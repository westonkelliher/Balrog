extends Node2D



func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var parent := get_parent()
	var p_3d: Vector3 = parent.global_position + parent.global_basis * Vector3.UP
	p_3d += parent.global_basis * Vector3.UP * ($Timer.wait_time - $Timer.time_left)
	position = cam.unproject_position(p_3d)
	var distance := p_3d.distance_to(cam.global_position)
	scale = Vector2.ONE * pow(distance, -0.6) * 1.5


func set_number(number: int) -> void:
	$Label.text = str(number)


func _on_timer_timeout() -> void:
	queue_free()
