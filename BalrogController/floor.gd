extends StaticBody3D


func _ready() -> void:
	$GravObject.gravity_func = get_grav_force

func get_grav_force(p: Vector3) -> Vector3:
	if p.y > position.y:
		return Vector3.DOWN * 9.8 * 1.5
	else:
		return Vector3.UP * 9.8 * 1.5
		
