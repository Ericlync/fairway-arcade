extends Node3D
class_name GolfCamera
## Elevated arcade-style camera with aiming, flight-follow, and resting states.

enum State { AIMING, SWING, FLIGHT, REST }

signal state_changed(new_state: String)

@export var aim_distance: float = 22.0
@export var aim_height: float = 12.0
@export var flight_height: float = 24.0
@export var flight_distance: float = 30.0
@export var rest_height: float = 40.0
@export var rest_distance: float = 52.0
@export var follow_speed: float = 3.2
@export var aim_follow_speed: float = 7.0
@export var look_ahead: float = 12.0

var camera: Camera3D
var _state := State.AIMING
var _target: Node3D
var _aim_degrees := 0.0
var _rest_position: Vector3
var _rest_target: Vector3


func _init() -> void:
	camera = Camera3D.new()
	camera.name = "GolfCamera"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 48.0
	camera.near = 0.1
	camera.far = 400.0
	camera.position = Vector3(0.0, aim_height, aim_distance)
	camera.current = true


func _enter_tree() -> void:
	if camera.get_parent() == null:
		add_child(camera)


func _process(delta: float) -> void:
	if _target == null:
		return

	var desired_pos: Vector3
	var desired_look: Vector3

	match _state:
		State.AIMING:
			desired_pos = _aiming_position()
			desired_look = _target.global_position + _aim_forward() * look_ahead
		State.SWING:
			desired_pos = _aiming_position()
			desired_look = _target.global_position + _aim_forward() * look_ahead * 0.5
		State.FLIGHT:
			desired_pos = _flight_position()
			desired_look = _flight_look_target()
		State.REST:
			desired_pos = _rest_position
			desired_look = _rest_target

	var blend_speed := aim_follow_speed if _state == State.AIMING or _state == State.SWING else follow_speed
	var t := 1.0 - exp(-delta * blend_speed)
	camera.global_position = camera.global_position.lerp(desired_pos, t)
	var look_direction := desired_look - camera.global_position
	if look_direction.length_squared() > 0.0001:
		var target_basis := Basis.looking_at(look_direction.normalized(), Vector3.UP)
		camera.global_transform = Transform3D(camera.global_basis.slerp(target_basis, t), camera.global_position)


func setup(ball: Node3D) -> void:
	_target = ball
	_state = State.AIMING
	camera.global_position = _aiming_position()
	camera.look_at(ball.global_position + _aim_forward() * look_ahead, Vector3.UP)


func set_aim_degrees(degrees: float) -> void:
	_aim_degrees = degrees


func start_swing() -> void:
	_state = State.SWING
	state_changed.emit("swing")


func follow_ball() -> void:
	_state = State.FLIGHT
	state_changed.emit("flight")


func rest_at(position: Vector3, look_target: Vector3) -> void:
	_rest_position = position
	_rest_target = look_target
	_state = State.REST
	state_changed.emit("rest")


func is_following() -> bool:
	return _state == State.FLIGHT


func _aiming_position() -> Vector3:
	if _target == null:
		return Vector3(0.0, aim_height, aim_distance)
	var rad := deg_to_rad(_aim_degrees)
	var offset := Vector3(-sin(rad) * aim_distance, aim_height, cos(rad) * aim_distance)
	return _target.global_position + offset


func _aim_forward() -> Vector3:
	var rad := deg_to_rad(_aim_degrees)
	return Vector3(sin(rad), 0.0, -cos(rad)).normalized()


func _flight_position() -> Vector3:
	if _target == null:
		return Vector3(0.0, flight_height, flight_distance)
	var velocity := Vector3.ZERO
	if _target is RigidBody3D:
		velocity = _target.linear_velocity
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).normalized() if velocity.length() > 0.1 else Vector3.BACK
	var height_offset := clampf(flight_height + velocity.y * 0.12, 18.0, 32.0)
	var offset := Vector3(-horizontal.x * flight_distance, height_offset, -horizontal.z * flight_distance)
	return _target.global_position + offset


func _flight_look_target() -> Vector3:
	if _target == null:
		return Vector3.ZERO
	var velocity := Vector3.ZERO
	if _target is RigidBody3D:
		velocity = _target.linear_velocity
	var look_ahead_vector := velocity.normalized() * 10.0 if velocity.length_squared() > 0.25 else Vector3.ZERO
	return _target.global_position + look_ahead_vector + Vector3.UP * 1.5
