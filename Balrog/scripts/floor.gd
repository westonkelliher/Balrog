@tool
extends StaticBody3D

@export var radius := 1.0 :
	set(value):
		radius = value
		if $Shape == null:
			return
		$Shape.shape.radius = value
		$Mesh.mesh.top_radius = value
		$Mesh.mesh.bottom_radius = value
	get:
		return radius

@export var height := 1.0 :
	set(value):
		height = value
		if $Shape == null:
			return
		$Shape.shape.height = value
		$Mesh.mesh.height = value
	get:
		return height

@export var atmospheric_half_life := 10.0

func _ready() -> void:
	$GravObject.gravity_func = get_grav
	$GravObject.normal_func = get_normal
	$GravObject.signed_distance_func = get_signed_distance
	$GravObject.atmosphere_func = get_atmosphere
	#
	$Shape.shape = $Shape.shape.duplicate()
	$Mesh.mesh = $Mesh.mesh.duplicate()
	radius = radius
	height = height

func get_grav(p: Vector3) -> Vector3:
	return -get_normal(p) * 9.8 * 1.5
		

func get_normal(p: Vector3) -> Vector3:
	var rp = p - global_position # relative position
	var lateral_component = Vector3(rp.x, 0.0, rp.z)
	var vertical_component = Vector3(0.0, rp.y, 0.0)
	if lateral_component.length() < radius:
		return vertical_component.normalized()
	else:
		#var edge_point := lateral_component.normalized()*radius
		return rp.normalized()
		# TODO: maybe (prob not) lerp between radial and downward when near edge (outside of it tho)
		#return rp.normalized()

func get_signed_distance(p: Vector3) -> float:
	var rp = p - global_position # relative position
	var lateral_component = Vector3(rp.x, 0.0, rp.z)
	var vertical_component = Vector3(0.0, rp.y, 0.0)
	if lateral_component.length() < radius:
		return vertical_component.length() - height/2.0
	else:
		return rp.length() - radius

func get_atmosphere(p: Vector3) -> float:
	print(get_signed_distance(p))
	return atmospheric_half_life / (atmospheric_half_life + get_signed_distance(p))
