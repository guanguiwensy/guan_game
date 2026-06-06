class_name DamageText
extends Node2D
## Floating damage number (GDD §0 feedback). Rises and fades, then frees itself.
## NOTE: M1 instantiates/frees per hit; object pooling is an M5 perf optimization.

var _amount: int = 0
var _is_crit: bool = false
var _element: StringName = &"physical"


func setup(amount: int, is_crit: bool, element: StringName) -> void:
	_amount = amount
	_is_crit = is_crit
	_element = element


func _ready() -> void:
	var label := Label.new()
	label.text = str(_amount)
	label.add_theme_font_size_override("font_size", 36 if _is_crit else 24)
	var col := Color(1.0, 0.85, 0.25) if _is_crit else Color(1, 1, 1)
	if _element == &"ice":
		col = Color(0.6, 0.85, 1.0)
	elif _element == &"fire":
		col = Color(1.0, 0.5, 0.2)
	label.add_theme_color_override("font_color", col)
	label.position = Vector2(-24, -24)
	add_child(label)

	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - 72.0, 0.6)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
