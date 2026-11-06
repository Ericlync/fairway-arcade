extends SceneTree
## Small headless smoke test for the keyboard-aim plus trackpad-swing path.

const TrackpadInputScript = preload("res://scripts/trackpad_input.gd")
const ShotCalculator = preload("res://scripts/shot_calculator.gd")

var captured_sample: Dictionary = {}


func _initialize() -> void:
	var detector = TrackpadInputScript.new()
	root.add_child(detector)
	detector.swing_released.connect(_capture_swing)

	# Simulate a 160 px backswing followed by a fast 120 px forward flick.
	detector._begin_swing()
	detector._sample_drag(Vector2(0.0, 160.0))
	detector._sample_drag(Vector2(-8.0, -120.0))
	detector._finish_swing()

	assert(not captured_sample.is_empty(), "A completed drag should emit a swing sample")
	assert(captured_sample.power > 0.0, "A completed swing should have positive power")
	var shot: Dictionary = ShotCalculator.calculate(captured_sample)
	assert(shot.velocity.y > 0.0, "A golf shot should launch upward")
	assert(shot.velocity.z < 0.0, "The default shot should travel down-course")
	print("Swing input smoke test passed (power %.2f)." % captured_sample.power)
	quit()


func _capture_swing(sample: Dictionary) -> void:
	captured_sample = sample
