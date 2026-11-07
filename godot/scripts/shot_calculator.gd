extends RefCounted
class_name ShotCalculator
## Converts a normalized swing sample into launch velocity, direction, and spin.
## Pull/push controls the initial launch direction; sidespin controls curvature.

const ClubData = preload("res://scripts/club_data.gd")

const PUSH_PULL_GAIN := 14.0
const HOOK_SLICE_GAIN := 550.0
static func calculate(sample: Dictionary) -> Dictionary:
	var power: float = clampf(float(sample.get("power", 0.0)), 0.05, 1.0)
	var accuracy: float = clampf(float(sample.get("accuracy", 1.0)), 0.0, 1.0)
	var aim_degrees: float = float(sample.get("aim_degrees", 0.0))
	var lateral_ratio: float = float(sample.get("lateral_ratio", 0.0))
	var club: Dictionary = sample.get("club", ClubData.get_club(0))

	var push_pull_degrees := lateral_ratio * PUSH_PULL_GAIN
	var launch_direction_degrees := aim_degrees + push_pull_degrees
	var launch_direction := deg_to_rad(launch_direction_degrees)

	var sidespin_rpm := -lateral_ratio * HOOK_SLICE_GAIN
	var backspin_rpm: float = float(club.get("backspin", 2200.0)) + float(club.get("backspin_power", 1800.0)) * power

	var launch_angle := deg_to_rad(lerpf(float(club.get("min_angle", 13.0)), float(club.get("max_angle", 29.0)), power))
	var speed := lerpf(float(club.get("min_speed", 16.0)), float(club.get("max_speed", 46.0)), power) * lerpf(0.82, 1.0, accuracy)
	if club.get("category", "wood") == "putter":
		launch_angle = 0.0

	var horizontal_direction := Vector3(sin(launch_direction), 0.0, -cos(launch_direction))
	var velocity := horizontal_direction * speed * cos(launch_angle)
	velocity.y = speed * sin(launch_angle)

	return {
		"velocity": velocity,
		"power": power,
		"accuracy": accuracy,
		"launch_direction_degrees": launch_direction_degrees,
		"path_degrees": clampf(lateral_ratio, -0.35, 0.35) * 30.0,
		"sidespin_rpm": sidespin_rpm,
		"backspin_rpm": backspin_rpm,
		"club_name": club.get("name", "Driver"),
		"club_category": club.get("category", "wood"),
		"roll_resistance": club.get("roll_resistance", 1.0),
		"bounce_restitution": club.get("bounce", 0.2),
	}
