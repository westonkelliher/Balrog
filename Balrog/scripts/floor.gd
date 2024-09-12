@tool
extends StaticBody3D

@export var radius := 1.0 :
	set(value):
		radius = value
		if $Flat == null:
			return
		$Flat.mesh.top_radius = value
		$Flat.mesh.bottom_radius = value
		#
		$Edge.mesh.inner_radius = value - height/2.0
		$Edge.mesh.outer_radius = value + height/2.0
	get:
		return radius

@export var height := 1.0 :
	set(value):
		height = value
		if $Flat == null:
			return
		$Flat.mesh.height = value
		#
		$Edge.mesh.inner_radius = radius - value/2.0
		$Edge.mesh.outer_radius = radius + value/2.0
	get:
		return height

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
	var whole_normal := basis * Vector3.UP
	var vertical_component := rp.dot(whole_normal) * whole_normal # projections
	var lateral_component = rp - vertical_component
	if lateral_component.length() < radius:
		return vertical_component.normalized()
	else:
		var edge_point := lateral_component.normalized()*radius
		return (rp-edge_point).normalized()
		# TODO: maybe (prob not) lerp between radial and downward when wanear edge (outside of it tho)

func get_signed_distance(p: Vector3) -> float:
	var rp = p - global_position # relative position
	var whole_normal := basis * Vector3.UP
	var vertical_component := rp.dot(whole_normal) * whole_normal # projections
	var lateral_component = rp - vertical_component
	if lateral_component.length() < radius:
		return vertical_component.length() - height/2.0
	else:
		var edge_point := lateral_component.normalized()*radius
		return (rp-edge_point).length() - height/2.0

func get_atmosphere(p: Vector3) -> float:
	#print(get_signed_distance(p))
	return atmospheric_half_life / (atmospheric_half_life + get_signed_distance(p))
