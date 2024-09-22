#@tool
extends Node3D

@export var ring_radius := 1.0 :
	set(value):
		ring_radius = value
		if !has_node("Flat"):
			return
		$Flat.mesh.top_radius = value
		$Flat.mesh.bottom_radius = value
		$Flat.mesh.height = 2.0
		#
		$Edge.mesh.inner_radius = value - 1.0
		$Edge.mesh.outer_radius = value + 1.0
	get:
		return ring_radius




func _ready() -> void:
	$FieldBody.sdf_func = get_signed_distance
	$FieldBody.up_func = get_up
	#
	$Flat.mesh = $Flat.mesh.duplicate()
	$Edge.mesh = $Edge.mesh.duplicate()
	ring_radius = ring_radius
	#
	$FieldBody/Shape.shape.height = ring_radius * 6
	$FieldBody/Shape.shape.radius = ring_radius * 3

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
