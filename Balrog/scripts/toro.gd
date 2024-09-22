@tool
extends Node3D

@export var ring_radius := 1.0 :
	set(value):
		ring_radius = value
		if !has_node("Box"):
			return
		$Box.mesh.material.set("shader_parameter/ring_radius", value)
		#print("-" + str($Box.mesh.material))
		$Box.mesh.size.x = value*2 + 2
		$Box.mesh.size.z = value*2 + 2
	get:
		return ring_radius

func _notification(what: int) -> void:
	if what == Node3D.NOTIFICATION_TRANSFORM_CHANGED:
		$Box.mesh.material.set("shader_parameter/scale", global_basis.get_scale().x)
		



func _ready() -> void:
	$FieldBody.sdf_func = get_signed_distance
	$FieldBody.up_func = get_up
	#
	$Box.mesh = $Box.mesh.duplicate()
	$Box.mesh.material = preload("res://mats/field_body_mat.tres").duplicate()
	$Box.mesh.material.set("shader_parameter/type", 2)
	#print("ini " + str($Box.mesh.material))
	#$Box.mesh.material.shader = $Box.mesh.material.shader.duplicate()
	ring_radius = ring_radius
	#

func get_grav(p: Vector3) -> Vector3:
	var rp := global_transform.affine_inverse() * p # relative position
	#get_node("break").break()
	#
	var lateral_component := get_lateral_component(rp)
	if lateral_component.length() < ring_radius:
		return get_internal_grav(p)
	var ghl: float = $FieldBody.gravitational_half_life
	var mult := ghl / (ghl + get_signed_distance(rp))
	return -get_up(p) * mult * $FieldBody.base_gravity

func get_internal_grav(rp: Vector3) -> Vector3:
	#
	var near_lateral_component := get_lateral_component(rp)
	var near_lateral_center := near_lateral_component.normalized() * ring_radius
	var near_normal := (rp-near_lateral_center).normalized()
	var near_distance := get_signed_distance(rp)
	var ghl: float = $FieldBody.gravitational_half_life
	var near_mult := ghl / (ghl + near_distance)
	var near_gravity: Vector3 = -near_normal * near_mult * $FieldBody.base_gravity
	var near_weight := 1.0/pow(near_distance, 2)
	#
	var far_lateral_component := get_lateral_component(-rp)
	var far_lateral_center := far_lateral_component.normalized() * ring_radius
	var far_abnormal := rp-far_lateral_center
	var far_distance := (rp-far_lateral_center).length() - 1.0
	var far_mult := ghl / (ghl + far_distance)
	var far_gravity: Vector3 =  -far_abnormal.normalized() * far_mult * $FieldBody.base_gravity
	var far_weight := 1.0/pow(far_abnormal.length(), 2)
	#
	return (near_gravity*near_weight + far_gravity*far_weight) / (near_weight + far_weight)
	#return near_gravity

func get_up(rp: Vector3) -> Vector3:
	var lateral_component := get_lateral_component(rp)
	var lateral_center := lateral_component.normalized() * ring_radius
	#if lateral_component.length() < ring_radius:
		#return get_internal_normal(rp)
	return (rp-lateral_center).normalized()
		# TODO: maybe (prob not) lerp between radial and downward when wanear edge (outside of it tho)

func get_internal_normal(rp: Vector3) -> Vector3:
	var whole_normal := Vector3.UP
	var vertical_component := rp.dot(whole_normal) * whole_normal # projections
	var lateral_component := rp - vertical_component
	var near_lateral_center := lateral_component.normalized() * ring_radius
	var near_normal := (rp-near_lateral_center).normalized()
	var near_distance := get_signed_distance(rp)
	var near_weight := 1.0/near_distance
	# 
	var inner_radius := ring_radius - 1.0
	var inner_normal := vertical_component.normalized()
	var inner_distance := lateral_component.length()
	var inner_weight := 1.0/inner_distance
	#
	return (near_weight*near_normal + inner_weight*inner_normal) / (near_weight + inner_weight)


func get_signed_distance(rp: Vector3) -> float:
	var lateral_component := get_lateral_component(rp)
	var lateral_center := lateral_component.normalized() * ring_radius
	return (rp-lateral_center).length() - 1.0
	# TODO: have to multiply back the scale

func get_lateral_component(rp: Vector3) -> Vector3:
	var lateral_component := Vector3(rp.x, 0.0, rp.z)
	return lateral_component
