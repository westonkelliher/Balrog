@tool
extends Area3D
class_name FieldBody

var bodies := []
var sdf_func: Callable = default_sdf
var up_func: Callable = default_up
var gravity_func: Callable = default_gravity
var atmosphere_func: Callable = default_atmosphere
@export var base_gravity: float = 9.8
@export var gravitational_half_life: float = 1.0
@export var atmospheric_half_life: float = 1.0
@export var uniform_scale := 1.0 :
	set(value):
		if value < 0.01:
			return
		var s := global_basis.get_scale().x
		var ratio := value/s
		get_parent().scale *= ratio
		uniform_scale = global_basis.get_scale().x
	get:
		return global_basis.get_scale().x
		#return .x
		
		


func _notification(what: int) -> void:
	if what == Node3D.NOTIFICATION_TRANSFORM_CHANGED:
		var gs := global_basis.get_scale()
		#print(str(gs.x) + " " +str(gs.x) + " " +str(gs.x) )
		#if gs.x == gs.y and gs.x == gs.z:
			#print("sas")
		#else:
			#print("no")
		assert(abs(gs.x - gs.y) < 0.0001 and abs(gs.x - gs.z) < 0.0001) # uniform scaling required
		uniform_scale = gs.x

# default to a sphere
# this is the only one you have to override to change the shape, others are optional
func default_sdf(rp: Vector3) -> float:
	return rp.length() - 1.0

# TODO: this function seems to cause stutteryness in the up-direcition-field
func surface_normal(p: Vector3) -> Vector3:
	var ep := 0.0001
	var e := Vector2(1.0,-1.0)*0.5773
	var xyy := Vector3(e.x, e.y, e.y)
	var yxy := Vector3(e.y, e.x, e.y)
	var yyx := Vector3(e.y, e.y, e.x)
	var xxx := Vector3(e.x, e.x, e.x)
	return ( xyy*field_sdf(p + xyy*ep)
		+ yxy*field_sdf(p + yxy*ep)
		+ yyx*field_sdf(p + yyx*ep)
		+ xxx*field_sdf(p + xxx*ep) ).normalized();

func default_gravity(p: Vector3) -> Vector3:
	var ghl := gravitational_half_life
	return -field_up(p) * base_gravity * ghl / (ghl + field_sdf(p))  * uniform_scale

func default_up(p: Vector3) -> Vector3:
	return surface_normal(p)

func default_atmosphere(rp: Vector3) -> float:
	var ahl := atmospheric_half_life
	return ahl / (ahl + field_sdf(rp)) * uniform_scale

##

func field_sdf(p: Vector3) -> float:
	#print("field sdf")
	var rp := global_transform.affine_inverse() * p
	return sdf_func.call(rp) * uniform_scale

func field_up(p: Vector3) -> Vector3:
	var rp := global_transform.affine_inverse() * p
	return global_basis * up_func.call(rp) / uniform_scale

func field_gravity(p: Vector3) -> Vector3:
	return gravity_func.call(p)

func field_atmosphere(p: Vector3) -> float:
	return atmosphere_func.call(p)

#func _ready() -> void:
	#await get_tree().physics_frame
	## Manually process bodies already inside the area
	#for body in get_overlapping_bodies():
		#_on_body_entered(body)

func _on_body_entered(body: Node3D) -> void:
	bodies.append(body)
	if "field_bodies" in body:
		print("enter")
		body.field_bodies.append(self)

func _on_body_exited(body: Node3D) -> void:
	bodies.erase(body)
	if "field_bodies" in body:
		print("exit")
		var g: Array = body.field_bodies
		g.erase(self)
