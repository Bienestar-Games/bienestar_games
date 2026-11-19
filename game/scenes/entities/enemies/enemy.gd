class_name Enemy extends BaseCharacter

@export var vision_area: Area2D
@export var vision_ray: RayCast2D
@export var attack_area: Area2D
@export var navigation_agent_2d: NavigationAgent2D
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.2
@export var enemy_spawn_zone: EnemySpawnZone
## When true the enemy always knows roughly where Kade is and walks toward him even
## without line of sight (WaveManager turns it on). It still needs to see him to chase and attack.
@export var hunts_player: bool = false
## Seconds the sprite takes to fade back from white after being hit.
@export var hit_flash_duration: float = 0.15

const HIT_FLASH_SHADER: Shader = preload("res://resources/shaders/hit_flash.gdshader")

# Percepción — compartida entre estados
var player_in_range: Node2D = null
var target: Node2D = null
var last_seen_position: Vector2 = Vector2.ZERO
var has_last_seen: bool = false
var player_in_attack_area: bool = false
var _ongoing_interaction: bool = false
var attack_cd_timer: float = 0.0
var sight_loss_timer: float = 0.0

const SIGHT_LOSS_GRACE: float = 2.0
const REPATH_THRESHOLD: float = 8.0
## Seconds between updates of Kade's position while hunting.
const HUNT_UPDATE_INTERVAL: float = 1.0
## Max distance (px) between the end of a path and the target for it to count as reachable.
const REACHABLE_TOLERANCE: float = 16.0
## Radius (px) within which the enemy aggroes onto a deployed wall over the player.
const WALL_AGGRO_RANGE: float = 480.0

var _hunt_timer: float = 0.0
var _hit_flash_material: ShaderMaterial
var _hit_flash_tween: Tween
## The wall this enemy is currently chasing, if any. Takes priority over `player_in_range`.
var wall_target: Wall = null
## Players touching the attack area; counted so simultaneous overlaps are handled correctly.
var _players_in_attack_area: int = 0
## Walls touching the attack area, in the order they entered. Lets us know if `wall_target`
## is close enough to be hit without changing EnemyAttackingState's attack path.
var _walls_in_attack_area: Array[Wall] = []

func _ready() -> void:
	add_to_group("enemy")
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	died.connect(_on_died)
	_setup_hit_flash()

## Gives this enemy its own flash material so only the enemy that was shot turns white.
func _setup_hit_flash() -> void:
	if entity_sprite == null:
		return
	_hit_flash_material = ShaderMaterial.new()
	_hit_flash_material.shader = HIT_FLASH_SHADER
	entity_sprite.material = _hit_flash_material
	damage_taken.connect(_flash_white)

func _flash_white() -> void:
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()
	_hit_flash_material.set_shader_parameter("flash_amount", 1.0)
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_method(
		func(amount: float) -> void: _hit_flash_material.set_shader_parameter("flash_amount", amount),
		1.0, 0.0, hit_flash_duration)

func _on_died() -> void:
	spawn_loot()
	queue_free()

func spawn_loot() -> void:
	LootManager.drop_enemy_loot(get_parent(), global_position)

func _physics_process(delta: float) -> void:
	if not _is_alive():
		return
	_check_line_of_sight(delta)
	_update_hunt(delta)
	_update_wall_priority()
	attack_cd_timer -= delta
	_update_rotation(vision_area, _last_move_direction)
	_update_rotation(attack_area, _last_move_direction)

## Picks the closest wall inside WALL_AGGRO_RANGE and, if it is not farther than the player,
## routes `target` onto it so the enemy chases and attacks it first. Falls back to Kade as
## soon as the wall is gone or he gets closer than it.
func _update_wall_priority() -> void:
	if not is_instance_valid(wall_target):
		wall_target = null
	var closest := _find_closest_wall(WALL_AGGRO_RANGE)
	if closest == null:
		if wall_target != null and target == wall_target:
			# The wall we were chasing is gone: let the normal sight logic retake the player.
			target = player_in_range
			player_in_attack_area = _players_in_attack_area > 0
		wall_target = null
		return
	wall_target = closest
	var wall_dist := global_position.distance_to(closest.global_position)
	var player_dist := INF
	if player_in_range != null:
		player_dist = global_position.distance_to(player_in_range.global_position)
	if wall_dist <= player_dist:
		target = closest
		last_seen_position = closest.global_position
		has_last_seen = true
		player_in_attack_area = _walls_in_attack_area.has(closest)
	elif target == closest:
		target = player_in_range
		player_in_attack_area = _players_in_attack_area > 0

func _find_closest_wall(max_distance: float) -> Wall:
	var closest: Wall = null
	var closest_dist_sq: float = max_distance * max_distance
	for wall in get_tree().get_nodes_in_group(&"wall"):
		if not (wall is Wall) or not is_instance_valid(wall):
			continue
		var dist_sq := global_position.distance_squared_to(wall.global_position)
		if dist_sq <= closest_dist_sq:
			closest_dist_sq = dist_sq
			closest = wall
	return closest

func _check_line_of_sight(delta: float) -> void:
	sight_loss_timer -= delta
	if player_in_range == null:
		if sight_loss_timer <= 0.0:
			target = null
		return
	vision_ray.target_position = player_in_range.global_position - global_position
	vision_ray.force_raycast_update()
	if vision_ray.is_colliding():
		if sight_loss_timer <= 0.0:
			target = null
	else:
		target = player_in_range
		last_seen_position = player_in_range.global_position
		has_last_seen = true
		sight_loss_timer = SIGHT_LOSS_GRACE

## While hunting, refresh last_seen_position with Kade's real position so the
## searching state walks toward him. Does nothing while the enemy can see him.
func _update_hunt(delta: float) -> void:
	if not hunts_player or target != null:
		return
	_hunt_timer -= delta
	if _hunt_timer > 0.0:
		return
	_hunt_timer = HUNT_UPDATE_INTERVAL
	var player := get_tree().get_first_node_in_group("player") as BaseCharacter
	if player == null or player.base_health <= 0:
		return
	# Unreachable (e.g. no navmesh path to the player): stop hunting and fall back to idle/wander
	if not _can_reach(player.global_position):
		has_last_seen = false
		return
	last_seen_position = player.global_position
	has_last_seen = true

## True when the navmesh has a path from this enemy to `point`.
func _can_reach(point: Vector2) -> bool:
	var map := navigation_agent_2d.get_navigation_map()
	var path := NavigationServer2D.map_get_path(map, global_position, point, true)
	if path.is_empty():
		return false
	var goal := NavigationServer2D.map_get_closest_point(map, point)
	return path[path.size() - 1].distance_to(goal) <= REACHABLE_TOLERANCE

func _update_rotation(area: Area2D, dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		area.rotation = dir.angle() - PI / 2

func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = body

func _on_vision_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players_in_attack_area += 1
		player_in_attack_area = true
		attack_cd_timer = attack_cooldown
	elif body.is_in_group("wall") and body is Wall:
		if not _walls_in_attack_area.has(body):
			_walls_in_attack_area.append(body)
		if target == body:
			player_in_attack_area = true
			attack_cd_timer = attack_cooldown

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players_in_attack_area = maxi(_players_in_attack_area - 1, 0)
		if _players_in_attack_area == 0 and (target == null or target == player_in_range):
			player_in_attack_area = false
	elif body.is_in_group("wall"):
		_walls_in_attack_area.erase(body)
		if target == body:
			player_in_attack_area = false



func handle_animations(state:String):
	handle_flip_h_sprite()
	match state:
		"idle":
			animation_tree["parameters/conditions/idle"] = true
			animation_tree["parameters/conditions/attacking"] = false
			animation_tree["parameters/conditions/running"] = false
		"moving":
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/attacking"] = false
			animation_tree["parameters/conditions/running"] = true
		"attacking":
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/attacking"] = true
			animation_tree["parameters/conditions/running"] = false
	
