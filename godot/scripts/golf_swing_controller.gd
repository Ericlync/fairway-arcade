extends Node
class_name GolfSwingController
## Combines raw trackpad input with shot calculation and exposes arcade swing events.

const ClubData = preload("res://scripts/club_data.gd")

signal aim_changed(degrees: float)
signal phase_changed(description: String, power: float)
signal swing_feedback(description: String, power: float, lateral_ratio: float)
signal shot_calculated(shot: Dictionary)

var _input: TrackpadInput
var _calculator := ShotCalculator.new()
var _club: Dictionary = ClubData.get_club(0)


func _init() -> void:
	_input = TrackpadInput.new()
	_input.name = "TrackpadInput"
	add_child(_input)
	_input.aim_changed.connect(_on_aim_changed)
	_input.phase_changed.connect(_on_phase_changed)
	_input.swing_feedback.connect(_on_swing_feedback)
	_input.swing_released.connect(_on_swing_released)


func set_enabled(enabled: bool) -> void:
	_input.enabled = enabled


func set_club(club: Dictionary) -> void:
	_club = club


func _on_aim_changed(degrees: float) -> void:
	aim_changed.emit(degrees)


func _on_phase_changed(description: String, power: float) -> void:
	phase_changed.emit(description, power)


func _on_swing_feedback(description: String, power: float, lateral_ratio: float) -> void:
	swing_feedback.emit(description, power, lateral_ratio)


func _on_swing_released(sample: Dictionary) -> void:
	sample["club"] = _club
	var shot := _calculator.calculate(sample)
	shot_calculated.emit(shot)
