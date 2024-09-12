extends StaticBody3D


func _ready() -> void:
	$GravObject.gravity_func = get_grav_force

func get_grav_force(p: Vector3) -> Vector3:
	var toward_p := (p - global_position).normalized()
	print(toward_p)
	return -toward_p * 9.8 * 2.0
		
