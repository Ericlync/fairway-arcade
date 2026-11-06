extends Node3D
## Fixed angled overhead view for the first playable hole.

var camera: Camera3D


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "CourseCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 108.0
	camera.near = 0.1
	camera.far = 300.0
	camera.position = Vector3(0.0, 55.0, 63.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, -7.0), Vector3.UP)
	camera.current = true
