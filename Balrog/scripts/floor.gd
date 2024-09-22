@tool
extends Node3D

@export var ring_radius := 1.0 :
	set(value):
		ring_radius = value
		if !has_node("Box"):
			print("A")
			return
		print("B")
		$Box.mesh.material.set("shader_parameter/ring_radius", value)
		#print("-" + str($Box.mesh.material))
		$Box.mesh.size.x = value*2 + 2
		$Box.mesh.size.z = value*2 + 2
		#
		$FieldBody/Shape.shape.height = ring_radius * 6
		$FieldBody/Shape.shape.radius = ring_radius * 3
	get:
		return ring_radius

func _notification(what: int) -> void:
	if what == Node3D.NOTIFICATION_TRANSFORM_CHANGED:
		$Box.mesh.material.set("shader_parameter/scale", global_basis.get_scale().x)
	


func _ready() -> void:
	print("abc")
	$FieldBody.sdf_func = get_signed_distance
	$FieldBody.up_func = get_up
	#
	$Box.mesh = $Box.mesh.duplicate()
	$Box.mesh.material = preload("res://mats/field_body_mat.tres").duplicate()
	$Box.mesh.material.set("shader_parameter/type", 3)
	print("-A")
	$Box.mesh.material.set("shader_parameter/ring_radius", .5)
	print("--A")
	#
	ring_radius = ring_radius

func get_signed_distance(rp: Vector3) -> float:
	var vertical_component := Vector3(0.0, rp.y,  0.0)
	var lateral_component := rp - vertical_component
	if lateral_component.length() < ring_radius:
		return vertical_component.length() - 1.0
	else:
		var edge_point := lateral_component.normalized()*ring_radius
		return (rp - edge_point).length() - 1.0
		# TODO: maybe (prob not) lerp between radial and downward when wanear edge (outside of it tho)

func get_up(rp: Vector3) -> Vector3:
	var vertical_component := Vector3(0.0, rp.y,  0.0)
	var lateral_component := rp - vertical_component
	if lateral_component.length() < ring_radius:
		return vertical_component.normalized()
	else:
		var edge_point := lateral_component.normalized()*ring_radius
		return (rp - edge_point).normalized()
		# TODO: maybe (prob not) lerp between radial and downward when wanear edge (outside of it tho)
