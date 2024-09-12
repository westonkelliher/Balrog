@tool
extends StaticBody3D

@export var radius := 1.0 :
	set(value):
		radius = value
		if $Mesh == null:
			return
		$Mesh.mesh.radius = value
		$Mesh.mesh.height = value*2
	get:
		return radius

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

func get_grav(p: Vector3) -> Vector3:
	var mult := gravitational_half_life / (gravitational_half_life + get_signed_distance(p))
	return -get_normal(p) * mult * base_gravity
		

func get_normal(p: Vector3) -> Vector3:
	var rp = p - global_position # relative position
	return rp.normalized()

func get_signed_distance(p: Vector3) -> float:
	var rp = p - global_position # relative position
	return rp.length() - radius

func get_atmosphere(p: Vector3) -> float:
	return atmospheric_half_life / (atmospheric_half_life + get_signed_distance(p))
