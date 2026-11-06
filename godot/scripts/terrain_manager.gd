extends Node3D
class_name TerrainManager
## Shared heightfield generator: builds a visual mesh and a matching collision
## shape from the same height data so the ball rolls on real 3D terrain.

@export var terrain_size: Vector2 = Vector2(180.0, 150.0)
@export var cell_size: float = 2.0
@export var height_scale: float = 12.0

var _map_width: int = 0
var _map_depth: int = 0
var _mesh_instance: MeshInstance3D
var _collision_body: StaticBody3D


func _ready() -> void:
	_generate()


func _generate() -> void:
	_map_width = maxi(2, ceili(terrain_size.x / cell_size) + 1)
	_map_depth = maxi(2, ceili(terrain_size.y / cell_size) + 1)
	_build_mesh()
	_build_collision()


func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(_map_depth):
		for x in range(_map_width):
			var world_pos := _vertex_world_position(x, z)
			var color := _vertex_color(world_pos.x, world_pos.z)
			st.set_color(color)
			st.add_vertex(world_pos)

	for z in range(_map_depth - 1):
		for x in range(_map_width - 1):
			var i := x + z * _map_width
			var i_next := x + (z + 1) * _map_width
			st.add_index(i)
			st.add_index(i_next + 1)
			st.add_index(i + 1)
			st.add_index(i)
			st.add_index(i_next)
			st.add_index(i_next + 1)

	st.generate_normals()
	var mesh := st.commit()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TerrainMesh"
	_mesh_instance.mesh = mesh
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var terrain_material := StandardMaterial3D.new()
	terrain_material.vertex_color_use_as_albedo = true
	terrain_material.roughness = 0.92
	terrain_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = terrain_material
	add_child(_mesh_instance)


func _build_collision() -> void:
	var heights := PackedFloat32Array()
	heights.resize(_map_width * _map_depth)
	for z in range(_map_depth):
		for x in range(_map_width):
			var world_pos := _vertex_world_position(x, z)
			heights[x + z * _map_width] = world_pos.y

	var shape := HeightMapShape3D.new()
	shape.map_width = _map_width
	shape.map_depth = _map_depth
	shape.map_data = heights

	_collision_body = StaticBody3D.new()
	_collision_body.name = "TerrainCollision"
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3(cell_size, 1.0, cell_size)
	_collision_body.add_child(collision)
	add_child(_collision_body)


func _vertex_world_position(grid_x: int, grid_z: int) -> Vector3:
	var half_width := (_map_width - 1) * cell_size * 0.5
	var half_depth := (_map_depth - 1) * cell_size * 0.5
	var world_x := grid_x * cell_size - half_width
	var world_z := grid_z * cell_size - half_depth
	var world_y := _sample_height(world_x, world_z)
	return Vector3(world_x, world_y, world_z)


func get_height_at(world_x: float, world_z: float) -> float:
	return _sample_height(world_x, world_z)


func get_surface_normal(world_x: float, world_z: float) -> Vector3:
	var sample_step := maxf(cell_size, 0.5)
	var left := _sample_height(world_x - sample_step, world_z)
	var right := _sample_height(world_x + sample_step, world_z)
	var forward := _sample_height(world_x, world_z - sample_step)
	var back := _sample_height(world_x, world_z + sample_step)
	return Vector3(left - right, sample_step * 2.0, forward - back).normalized()


## Override this in subclasses to define real terrain shape.
func _sample_height(world_x: float, world_z: float) -> float:
	return 0.0


## Override this in subclasses to tint different surfaces.
func _vertex_color(world_x: float, world_z: float) -> Color:
	return Color(0.18, 0.38, 0.18)
