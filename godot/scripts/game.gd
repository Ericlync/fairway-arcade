extends Node3D
## Main 3D golf scene composer for Milestone 1.

const GolfBall = preload("res://scripts/golf_ball.gd")
const GolfCamera = preload("res://scripts/golf_camera.gd")
const GolfCourse = preload("res://scripts/golf_course.gd")
const GolfHUD = preload("res://scripts/golf_hud.gd")
const GolfSwingController = preload("res://scripts/golf_swing_controller.gd")
const GameManager = preload("res://scripts/game_manager.gd")
const ClubData = preload("res://scripts/club_data.gd")

var _course: GolfCourse
var _ball: GolfBall
var _camera: GolfCamera
var _hud: GolfHUD
var _swing: GolfSwingController
var _game: GameManager

var _ball_settled := true
var _last_safe_position: Vector3
var _water_penalty_pending := false
var _reset_cooldown := 0.0
var _aim_indicator: Node3D
var _path_indicator: Node3D
var _aim_degrees := 0.0
var _swing_path_degrees := 0.0
var _club_index := 0
var _club: Dictionary = ClubData.get_club(0)


func _ready() -> void:
	_setup_environment()
	var args := OS.get_cmdline_args()
	var test_shot := args.has("--test-shot")

	_course = GolfCourse.new()
	_course.name = "GolfCourse"
	add_child(_course)

	_game = GameManager.new()
	_game.name = "GameManager"
	_game.par = 4
	_game.setup(_course.tee_position)
	_game.stroke_taken.connect(_on_stroke_taken)
	_game.ball_reset.connect(_on_ball_reset)
	add_child(_game)

	_ball = GolfBall.new()
	_ball.name = "GolfBall"
	_ball.position = _course.tee_position + Vector3.UP * 0.25
	_ball.landed.connect(_on_ball_landed)
	add_child(_ball)
	_last_safe_position = _ball.global_position

	_aim_indicator = _create_aim_indicator()
	add_child(_aim_indicator)
	_path_indicator = _create_aim_indicator(Color(0.25, 0.85, 1.0), 4.0, 4.0)
	add_child(_path_indicator)

	_camera = GolfCamera.new()
	_camera.name = "GolfCamera"
	add_child(_camera)
	_camera.setup(_ball)

	_swing = GolfSwingController.new()
	_swing.name = "GolfSwingController"
	add_child(_swing)
	_swing.aim_changed.connect(_on_aim_changed)
	_swing.phase_changed.connect(_on_phase_changed)
	_swing.swing_feedback.connect(_on_swing_feedback)
	_swing.shot_calculated.connect(_on_shot_calculated)
	_swing.set_club(_club)

	_hud = GolfHUD.new()
	_hud.name = "GolfHUD"
	add_child(_hud)
	_hud.update_hole(_distance_to_cup(), _game.strokes, _game.par, _club.name)
	_hud.update_ball_state(_ball.motion_state_name(), _ball.flight_altitude())

	if test_shot:
		get_tree().create_timer(1.5).timeout.connect(_test_shot)


func _process(delta: float) -> void:
	var settled := _ball.is_settled()
	_swing.set_enabled(settled and _ball.surface_type() != "water" and _reset_cooldown <= 0.0)

	_update_aim_indicator(settled)

	if not settled and _ball_settled:
		_camera.follow_ball()
	elif settled and not _ball_settled:
		_last_safe_position = _ball.global_position
		_camera.rest_at(_resting_camera_position(), _ball.global_position)

	_ball_settled = settled

	if _reset_cooldown > 0.0:
		_reset_cooldown = maxf(0.0, _reset_cooldown - delta)
		return

	if _ball.global_position.y < -10.0 and not _water_penalty_pending:
		print("WATER/OOB: ball y=", _ball.global_position.y, " surface=", _ball.surface_type())
		_water_penalty_pending = true
		_game.handle_water()
		return

	_hud.update_hole(_distance_to_cup(), _game.strokes, _game.par, _club.name)
	_hud.update_lie(_ball.surface_type())
	_hud.update_ball_state(_ball.motion_state_name(), _ball.flight_altitude())


func _on_aim_changed(degrees: float) -> void:
	_aim_degrees = degrees
	_camera.set_aim_degrees(degrees)
	_hud.set_aim_value(degrees)


func _on_phase_changed(description: String, power: float) -> void:
	if description == "Backswing — drag down":
		_camera.start_swing()
	_hud.update_swing(description, power)


func _on_swing_feedback(description: String, power: float, lateral_ratio: float) -> void:
	_swing_path_degrees = clampf(lateral_ratio, -0.35, 0.35) * 30.0
	_hud.update_swing(description, power, lateral_ratio)


func _on_shot_calculated(shot: Dictionary) -> void:
	_swing_path_degrees = 0.0
	_ball.launch(shot)
	_game.take_stroke()
	_hud.show_shot(shot)


func _on_ball_landed(surface_type: String) -> void:
	if surface_type == "water" and not _water_penalty_pending:
		_water_penalty_pending = true
		_game.handle_water()


func _on_stroke_taken(_strokes: int) -> void:
	_hud.update_hole(_distance_to_cup(), _game.strokes, _game.par, _club.name)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not _ball.is_settled() or _reset_cooldown > 0.0:
		return

	var new_index := _club_index
	match event.keycode:
		KEY_UP, KEY_PAGEUP:
			new_index += 1
		KEY_DOWN, KEY_PAGEDOWN:
			new_index -= 1
		KEY_1: new_index = 0
		KEY_2: new_index = 1
		KEY_3: new_index = 2
		KEY_4: new_index = 3
		KEY_5: new_index = 4
		KEY_6: new_index = 5
		_: return
	_select_club(new_index)


func _select_club(index: int) -> void:
	_club_index = posmod(index, ClubData.count())
	_club = ClubData.get_club(_club_index)
	_swing.set_club(_club)
	_hud.update_hole(_distance_to_cup(), _game.strokes, _game.par, _club.name)
	_hud.show_message("%s selected • aim ← →, swing with trackpad" % _club.name)


func _on_ball_reset(position: Vector3) -> void:
	_ball.reset_at(position + Vector3.UP * 0.25)
	_ball_settled = true
	_water_penalty_pending = false
	_reset_cooldown = 1.2
	_camera.setup(_ball)
	_hud.show_message("Drop — stroke penalty")


func _distance_to_cup() -> float:
	var cup: Vector3 = _course.cup_position
	return Vector2(_ball.global_position.x - cup.x, _ball.global_position.z - cup.z).length()


func _resting_camera_position() -> Vector3:
	var cup := _course.cup_position
	var to_cup := (cup - _ball.global_position).normalized()
	var offset := Vector3(-to_cup.x * _camera.rest_distance * 0.75, _camera.rest_height, -to_cup.z * _camera.rest_distance * 0.75)
	return _ball.global_position + offset


func _test_shot() -> void:
	var sample := {
		"power": 0.92,
		"accuracy": 0.94,
		"aim_degrees": _aim_degrees,
		"lateral_ratio": -0.12,
		"club": _club,
	}
	var shot := ShotCalculator.calculate(sample)
	_on_shot_calculated(shot)


func _create_aim_indicator(tint: Color = Color(0.95, 0.95, 0.15), shaft_length: float = 2.5, head_position: float = 2.5) -> Node3D:
	var root := Node3D.new()
	root.name = "AimIndicator"
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.04
	shaft_mesh.bottom_radius = 0.04
	shaft_mesh.height = shaft_length
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0.0, 0.02, shaft_length * 0.5)
	shaft.rotation_degrees.x = 90.0
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy = 0.4
	shaft.material_override = mat
	root.add_child(shaft)

	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.18
	head_mesh.height = 0.45
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.02, head_position)
	head.rotation_degrees.x = 90.0
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	head.material_override = mat
	root.add_child(head)
	return root


func _update_aim_indicator(visible: bool) -> void:
	if _aim_indicator == null or _ball == null:
		return
	_aim_indicator.visible = visible
	_path_indicator.visible = visible and absf(_swing_path_degrees) > 0.5
	if visible:
		_aim_indicator.global_position = _ball.global_position + Vector3.UP * 0.05
		_aim_indicator.global_rotation_degrees.y = -_aim_degrees
		_path_indicator.global_position = _ball.global_position + Vector3.UP * 0.06
		_path_indicator.global_rotation_degrees.y = -(_aim_degrees + _swing_path_degrees)


func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.35, 0.55, 0.78)
	sky_material.sky_horizon_color = Color(0.62, 0.78, 0.88)
	sky_material.ground_horizon_color = Color(0.62, 0.78, 0.88)
	sky_material.ground_bottom_color = Color(0.35, 0.55, 0.78)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.rotation_degrees = Vector3(-50.0, -32.0, 0.0)
	sunlight.light_energy = 1.3
	sunlight.shadow_enabled = true
	add_child(sunlight)
