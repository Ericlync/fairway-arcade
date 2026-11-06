extends Node3D
## Composes independent gameplay systems for the first playable golf hole.

const CameraRig = preload("res://scripts/camera_rig.gd")
const Course = preload("res://scripts/course.gd")
const GolfBall = preload("res://scripts/golf_ball.gd")
const Hud = preload("res://scripts/hud.gd")
const ShotCalculator = preload("res://scripts/shot_calculator.gd")
const SwingInput = preload("res://scripts/swing_input.gd")

var _course
var _ball
var _swing_input
var _hud
var _strokes := 0


func _ready() -> void:
	_setup_environment()
	_course = Course.new()
	_course.name = "Course"
	add_child(_course)

	_ball = GolfBall.new()
	_ball.name = "GolfBall"
	_ball.position = _course.tee_position
	add_child(_ball)

	var camera_rig := CameraRig.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)

	_swing_input = SwingInput.new()
	_swing_input.name = "SwingInput"
	add_child(_swing_input)
	_swing_input.aim_changed.connect(_on_aim_changed)
	_swing_input.phase_changed.connect(_on_phase_changed)
	_swing_input.swing_released.connect(_on_swing_released)

	_hud = Hud.new()
	_hud.name = "HUD"
	add_child(_hud)
	_hud.update_hole(_distance_to_cup(), _strokes)


func _process(_delta: float) -> void:
	_swing_input.enabled = _ball.is_settled()
	_hud.update_hole(_distance_to_cup(), _strokes)


func _on_aim_changed(degrees: float) -> void:
	_hud.set_aim_value(degrees)


func _on_phase_changed(description: String, power: float) -> void:
	_hud.update_swing(description, power)


func _on_swing_released(sample: Dictionary) -> void:
	var shot := ShotCalculator.calculate(sample)
	_ball.launch(shot.velocity)
	_strokes += 1
	_hud.show_shot(shot.power, shot.direction_degrees, shot.accuracy)


func _distance_to_cup() -> float:
	var cup: Vector3 = _course.cup_position
	return Vector2(_ball.global_position.x - cup.x, _ball.global_position.z - cup.z).length()


func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sunlight.light_energy = 1.25
	sunlight.shadow_enabled = true
	add_child(sunlight)
