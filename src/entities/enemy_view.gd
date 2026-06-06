class_name EnemyView
extends Node2D
## Placeholder visual for an enemy (M1). Syncs position from its CombatActor and draws a
## body + hp bar. Boss renders larger and darker red. Fades out on death.

var actor: CombatActor
var _dying := false


func sync() -> void:
	if actor == null or _dying:
		return
	position = actor.position
	queue_redraw()


func play_death() -> void:
	_dying = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


func _draw() -> void:
	if actor == null:
		return
	var s := 64.0 if actor.is_boss else 34.0
	var col := Color(0.72, 0.18, 0.18) if actor.is_boss else Color(0.92, 0.55, 0.30)
	draw_rect(Rect2(-s * 0.5, -s * 0.5, s, s), col)
	# hp bar above body
	var ratio := clampf(actor.hp / maxf(actor.max_hp, 1.0), 0.0, 1.0)
	var top := -s * 0.5 - 12.0
	draw_rect(Rect2(-s * 0.5, top, s, 6.0), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-s * 0.5, top, s * ratio, 6.0), Color(0.30, 0.90, 0.35))
