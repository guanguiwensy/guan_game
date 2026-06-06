class_name HeroView
extends Node2D
## Placeholder visual for the hero (M1 — original art comes later). Renders a simple
## marker at the hero's fixed position; reads its CombatActor for hp-driven tinting.

var actor: CombatActor

const BODY := Color(0.45, 0.72, 1.0)


func sync() -> void:
	if actor == null:
		return
	position = actor.position
	# dim toward red as hp drops
	var ratio := clampf(actor.hp / maxf(actor.max_hp, 1.0), 0.0, 1.0)
	modulate = Color(1.0, 0.4 + 0.6 * ratio, 0.4 + 0.6 * ratio)
	queue_redraw()


func _draw() -> void:
	var bob := sin(Time.get_ticks_msec() / 280.0) * 3.0   # M5: idle breathing
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	draw_rect(Rect2(-30, -58, 60, 92), BODY)
	draw_circle(Vector2(0, -72), 18, BODY)
