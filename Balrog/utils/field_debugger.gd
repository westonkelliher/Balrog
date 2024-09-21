@tool
extends Node3D
class_name FieldDebugger

@export var radius := 0.5 :
	set(value):
		radius = value
		if $FieldCollider.shape == null:
			return
		$FieldCollider.shape.radius = value
	get:
		return radius

@export var target_body: Node3D = null


var t := 0.0

func _notification(what: int) -> void:
	if what == Node3D.NOTIFICATION_TRANSFORM_CHANGED:
		update_ray()

func update_ray() -> void:
	var fb: FieldBody = target_body.get_child(1)
	$FieldCollider/RayCast.target_position = fb.field_up($FieldCollider.global_position)*3.0

func _process(delta: float) -> void:
	t += delta
	$FieldCollider.position = Vector3.ONE*cos(t)
	update_ray()

func _ready() -> void:
	$FieldCollider.shape = $FieldCollider.shape.duplicate()
	radius = radius

func handle_fieldedbody_collision(fb: FieldBody) -> void:
	var signed_distance: float = fb.signed_distance_func.call(global_position)
	var normal: Vector3 = fb.normal_func.call(global_position)
	var depth := radius - signed_distance
	#parent_body.position += normal*depth # TODO: torque
	#var vel_projection: Vector3 = parent_body.velocity.dot(normal) * normal
	#parent_body.velocity -= vel_projection
	#parent_body.velocity -= normal * ground_stick
