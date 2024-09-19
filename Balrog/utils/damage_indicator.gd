extends Node2D



func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var parent := get_parent()
	var p_3d: Vector3 = parent.global_position + parent.global_basis * Vector3.UP
	position = cam.unproject_position(p_3d)
	var distance := p_3d.distance_to(cam.global_position)
	scale = Vector2.ONE * pow(distance, -0.7) * 3.0


func set_number(number: int) -> void:
	$Label.text = str(number)
