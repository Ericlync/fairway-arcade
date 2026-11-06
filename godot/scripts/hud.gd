extends CanvasLayer
## Arcade-style distance, club, stroke, aiming, and swing feedback.

var _distance_label: Label
var _aim_label: Label
var _status_label: Label
var _strokes_label: Label
var _power_bar: ProgressBar
var _aim_degrees := 0.0


func _ready() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)

	var panel := PanelContainer.new()
	panel.position = Vector2(22.0, 20.0)
	panel.custom_minimum_size = Vector2(370.0, 190.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.09, 0.12, 0.88)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 16.0
	panel_style.content_margin_right = 16.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", panel_style)
	screen.add_child(panel)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 5)
	panel.add_child(rows)

	var title := _label("FAIRWAY ARCADE  •  HOLE 1", 21, Color(0.97, 0.82, 0.32))
	rows.add_child(title)
	_distance_label = _label("To cup: -- m     Club: Driver", 17, Color(0.92, 0.96, 0.88))
	rows.add_child(_distance_label)
	_strokes_label = _label("Strokes: 0     Par: 4", 16, Color(0.83, 0.90, 0.82))
	rows.add_child(_strokes_label)
	_aim_label = _label("Aim: 0°     Power: 0%", 16, Color(0.83, 0.90, 0.82))
	rows.add_child(_aim_label)
	_power_bar = ProgressBar.new()
	_power_bar.custom_minimum_size = Vector2(0.0, 14.0)
	_power_bar.min_value = 0.0
	_power_bar.max_value = 100.0
	_power_bar.show_percentage = false
	rows.add_child(_power_bar)
	_status_label = _label("Move pointer to aim • click-drag down, flick up, release", 14, Color(0.93, 0.94, 0.88))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(_status_label)


func update_hole(distance_m: float, strokes: int) -> void:
	_distance_label.text = "To cup: %d m     Club: Driver" % roundi(distance_m)
	_strokes_label.text = "Strokes: %d     Par: 4" % strokes


func update_aim(degrees: float) -> void:
	_aim_label.text = "Aim: %+.1f°     Power: %d%%" % [degrees, roundi(_power_bar.value)]


func update_swing(description: String, power: float) -> void:
	_status_label.text = description
	_power_bar.value = clampf(power, 0.0, 1.0) * 100.0
	_aim_label.text = "Aim: %+.1f°     Power: %d%%" % [_aim_degrees, roundi(_power_bar.value)]


func show_shot(power: float, direction_degrees: float, accuracy: float) -> void:
	_power_bar.value = power * 100.0
	_status_label.text = "Shot away • %d%% accuracy" % roundi(accuracy * 100.0)
	_aim_label.text = "Shot direction: %+.1f°     Power: %d%%" % [direction_degrees, roundi(power * 100.0)]


func set_aim_value(degrees: float) -> void:
	_aim_degrees = degrees
	_aim_label.text = "Aim: %+.1f°     Power: %d%%" % [_aim_degrees, roundi(_power_bar.value)]


func _label(value: String, font_size: int, tint: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", tint)
	return result
