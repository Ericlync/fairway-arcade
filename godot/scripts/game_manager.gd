extends Node
class_name GameManager
## Tracks hole state, strokes, par, score, and out-of-bounds/water handling.

signal stroke_taken(strokes: int)
signal ball_reset(position: Vector3)
signal hole_finished(strokes: int, par: int)

var current_hole := 1
var par := 4
var strokes := 0
var _ball_start_position: Vector3


func setup(tee_position: Vector3) -> void:
	_ball_start_position = tee_position


func take_stroke() -> void:
	strokes += 1
	stroke_taken.emit(strokes)


func reset_to_tee() -> void:
	strokes += 1
	ball_reset.emit(_ball_start_position)


func handle_water() -> void:
	reset_to_tee()


func finish_hole() -> void:
	hole_finished.emit(strokes, par)


func reset_hole() -> void:
	strokes = 0
	ball_reset.emit(_ball_start_position)
