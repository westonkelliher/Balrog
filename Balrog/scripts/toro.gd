@tool
extends Node3D

@export var radius := 2.0 :
	set(value):
		radius = value
		if $Mesh == null:
			return
		$Mesh.mesh.inner_radius = value - thickness
		$Mesh.mesh.outer_radius = value + thickness
	get:
		return radius

@export var thickness := 0.5 :
	set(value):
		thickness = value
		if $Mesh == null:
			return
		$Mesh.mesh.inner_radius = radius - value
		$Mesh.mesh.outer_radius = radius + value
	get:
		return thickness

@export var atmospheric_half_life := 10.0
@export var gravitational_half_life := 20.0
@export var base_gravity := 9.8 * 2.0

func _ready() -> void:
	$GravObject.gravity_func = get_grav
	$GravObject.normal_func = get_normal
	$GravObject.signed_distance_func = get_signed_distance
	$GravObject.atmosphere_func = get_atmosphere
	#
	$Mesh.mesh = $Mesh.mesh.duplicate()
	radius = radius
	thickness - thickness

func get_grav(p: Vector3) -> Vector3:
	var rp := p - global_position # relative positionvar lateral_component = rp - vertical_component
	#
	var lateral_component := get_lateral_component(rp)
	if lateral_component.length() < radius:
		return get_internal_grav(p)
	var mult := gravitational_half_life / (gravitational_half_life + get_signed_distance(p))
	return -get_normal(p) * mult * base_gravity

func get_internal_grav(p: Vector3) -> Vector3:
	var rp := p - global_position # relative positionvar lateral_component = rp - vertical_component
	#
	var near_lateral_component := get_lateral_component(rp)
	var near_lateral_center := near_lateral_component.normalized() * radius
	var near_normal := (rp-near_lateral_center).normalized()
	var near_distance := get_relative_signed_distance(rp)
	var near_mult := gravitational_half_life / (gravitational_half_life + near_distance)
	var near_gravity := -near_normal * near_mult * base_gravity
	var near_weight := 1.0/near_distance
	#
	var far_lateral_component := get_lateral_component(-rp)
	var far_lateral_center := far_lateral_component.normalized() * radius
	var far_abnormal := rp-far_lateral_center
	var far_distance := (rp-far_lateral_center).length() - thickness
	var far_mult := gravitational_half_life / (gravitational_half_life + far_distance)
	var far_gravity := -far_abnormal.normalized() * far_mult * base_gravity
	var far_weight := 1.0/far_abnormal.length()
	#
	return (near_gravity*near_weight + far_gravity*far_weight) / (near_weight + far_weight)


func get_normal(p: Vector3) -> Vector3:
	var rp := p - global_position # relative position
	var lateral_component := get_lateral_component(rp)
	var lateral_center := lateral_component.normalized() * radius
	if lateral_component.length() < radius:
		return get_internal_normal(p)
	return (rp-lateral_center).normalized()
		# TODO: maybe (prob not) lerp between radial and downward when wanear edge (outside of it tho)

func get_internal_normal(p: Vector3) -> Vector3:
	var rp := p - global_position # relative position
	#
	var whole_normal := basis * Vector3.UP
	var vertical_component := rp.dot(whole_normal) * whole_normal # projections
	var lateral_component := rp - vertical_component
	var near_lateral_center := lateral_component.normalized() * radius
	var near_normal := (rp-near_lateral_center).normalized()
	var near_distance := get_relative_signed_distance(rp)
	var near_weight := 1.0/near_distance
	# 
	var inner_radius := radius - thickness
	var inner_normal := vertical_component.normalized()
	var inner_distance := lateral_component.length()
	var inner_weight := 1.0/inner_distance
	#
	return (near_weight*near_normal + inner_weight*inner_normal) / (near_weight + inner_weight)

func get_signed_distance(p: Vector3) -> float:
	var rp := p - global_position # relative position
	return get_relative_signed_distance(rp)

func get_relative_signed_distance(rp: Vector3) -> float:
	var lateral_component := get_lateral_component(rp)
	var lateral_center := lateral_component.normalized() * radius
	return (rp-lateral_center).length() - thickness

func get_atmosphere(p: Vector3) -> float:
	return atmospheric_half_life / (atmospheric_half_life + get_signed_distance(p))

func get_lateral_component(rp: Vector3) -> Vector3:
	var whole_normal := basis * Vector3.UP
	var vertical_component := rp.dot(whole_normal) * whole_normal # projections
	var lateral_component := rp - vertical_component
	return lateral_component
