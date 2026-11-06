extends RigidBody3D
class_name GolfBall
## Visible golf ball with custom flight/ground physics and surface detection.

signal landed(surface_type: String)
signal settled(position: Vector3)
signal state_changed(state_name: String)

const BALL_RADIUS := 0.28
const SETTLE_DELAY := 0.28

enum MotionState { SETTLED, FLIGHT, GROUND }

var physics: GolfBallPhysics

var _visual: MeshInstance3D
var _flight_glow: MeshInstance3D
var _ground_shadow: MeshInstance3D
var _trail_nodes: Array[MeshInstance3D] = []
var _trail_timer := 0.0
var _last_position: Vector3
var _surface_type := "fairway"
var _motion_state := MotionState.SETTLED
var _settled_timer := 0.0
var _has_landed := false


func _init() -> void:
	physics = GolfBallPhysics.new()
	physics.configure_ball(self)


func _enter_tree() -> void:
	_last_position = global_position
	_add_collision()
	_add_visual()
	_add_flight_effects()
	sleeping = true


func _add_collision() -> void:
	var collision := CollisionShape3D.new()
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = BALL_RADIUS
	collision.shape = sphere_shape
	add_child(collision)


func _add_visual() -> void:
	_visual = MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = BALL_RADIUS
	sphere_mesh.height = BALL_RADIUS * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	_visual.mesh = sphere_mesh
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var ball_material := StandardMaterial3D.new()
	ball_material.albedo_color = Color(0.96, 0.97, 0.90)
	ball_material.roughness = 0.25
	ball_material.metallic = 0.0
	ball_material.emission_enabled = true
	ball_material.emission = Color(0.35, 0.38, 0.28)
	ball_material.emission_energy_multiplier = 0.35
	_visual.material_override = ball_material
	add_child(_visual)


func _add_flight_effects() -> void:
	_flight_glow = MeshInstance3D.new()
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = BALL_RADIUS * 1.45
	glow_mesh.height = BALL_RADIUS * 2.9
	_flight_glow.mesh = glow_mesh
	_flight_glow.top_level = true
	var glow_material := StandardMaterial3D.new()
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.albedo_color = Color(1.0, 0.72, 0.12, 0.2)
	glow_material.emission_enabled = true
	glow_material.emission = Color(1.0, 0.42, 0.04)
	glow_material.emission_energy_multiplier = 2.0
	_flight_glow.material_override = glow_material
	_flight_glow.visible = false
	add_child(_flight_glow)

	_ground_shadow = MeshInstance3D.new()
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.65
	shadow_mesh.bottom_radius = 0.65
	shadow_mesh.height = 0.015
	_ground_shadow.mesh = shadow_mesh
	_ground_shadow.top_level = true
	var shadow_material := StandardMaterial3D.new()
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.albedo_color = Color(0.015, 0.025, 0.015, 0.34)
	shadow_material.roughness = 1.0
	_ground_shadow.material_override = shadow_material
	_ground_shadow.visible = false
	add_child(_ground_shadow)

	for index in range(6):
		var trail := MeshInstance3D.new()
		var trail_mesh := SphereMesh.new()
		trail_mesh.radius = lerpf(0.13, 0.06, float(index) / 5.0)
		trail_mesh.height = trail_mesh.radius * 2.0
		trail.mesh = trail_mesh
		trail.top_level = true
		var trail_material := StandardMaterial3D.new()
		trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		trail_material.albedo_color = Color(1.0, 0.56, 0.08, 0.5 - index * 0.065)
		trail_material.emission_enabled = true
		trail_material.emission = Color(1.0, 0.25, 0.02)
		trail_material.emission_energy_multiplier = 1.5
		trail.material_override = trail_material
		trail.visible = false
		_trail_nodes.append(trail)
		add_child(trail)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _motion_state == MotionState.SETTLED:
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		return

	var terrain_height := _terrain_height()
	var distance_to_ground := state.transform.origin.y - terrain_height
	var ground_normal := _ground_normal()
	var normal_velocity := state.linear_velocity.dot(ground_normal)
	var grounded := state.get_contact_count() > 0 or (distance_to_ground <= BALL_RADIUS + 0.10 and normal_velocity <= 0.8)
	var bounced := physics.integrate(self, state, state.step, _surface_type, grounded, ground_normal)

	if grounded and not bounced:
		var target_y := terrain_height + BALL_RADIUS
		if state.transform.origin.y < target_y:
			var transform := state.transform
			transform.origin.y = target_y
			state.transform = transform

	if bounced:
		_set_motion_state(MotionState.FLIGHT)
	elif grounded and _motion_state == MotionState.FLIGHT:
		_set_motion_state(MotionState.GROUND)
		if not _has_landed:
			_has_landed = true
			landed.emit(_surface_type)


func _physics_process(delta: float) -> void:
	_detect_surface()
	if _motion_state == MotionState.GROUND:
		var speed := linear_velocity.length()
		if speed <= physics.settled_speed and angular_velocity.length() <= physics.settled_spin:
			_settled_timer += delta
		else:
			_settled_timer = 0.0
		if _settled_timer >= SETTLE_DELAY:
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			global_position.y = _terrain_height() + BALL_RADIUS
			sleeping = true
			_set_motion_state(MotionState.SETTLED)
			settled.emit(global_position)

	_update_flight_effects(delta)


func launch(shot: Dictionary) -> void:
	var velocity: Vector3 = shot.get("velocity", Vector3.ZERO)
	var backspin: float = shot.get("backspin_rpm", 2400.0)
	var sidespin: float = shot.get("sidespin_rpm", 0.0)
	physics.launch(self, velocity, backspin, sidespin)
	_settled_timer = 0.0
	_has_landed = false
	_set_motion_state(MotionState.FLIGHT)


func reset_at(position: Vector3) -> void:
	global_position = position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_settled_timer = 0.0
	_has_landed = false
	_set_motion_state(MotionState.SETTLED)
	sleeping = true


func is_settled() -> bool:
	return _motion_state == MotionState.SETTLED


func motion_state_name() -> String:
	match _motion_state:
		MotionState.FLIGHT: return "flight"
		MotionState.GROUND: return "ground"
		_: return "settled"


func flight_altitude() -> float:
	return maxf(0.0, global_position.y - _terrain_height() - BALL_RADIUS)


func surface_type() -> String:
	return _surface_type


func _detect_surface() -> void:
	var course := _find_course()
	if course != null:
		_surface_type = course.get_surface_type(global_position.x, global_position.z)


func _terrain_height() -> float:
	var course := _find_course()
	if course != null:
		return course.get_height_at(global_position.x, global_position.z)
	return 0.0


func _ground_normal() -> Vector3:
	var course := _find_course()
	if course != null:
		return course.get_surface_normal(global_position.x, global_position.z)
	return Vector3.UP


func _set_motion_state(new_state: MotionState) -> void:
	if _motion_state == new_state:
		return
	_motion_state = new_state
	state_changed.emit(motion_state_name())


func _update_flight_effects(delta: float) -> void:
	var airborne := _motion_state == MotionState.FLIGHT
	_flight_glow.visible = airborne
	_ground_shadow.visible = airborne or _motion_state == MotionState.GROUND
	if _ground_shadow.visible:
		_ground_shadow.global_position = Vector3(global_position.x, _terrain_height() + 0.035, global_position.z)
		var altitude_factor := clampf(flight_altitude() / 20.0, 0.0, 1.0)
		_ground_shadow.scale = Vector3.ONE * lerpf(1.0, 0.55, altitude_factor)
	if not airborne:
		for trail in _trail_nodes:
			trail.visible = false
		return

	_flight_glow.global_position = global_position
	_trail_timer += delta
	if _trail_timer >= 0.045:
		_trail_timer = 0.0
		for index in range(_trail_nodes.size() - 1, 0, -1):
			_trail_nodes[index].global_position = _trail_nodes[index - 1].global_position
		_trail_nodes[0].global_position = global_position
	for trail in _trail_nodes:
		trail.visible = true


func _find_course() -> GolfCourse:
	var parent := get_parent()
	if parent != null:
		for child in parent.get_children():
			if child is GolfCourse:
				return child
	return null
