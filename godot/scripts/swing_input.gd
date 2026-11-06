extends Node
## Trackpad-as-trackball swing detection using ordinary mouse/pointer events.

signal aim_changed(degrees: float)
signal phase_changed(description: String, power: float)
signal swing_released(sample: Dictionary)

enum Phase { AIMING, BACKSWING, READY, FORWARD }

const MIN_BACKSWING_PIXELS := 14.0
const MIN_FORWARD_PIXELS := 8.0

@export_range(5.0, 45.0, 1.0) var aim_limit_degrees := 24.0
var enabled := true
var aim_degrees := 0.0

var _phase := Phase.AIMING
var _backswing_pixels := 0.0
var _forward_pixels := 0.0
var _lateral_pixels := 0.0
var _max_forward_speed := 0.0
var _max_forward_acceleration := 0.0
var _previous_forward_speed := 0.0
var _last_sample_usec := 0


func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_swing(event.position)
		else:
			_finish_swing()
		return

	if event is InputEventMouseMotion:
		if _phase == Phase.AIMING:
			_update_aim(event.position.x)
		else:
			_sample_drag(event.relative)


func _begin_swing(pointer_position: Vector2) -> void:
	_backswing_pixels = 0.0
	_forward_pixels = 0.0
	_lateral_pixels = 0.0
	_max_forward_speed = 0.0
	_max_forward_acceleration = 0.0
	_previous_forward_speed = 0.0
	_last_sample_usec = Time.get_ticks_usec()
	_phase = Phase.BACKSWING
	_update_aim(pointer_position.x)
	phase_changed.emit("Backswing — drag down", 0.0)


func _sample_drag(relative_motion: Vector2) -> void:
	var now_usec := Time.get_ticks_usec()
	var elapsed := maxf(float(now_usec - _last_sample_usec) / 1_000_000.0, 0.001)
	_last_sample_usec = now_usec

	if _phase == Phase.BACKSWING:
		if relative_motion.y > 0.0:
			_backswing_pixels += relative_motion.y
			if _backswing_pixels >= MIN_BACKSWING_PIXELS:
				_phase = Phase.READY
				phase_changed.emit("Flick up to swing", _power_estimate())
		return

	if _phase == Phase.READY or _phase == Phase.FORWARD:
		if relative_motion.y < 0.0:
			_phase = Phase.FORWARD
			var forward_delta := -relative_motion.y
			var speed := forward_delta / elapsed
			var acceleration := maxf((speed - _previous_forward_speed) / elapsed, 0.0)
			_previous_forward_speed = speed
			_max_forward_speed = maxf(_max_forward_speed, speed)
			_max_forward_acceleration = maxf(_max_forward_acceleration, acceleration)
			_forward_pixels += forward_delta
			_lateral_pixels += relative_motion.x
			phase_changed.emit("Swing — release to hit", _power_estimate())


func _finish_swing() -> void:
	if _phase == Phase.FORWARD and _forward_pixels >= MIN_FORWARD_PIXELS:
		var lateral_ratio := _lateral_pixels / maxf(_forward_pixels, 1.0)
		var sample := {
			"backswing_pixels": _backswing_pixels,
			"forward_pixels": _forward_pixels,
			"forward_velocity_px_s": _max_forward_speed,
			"acceleration_px_s2": _max_forward_acceleration,
			"lateral_ratio": lateral_ratio,
			"accuracy": clampf(1.0 - absf(lateral_ratio) * 2.5, 0.0, 1.0),
			"aim_degrees": aim_degrees,
			"power": _power_estimate(),
		}
		_reset_swing()
		swing_released.emit(sample)
	else:
		_reset_swing()
		phase_changed.emit("Aim with pointer; drag down, flick up, release", 0.0)


func _reset_swing() -> void:
	_phase = Phase.AIMING
	_backswing_pixels = 0.0
	_forward_pixels = 0.0
	_lateral_pixels = 0.0
	_max_forward_speed = 0.0
	_max_forward_acceleration = 0.0
	_previous_forward_speed = 0.0


func _power_estimate() -> float:
	var backswing = clampf(_backswing_pixels / 170.0, 0.0, 1.0)
	var speed = clampf(_max_forward_speed / 1500.0, 0.0, 1.0)
	var acceleration = clampf(_max_forward_acceleration / 12_000.0, 0.0, 1.0)
	return clampf(0.42 * backswing + 0.48 * speed + 0.10 * acceleration, 0.0, 1.0)


func _update_aim(pointer_x: float) -> void:
	var viewport := get_viewport()
	var viewport_width := 1280.0 if viewport == null else maxf(viewport.get_visible_rect().size.x, 1.0)
	var centered := clampf((pointer_x / viewport_width) * 2.0 - 1.0, -1.0, 1.0)
	aim_degrees = centered * aim_limit_degrees
	aim_changed.emit(aim_degrees)
