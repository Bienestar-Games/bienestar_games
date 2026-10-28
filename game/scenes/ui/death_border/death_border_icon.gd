class_name DeathBorderIcon
extends Control
## Non-numeric Death Border icon: a ring whose red core grows with the run risk.
## Hidden until the risk first rises, so it appears without any text (GDD §13).

@export var ring_color: Color = Color(0.85, 0.85, 0.85, 0.9)
@export var core_color: Color = Color(0.85, 0.2, 0.2, 1)
@export var ring_width: float = 3.0

var risk: float = 0.0:
	set(value):
		risk = clampf(value, 0.0, 1.0)
		modulate.a = clampf(risk * 4.0, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) / 2.0 - ring_width
	draw_circle(center, radius, Color(0, 0, 0, 0.6))
	if risk > 0.0:
		draw_circle(center, radius * lerpf(0.25, 1.0, risk), core_color)
	draw_arc(center, radius, 0.0, TAU, 48, ring_color, ring_width, true)
