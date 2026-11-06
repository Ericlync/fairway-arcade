extends Node3D
## Procedural first-hole course. Surface patches are visuals over a flat collider.

var tee_position := Vector3(0.0, 0.25, 27.0)
var cup_position := Vector3(0.0, 0.0, -43.0)


func _ready() -> void:
	_build_ground()
	_add_patch("Fairway", Vector3(0.0, 0.01, -3.0), Vector2(27.0, 112.0), Color(0.22, 0.53, 0.22))
	_add_patch("Green", Vector3(0.0, 0.025, -41.0), Vector2(30.0, 22.0), Color(0.30, 0.68, 0.28))
	_add_patch("Water", Vector3(30.0, 0.02, -4.0), Vector2(22.0, 52.0), Color(0.08, 0.43, 0.67), 0.22)
	_add_bunker(Vector3(-13.0, 0.08, -35.0), Vector2(8.0, 5.0))
	_add_bunker(Vector3(13.0, 0.08, -48.0), Vector2(7.0, 5.0))
	_add_cup_and_flag()
	_add_hills()
	_add_trees()


func _build_ground() -> void:
	var ground_mesh := MeshInstance3D.new()
	ground_mesh.name = "RoughAndGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(180.0, 150.0)
	ground_mesh.mesh = plane
	ground_mesh.position.y = -0.015
	ground_mesh.material_override = _material(Color(0.15, 0.38, 0.20))
	add_child(ground_mesh)

	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	body.position.y = -0.5
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(180.0, 1.0, 150.0)
	collision.shape = box
	body.add_child(collision)
	add_child(body)


func _add_patch(patch_name: String, position_3d: Vector3, dimensions: Vector2, tint: Color, roughness := 0.92) -> void:
	var patch := MeshInstance3D.new()
	patch.name = patch_name
	var plane := PlaneMesh.new()
	plane.size = dimensions
	patch.mesh = plane
	patch.position = position_3d
	patch.material_override = _material(tint, roughness)
	add_child(patch)


func _add_bunker(position_3d: Vector3, dimensions: Vector2) -> void:
	var bunker := MeshInstance3D.new()
	bunker.name = "SandBunker"
	var sand := CylinderMesh.new()
	sand.top_radius = 1.0
	sand.bottom_radius = 1.0
	sand.height = 0.12
	sand.radial_segments = 32
	bunker.mesh = sand
	bunker.scale = Vector3(dimensions.x * 0.5, 1.0, dimensions.y * 0.5)
	bunker.position = position_3d
	bunker.material_override = _material(Color(0.78, 0.66, 0.43))
	add_child(bunker)


func _add_cup_and_flag() -> void:
	var cup := MeshInstance3D.new()
	cup.name = "Cup"
	var cup_mesh := CylinderMesh.new()
	cup_mesh.top_radius = 0.48
	cup_mesh.bottom_radius = 0.48
	cup_mesh.height = 0.035
	cup.mesh = cup_mesh
	cup.position = cup_position + Vector3(0.0, 0.035, 0.0)
	cup.material_override = _material(Color(0.035, 0.05, 0.045), 0.5)
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


func _add_hills() -> void:
	_add_hill(Vector3(-41.0, 1.0, -26.0), Vector3(19.0, 4.0, 20.0), Color(0.23, 0.45, 0.22))
	_add_hill(Vector3(45.0, 0.8, 17.0), Vector3(22.0, 3.4, 17.0), Color(0.20, 0.42, 0.22))
	_add_hill(Vector3(38.0, 1.0, -52.0), Vector3(18.0, 4.2, 14.0), Color(0.28, 0.49, 0.23))


func _add_hill(position_3d: Vector3, dimensions: Vector3, tint: Color) -> void:
	var hill := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 20
	sphere.rings = 10
	hill.mesh = sphere
	hill.position = position_3d
	hill.scale = dimensions
	hill.material_override = _material(tint)
	add_child(hill)


func _add_trees() -> void:
	for tree_position in [Vector3(-25.0, 0.0, 15.0), Vector3(-34.0, 0.0, -7.0), Vector3(24.0, 0.0, -21.0), Vector3(36.0, 0.0, 28.0), Vector3(-24.0, 0.0, -57.0), Vector3(27.0, 0.0, -63.0)]:
		_add_tree(tree_position)


func _add_tree(tree_position: Vector3) -> void:
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


func _material(tint: Color, roughness := 0.88) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.roughness = roughness
	return result
