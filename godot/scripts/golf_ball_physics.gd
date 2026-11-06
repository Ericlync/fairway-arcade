extends RefCounted
class_name GolfBallPhysics
## Configurable flight and ground physics for a golf ball.

const BALL_RADIUS := 0.21
const BALL_MASS := 0.045

# Flight
@export var gravity_scale: float = 1.0
@export var air_drag_coefficient: float = 0.012
@export var lift_coefficient: float = 0.00065
@export var magnus_coefficient: float = 0.00045

# Ground
@export var default_friction: float = 4.5
@export var fairway_friction: float = 4.2
@export var rough_friction: float = 7.0
@export var bunker_friction: float = 11.0
@export var green_friction: float = 3.2
@export var ground_spin_decay: float = 8.0
@export var bounce_restitution: float = 0.20

# Detection
@export var settled_speed: float = 0.38
@export var settled_spin: float = 0.8


func configure_ball(ball: RigidBody3D) -> void:
	ball.mass = BALL_MASS
	ball.continuous_cd = true
	ball.contact_monitor = true
	ball.max_contacts_reported = 6
	ball.custom_integrator = true
	ball.gravity_scale = 0.0
	ball.linear_damp = 0.0
	ball.angular_damp = 0.0
	ball.physics_material_override = PhysicsMaterial.new()
	ball.physics_material_override.friction = default_friction
	ball.physics_material_override.bounce = 0.0


func integrate(ball: RigidBody3D, state: PhysicsDirectBodyState3D, delta: float, surface_type: String, grounded: bool, ground_normal: Vector3) -> bool:
	var gravity := Vector3.DOWN * 9.81 * gravity_scale
	var v := state.linear_velocity
	var normal := ground_normal.normalized() if ground_normal.length_squared() > 0.01 else Vector3.UP

	if not grounded:
		v += gravity * delta
		var speed_sq := v.length_squared()
		if speed_sq > 0.001:
			v *= exp(-air_drag_coefficient * sqrt(speed_sq) * delta)
			v += state.angular_velocity.cross(v) * magnus_coefficient * delta
			v += Vector3.UP * speed_sq * lift_coefficient * _backspin_factor(state.angular_velocity, v) * delta
		state.linear_velocity = v
		return true

	var normal_speed := v.dot(normal)
	var bounced := false
	if normal_speed < -0.45:
		var bounce_speed := -normal_speed * bounce_restitution
		v += normal * (-normal_speed + bounce_speed)
		bounced = bounce_speed > 1.0
	else:
		v -= normal * normal_speed

	var tangent := v - normal * v.dot(normal)
	var slope_gravity := gravity - normal * gravity.dot(normal)
	tangent += slope_gravity * delta
	var rolling_resistance := _friction_for_surface(surface_type)
	tangent *= exp(-rolling_resistance * delta)
	# Static friction: a very slow ball on a shallow slope should stop instead
	# of endlessly creeping due to tiny heightfield normal changes.
	if tangent.length() < 0.55 and slope_gravity.length() < rolling_resistance * 0.7:
		tangent = Vector3.ZERO
	state.linear_velocity = tangent + normal * maxf(v.dot(normal), 0.0)
	state.angular_velocity = state.angular_velocity.lerp(Vector3.ZERO, clampf(ground_spin_decay * delta, 0.0, 1.0))

	if ball.physics_material_override != null:
		ball.physics_material_override.friction = rolling_resistance

	return bounced


func launch(ball: RigidBody3D, velocity: Vector3, backspin_rpm: float, sidespin_rpm: float) -> void:
	ball.linear_velocity = velocity
	ball.angular_velocity = _spin_to_angular_velocity(velocity, backspin_rpm, sidespin_rpm)
	ball.sleeping = false


func _spin_to_angular_velocity(velocity: Vector3, backspin_rpm: float, sidespin_rpm: float) -> Vector3:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.0001:
		horizontal = Vector3.FORWARD
	else:
		horizontal = horizontal.normalized()
	var side_axis := Vector3.UP.cross(horizontal).normalized()
	var backspin_rad_s := backspin_rpm * TAU / 60.0
	var sidespin_rad_s := sidespin_rpm * TAU / 60.0
	return side_axis * backspin_rad_s + Vector3.UP * sidespin_rad_s


func _backspin_factor(angular_velocity: Vector3, velocity: Vector3) -> float:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.0001:
		return 0.0
	horizontal = horizontal.normalized()
	var side_axis := Vector3.UP.cross(horizontal).normalized()
	return clampf(angular_velocity.dot(side_axis) / 120.0, 0.0, 1.5)


func _friction_for_surface(surface_type: String) -> float:
	match surface_type:
		"fairway": return fairway_friction
		"rough": return rough_friction
		"bunker": return bunker_friction
		"green": return green_friction
		_: return default_friction


func is_settled(ball: RigidBody3D) -> bool:
	return ball.linear_velocity.length() < settled_speed and ball.angular_velocity.length() < settled_spin
