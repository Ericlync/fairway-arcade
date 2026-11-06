extends SceneTree

func _initialize() -> void:
	var shape := HeightMapShape3D.new()
	for prop in shape.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_EDITOR != 0 or prop["usage"] & PROPERTY_USAGE_STORAGE != 0:
			print(prop["name"], " type: ", prop["type"])
	quit()
