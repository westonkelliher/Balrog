extends Area3D
class_name GravObject

var bodies := []
@export var gravity_func: Callable = default_get_grav_force



func default_get_grav_force(p: Vector3) -> Vector3:
	return Vector3.DOWN * 9.8



func _on_body_entered(body: Node3D) -> void:
	print("enter")
	bodies.append(body)
	if "gravities" in body:
		body.gravities.append(self)
		print(body.gravities)

func _on_body_exited(body: Node3D) -> void:
	print("exit")
	bodies.erase(body)
	if "gravities" in body:
		var g: Array = body.gravities
		g.erase(self)
		print(body.gravities)
