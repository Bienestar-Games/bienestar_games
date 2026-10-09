class_name Enemy extends BaseCharacter

@export var vision_area: Area2D
@export var vision_ray: RayCast2D
@export var attack_area: Area2D
@export var navigation_agent_2d: NavigationAgent2D
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.2
@export var enemy_spawn_zone: EnemySpawnZone

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

func _ready() -> void:
	add_to_group("enemy")
	MAX_SPEED = 150
	vision_area.body_entered.connect(_on_vision_body_entered)
	vision_area.body_exited.connect(_on_vision_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	died.connect(queue_free)

func _physics_process(delta: float) -> void:
	if not _is_alive():
		return
	_check_line_of_sight(delta)
	attack_cd_timer -= delta
	_update_rotation(vision_area, _last_move_direction)
	_update_rotation(attack_area, _last_move_direction)

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

func _update_rotation(area: Area2D, dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		area.rotation = dir.angle() - PI / 2

func _on_vision_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = body
		print("player entered")

func _on_vision_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = true
		attack_cd_timer = attack_cooldown

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
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
	
