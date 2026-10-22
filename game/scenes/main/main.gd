extends Node2D

const DEATH_SCREEN := "res://scenes/ui/death_screen/death_screen.tscn"

func _ready() -> void:
	Events.run_ended.connect(_on_run_ended)

func _on_run_ended(extracted: bool) -> void:
	if not extracted:
		get_tree().change_scene_to_file.call_deferred(DEATH_SCREEN)
		return
	# TODO B36: load results screen
	print("Run ended — extracted: ", extracted)


func _on_interactive_barrier_barrier_opened() -> void:
	# Desactiva la colisión de forma segura para permitir el paso
	$CollisionShape2D.set_deferred("disabled", true)
	# Libera el nodo de la memoria (o puedes usar hide() si prefieres ocultarla)
	queue_free()
