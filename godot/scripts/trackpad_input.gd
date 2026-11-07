extends Node
class_name TrackpadInput
## Keyboard aiming plus raw trackpad/mouse swing sampling.

signal aim_changed(degrees: float)
signal phase_changed(description: String, power: float)
signal swing_feedback(description: String, power: float, lateral_ratio: float)
signal swing_released(sample: Dictionary)

enum Phase { AIMING, BACKSWING, READY, FORWARD }

@export_range(45.0, 180.0, 1.0) var aim_limit_degrees := 180.0
@export var aim_speed_degrees := 75.0
@export var min_backswing_pixels := 14.0
@export var min_forward_pixels := 8.0
@export var power_backswing_divisor := 170.0
@export var power_speed_divisor := 1500.0
@export var power_acceleration_divisor := 12000.0

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
			_begin_swing()
		else:
			_finish_swing()
		return

	if event is InputEventMouseMotion:
		if _phase != Phase.AIMING:
			_sample_drag(event.relative)


func _process(delta: float) -> void:
	if not enabled or _phase != Phase.AIMING:
		return

	var direction := 0.0
	if Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0
	if not is_zero_approx(direction):
		aim_degrees = wrapf(aim_degrees + direction * aim_speed_degrees * delta, -aim_limit_degrees, aim_limit_degrees)
		aim_changed.emit(aim_degrees)


func _begin_swing() -> void:
	_backswing_pixels = 0.0
	_forward_pixels = 0.0
	_lateral_pixels = 0.0
	_max_forward_speed = 0.0
	_max_forward_acceleration = 0.0
	_previous_forward_speed = 0.0
	_last_sample_usec = Time.get_ticks_usec()
	_phase = Phase.BACKSWING
	phase_changed.emit("Backswing — drag down", 0.0)
	swing_feedback.emit("Backswing — drag down", 0.0, 0.0)


func _sample_drag(relative_motion: Vector2) -> void:
	var now_usec := Time.get_ticks_usec()
	var elapsed := maxf(float(now_usec - _last_sample_usec) / 1_000_000.0, 0.001)
	_last_sample_usec = now_usec

	if _phase == Phase.BACKSWING:
		if relative_motion.y > 0.0:
			_backswing_pixels += relative_motion.y
			if _backswing_pixels >= min_backswing_pixels:
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
			swing_feedback.emit("Swing — release to hit", _power_estimate(), _lateral_pixels / maxf(_forward_pixels, 1.0))


func _finish_swing() -> void:
	if _phase == Phase.FORWARD and _forward_pixels >= min_forward_pixels:
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
		phase_changed.emit("Aim with ← →; drag down, flick up, release", 0.0)


func _reset_swing() -> void:
	_phase = Phase.AIMING
	_backswing_pixels = 0.0
	_forward_pixels = 0.0
	_lateral_pixels = 0.0
	_max_forward_speed = 0.0
	_max_forward_acceleration = 0.0
	_previous_forward_speed = 0.0


func _power_estimate() -> float:
	var backswing := clampf(_backswing_pixels / power_backswing_divisor, 0.0, 1.0)
	var speed := clampf(_max_forward_speed / power_speed_divisor, 0.0, 1.0)
	var acceleration := clampf(_max_forward_acceleration / power_acceleration_divisor, 0.0, 1.0)
	return clampf(0.42 * backswing + 0.48 * speed + 0.10 * acceleration, 0.0, 1.0)
