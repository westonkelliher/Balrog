extends RigidBody3D
class_name Rock




func _on_timer_timeout() -> void:
	queue_free()
