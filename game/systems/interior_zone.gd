extends Area2D

@export var wall_group: String = "walls_building_x"
@export var fade_alpha: float = 0.6
@export var fade_duration: float = 0.3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("entered building")
		_fade_walls(fade_alpha)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fade_walls(1.0)

func _fade_walls(target_alpha: float) -> void:
	for wall in get_tree().get_nodes_in_group(wall_group):
		var tween := create_tween()
		tween.tween_property(wall, "modulate:a", target_alpha, fade_duration)
