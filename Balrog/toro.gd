@tool
extends Node3D

@export var radius := 1.0 :
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

func _ready() -> void:
	$GravObject.gravity_func = get_grav
	$GravObject.normal_func = get_normal
	$GravObject.signed_distance_func = get_signed_distance
	$GravObject.atmosphere_func = get_atmosphere
	#
	$Flat.mesh = $Flat.mesh.duplicate()
	$Edge.mesh = $Edge.mesh.duplicate()
	radius = radius
	height = height

func get_grav(p: Vector3) -> Vector3:
	var mult := gravitational_half_life / (gravitational_half_life + get_signed_distance(p))
	return -get_normal(p) * 9.8 * 1.5
		

func get_normal(p: Vector3) -> Vector3:
	var rp = p - global_position # relative position
	var lateral_component = Vector3(rp.x, 0.0, rp.z)
	var vertical_component = Vector3(0.0, rp.y, 0.0)
	if lateral_component.length() < radius:
		return vertical_component.normalized()
	else:
		var edge_point := lateral_component.normalized()*radius
		return (rp-edge_point).normalized()
		# TODO: maybe (prob not) lerp between radial and downward when wanear edge (outside of it tho)

func get_signed_distance(p: Vector3) -> float:
	var rp = p - global_position # relative position
	var lateral_component = Vector3(rp.x, 0.0, rp.z)
	var vertical_component = Vector3(0.0, rp.y, 0.0)
	if lateral_component.length() < radius:
		return vertical_component.length() - height/2.0
	else:
		var edge_point := lateral_component.normalized()*radius
		return (rp-edge_point).length() - height/2.0

func get_atmosphere(p: Vector3) -> float:
	print(get_signed_distance(p))
	return atmospheric_half_life / (atmospheric_half_life + get_signed_distance(p))
