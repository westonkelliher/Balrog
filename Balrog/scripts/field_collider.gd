@tool
extends CollisionShape3D
class_name FieldCollider

@export var radius := 1.0 :
	set(value):
		radius = value
		if shape == null:
			return
		shape.radius = value
	get:
		return radius

@export var ground_stick := 0.0 # TODO: maybe multiply by gravity
@export var parent_body: Node3D = null

func _ready() -> void:
	shape = shape.duplicate()
	radius = radius

func handle_fieldedbody_collision(fb: FieldedBody) -> void:
	var signed_distance: float = fb.signed_distance_func.call(global_position)
	var normal: Vector3 = fb.normal_func.call(global_position)
	var depth := radius - signed_distance
	parent_body.position += normal*depth # TODO: torque
	var vel_projection: Vector3 = parent_body.velocity.dot(normal) * normal
	parent_body.velocity -= vel_projection
	parent_body.velocity -= normal * ground_stick
