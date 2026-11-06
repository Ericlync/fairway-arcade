extends TerrainManager
class_name GolfCourse
## Procedural first golf hole with tee, fairway, green, bunkers, water, and hills.

var tee_position := Vector3(0.0, 0.0, 25.0)
var cup_position := Vector3(0.0, 0.0, -43.0)

var _noise: FastNoiseLite
var _fairway_width_tee := 13.0
var _fairway_width_green := 20.0
var _bunkers: Array[Dictionary] = []
var _water_area: Dictionary


func _init() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = 12345
	_noise.frequency = 0.018
	_noise.fractal_octaves = 3
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH

	_bunkers = [
		{"center": Vector2(-12.0, -34.0), "radius": 5.5, "depth": 1.1},
		{"center": Vector2(13.0, -47.0), "radius": 5.0, "depth": 1.0},
	]
	_water_area = {"center": Vector2(30.0, -4.0), "size": Vector2(22.0, 52.0), "level": -0.9}


func _ready() -> void:
	super._ready()
	tee_position.y = get_height_at(tee_position.x, tee_position.z) + 0.04
	cup_position.y = get_height_at(cup_position.x, cup_position.z) + 0.02
	_add_water_plane()
	_add_cup_and_flag()
	_add_trees()
	_add_course_bounds()


func _sample_height(world_x: float, world_z: float) -> float:
	var base := _noise.get_noise_2d(world_x * 0.65, world_z * 0.65) * 1.4
	base += _noise.get_noise_2d(world_x * 0.2 + 50.0, world_z * 0.2) * 2.8

	var fairway := _fairway_height(world_x, world_z)
	var green := _green_height(world_x, world_z)
	var bunker := _bunker_height(world_x, world_z)
	var hill := _hill_height(world_x, world_z)
	var water := _water_influence(world_x, world_z)

	var height := base + fairway + green + hill + water
	height = lerpf(height, bunker, _bunker_mask(world_x, world_z))
	return height * height_scale * 0.12


func _fairway_height(world_x: float, world_z: float) -> float:
	var t: float = clampf((world_z - tee_position.z) / (cup_position.z - tee_position.z), 0.0, 1.0)
	var width: float = lerpf(_fairway_width_tee, _fairway_width_green, t)
	var x_dist := absf(world_x)
	if x_dist < width:
		return -0.35 - x_dist * 0.012
	var falloff := clampf((x_dist - width) / 9.0, 0.0, 1.0)
	return lerpf(-0.35 - width * 0.012, 0.0, falloff)


func _green_height(world_x: float, world_z: float) -> float:
	var dist := Vector2(world_x - cup_position.x, world_z - cup_position.z).length()
	if dist > 14.0:
		return 0.0
	var bowl := dist * 0.018
	var slope := (world_z - cup_position.z) * 0.008
	return -0.42 + bowl + slope


func _bunker_mask(world_x: float, world_z: float) -> float:
	var amount := 0.0
	for bunker in _bunkers:
		var center: Vector2 = bunker["center"]
		var radius: float = bunker["radius"]
		var dist := Vector2(world_x - center.x, world_z - center.y).length()
		if dist < radius:
			amount = maxf(amount, smoothstep(radius, radius * 0.35, dist))
	return amount


func _bunker_height(world_x: float, world_z: float) -> float:
	for bunker in _bunkers:
		var center: Vector2 = bunker["center"]
		var radius: float = bunker["radius"]
		var depth: float = bunker["depth"]
		var dist := Vector2(world_x - center.x, world_z - center.y).length()
		if dist < radius:
			var bowl := pow(dist / radius, 2.0) * depth
			return -depth + bowl
	return 0.0


func _hill_height(world_x: float, world_z: float) -> float:
	var h := 0.0
	h += _hill_bump(world_x, world_z, Vector2(-38.0, -22.0), 18.0, 3.2)
	h += _hill_bump(world_x, world_z, Vector2(42.0, 16.0), 20.0, 2.8)
	h += _hill_bump(world_x, world_z, Vector2(36.0, -50.0), 16.0, 3.6)
	h += _hill_bump(world_x, world_z, Vector2(-30.0, 16.0), 14.0, 1.8)
	return h


func _hill_bump(x: float, z: float, center: Vector2, radius: float, height: float) -> float:
	var dist := Vector2(x - center.x, z - center.y).length()
	if dist > radius:
		return 0.0
	var t := dist / radius
	return height * (1.0 - t * t) * (1.0 - t * t)


func _water_influence(world_x: float, world_z: float) -> float:
	var center: Vector2 = _water_area["center"]
	var size: Vector2 = _water_area["size"]
	var dx := absf(world_x - center.x) / (size.x * 0.5)
	var dz := absf(world_z - center.y) / (size.y * 0.5)
	var d := maxf(dx, dz)
	if d < 1.0:
		return -0.45 * (1.0 - d)
	return 0.0


func _vertex_color(world_x: float, world_z: float) -> Color:
	if _is_bunker(world_x, world_z):
		return Color(0.78, 0.66, 0.43)
	if _is_green(world_x, world_z):
		return Color(0.30, 0.72, 0.26)
	if _is_fairway(world_x, world_z):
		return Color(0.26, 0.56, 0.24)
	if _is_water(world_x, world_z):
		return Color(0.10, 0.30, 0.20)
	return Color(0.16, 0.40, 0.18)


func get_surface_type(world_x: float, world_z: float) -> String:
	if _is_water(world_x, world_z):
		return "water"
	if _is_bunker(world_x, world_z):
		return "bunker"
	if _is_green(world_x, world_z):
		return "green"
	if _is_fairway(world_x, world_z):
		return "fairway"
	return "rough"


func _is_fairway(world_x: float, world_z: float) -> bool:
	if world_z > tee_position.z + 2.0 or world_z < cup_position.z - 14.0:
		return false
	var t: float = clampf((world_z - tee_position.z) / (cup_position.z - tee_position.z), 0.0, 1.0)
	var width: float = lerpf(_fairway_width_tee, _fairway_width_green, t)
	return absf(world_x) < width + 1.5


func _is_green(world_x: float, world_z: float) -> bool:
	return Vector2(world_x - cup_position.x, world_z - cup_position.z).length() < 14.0


func _is_bunker(world_x: float, world_z: float) -> bool:
	for bunker in _bunkers:
		var center: Vector2 = bunker["center"]
		var radius: float = bunker["radius"]
		if Vector2(world_x - center.x, world_z - center.y).length() < radius * 0.92:
			return true
	return false


func _is_water(world_x: float, world_z: float) -> bool:
	var center: Vector2 = _water_area["center"]
	var size: Vector2 = _water_area["size"]
	return absf(world_x - center.x) < size.x * 0.5 and absf(world_z - center.y) < size.y * 0.5


func _add_water_plane() -> void:
	var water := MeshInstance3D.new()
	water.name = "WaterHazard"
	var plane := PlaneMesh.new()
	plane.size = _water_area["size"]
	water.mesh = plane
	water.position = Vector3(_water_area["center"].x, _water_area["level"], _water_area["center"].y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.43, 0.67)
	mat.roughness = 0.12
	mat.metallic = 0.0
	water.material_override = mat
	add_child(water)


func _add_cup_and_flag() -> void:
	var cup := MeshInstance3D.new()
	cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.48
	cup_mesh.bottom_radius = 0.48
	cup_mesh.height = 0.04
	cup.mesh = cup_mesh
	cup.position = cup_position + Vector3(0.0, 0.01, 0.0)
	cup.material_override = _material(Color(0.04, 0.05, 0.05))
	add_child(cup)

	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.035
	pole_mesh.bottom_radius = 0.05
	pole_mesh.height = 3.4
	pole.mesh = pole_mesh
	pole.position = cup_position + Vector3(0.0, 1.72, 0.0)
	pole.material_override = _material(Color(0.93, 0.92, 0.82), 0.55)
	add_child(pole)

	var flag := MeshInstance3D.new()
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(0.9, 0.52, 0.06)
	flag.mesh = flag_mesh
	flag.position = cup_position + Vector3(0.48, 3.05, 0.0)
	flag.material_override = _material(Color(0.88, 0.19, 0.12), 0.6)
	add_child(flag)


func _add_trees() -> void:
	var tree_positions := [
		Vector3(-24.0, 0.0, 14.0), Vector3(-34.0, 0.0, -6.0),
		Vector3(24.0, 0.0, -20.0), Vector3(38.0, 0.0, 26.0),
		Vector3(-26.0, 0.0, -54.0), Vector3(28.0, 0.0, -60.0),
		Vector3(-48.0, 0.0, -28.0), Vector3(52.0, 0.0, 10.0),
	]
	for pos in tree_positions:
		if _is_fairway(pos.x, pos.z) or _is_green(pos.x, pos.z) or _is_bunker(pos.x, pos.z) or _is_water(pos.x, pos.z):
			continue
		_add_tree(pos)


func _add_tree(tree_position: Vector3) -> void:
	tree_position.y = get_height_at(tree_position.x, tree_position.z)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 2.0
	trunk_mesh.radial_segments = 8
	trunk.mesh = trunk_mesh
	trunk.position = tree_position + Vector3(0.0, 1.0, 0.0)
	trunk.material_override = _material(Color(0.33, 0.22, 0.12))
	add_child(trunk)

	for tier in range(3):
		var canopy := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 1.15 - tier * 0.23
		cone.height = 1.65
		cone.radial_segments = 9
		canopy.mesh = cone
		canopy.position = tree_position + Vector3(0.0, 2.0 + tier * 0.95, 0.0)
		canopy.material_override = _material(Color(0.12 + tier * 0.025, 0.36 + tier * 0.035, 0.18))
		add_child(canopy)


func _add_course_bounds() -> void:
	var bounds := StaticBody3D.new()
	bounds.name = "OutOfBounds"
	var half_x := terrain_size.x * 0.5 + 4.0
	var half_z := terrain_size.y * 0.5 + 4.0
	for side in [
		Vector3(half_x, 5.0, 0.0), Vector3(-half_x, 5.0, 0.0),
		Vector3(0.0, 5.0, half_z), Vector3(0.0, 5.0, -half_z),
	]:
		var wall := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0, 10.0, terrain_size.y + 8.0) if absf(side.x) > 1.0 else Vector3(terrain_size.x + 8.0, 10.0, 2.0)
		wall.shape = box
		wall.position = side
		bounds.add_child(wall)
	add_child(bounds)


func _material(tint: Color, roughness := 0.88) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.roughness = roughness
	return result
