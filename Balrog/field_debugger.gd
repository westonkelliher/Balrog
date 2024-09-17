@tool
extends CollisionShape3D
class_name FieldDebugger

@export var radius := 0.5 :
	set(value):
		radius = value
		if shape == null:
			return
		shape.radius = value
	get:
		return radius

@export var target_body: Node3D = null


func _notification(what: int) -> void:
	if what == Node3D.NOTIFICATION_TRANSFORM_CHANGED:
		print("sa")
		var fb: FieldBody = target_body.get_child(1)
		$RayCast.target_position = fb.field_normal(global_position)
		print($RayCast.target_position)


func _ready() -> void:
	shape = shape.duplicate()
	radius = radius

func handle_fieldedbody_collision(fb: FieldBody) -> void:
	var signed_distance: float = fb.signed_distance_func.call(global_position)
	var normal: Vector3 = fb.normal_func.call(global_position)
	var depth := radius - signed_distance
	#parent_body.position += normal*depth # TODO: torque
	#var vel_projection: Vector3 = parent_body.velocity.dot(normal) * normal
	#parent_body.velocity -= vel_projection
	#parent_body.velocity -= normal * ground_stick
