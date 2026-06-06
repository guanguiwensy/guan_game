class_name SkillRing
extends Node2D
## M5: a brief expanding ring that visualizes an AoE skill cast, so skills read on screen
## (not just damage numbers). Colored by element. Self-frees.

var _radius := 80.0
var _color := Color.WHITE


func setup(radius: float, color: Color) -> void:
	_radius = maxf(radius, 20.0)
	_color = color


func _ready() -> void:
	scale = Vector2(0.35, 0.35)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.36)
	tw.tween_callback(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, _radius, Color(_color.r, _color.g, _color.b, 0.12))
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, _color, 5.0, true)
