extends Area3D
class_name FieldedBody

var bodies := []
@export var gravity_func: Callable = default_get_gravity
@export var normal_func: Callable = default_get_normal
@export var signed_distance_func: Callable = default_get_signed_distance
@export var atmosphere_func: Callable = default_get_atmosphere



func default_get_gravity(p: Vector3) -> Vector3:
	return Vector3.DOWN * 9.8

func default_get_normal(p: Vector3) -> Vector3:
	return Vector3(0.0, p.y, 0.0)

func default_get_signed_distance(p: Vector3) -> float:
	return p.y

func default_get_atmosphere(p: Vector3) -> float:
	return 100.0 / (100.0 + default_get_signed_distance(p))



func _on_body_entered(body: Node3D) -> void:
	print("enter")
	bodies.append(body)
	if "field_bodies" in body:
		body.field_bodies.append(self)

func _on_body_exited(body: Node3D) -> void:
	print("exit")
	bodies.erase(body)
	if "field_bodies" in body:
		var g: Array = body.field_bodies
		g.erase(self)
