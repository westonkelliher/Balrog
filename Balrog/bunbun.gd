extends CharacterBody3D
class_name Bunbun

var field_colliders: Array[FieldCollider] = []
var field_bodies: Array[FieldedBody] = []
var total_gravity := Vector3.ZERO

var grav_mult := 2.5

var target_direction := Vector3.ZERO

func _ready() -> void:
	field_colliders.append($FieldCollider)
	var temp := global_position
	global_position = Vector3(100000.0, 100000.0, 100000.0)
	global_position = temp
	field_bodies = get_parent().get_node("Balrog").field_bodies

func _physics_process(delta: float) -> void:
	calculate_fields(delta)
	handle_floor_clips(delta)
	#print(total_gravity)
	velocity += total_gravity * delta
	move_and_slide()
	#move_and_collide(linear_velocity)

func calculate_fields(delta: float) -> void:
	# calculate weights
	var weights := []
	var total_weight := 0.0
	for fb in field_bodies:
		var signed_distance: float = fb.signed_distance_func.call(global_position)
		var w:= 1.0/pow(abs(signed_distance), 0.7)
		total_weight += w
		weights.append(w)
	for i in weights.size():
		weights[i] /= total_weight
	# gravity
	total_gravity = Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		total_gravity += fb.gravity_func.call(global_position) * weights[i]
	total_gravity *= grav_mult
	# up direction
	var up_d := Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		up_d += fb.normal_func.call(global_position) * weights[i]
	if up_d.length()== 0.0:
		up_direction = Vector3.UP
	else:
		up_direction = up_d.normalized()
	


func handle_floor_clips(delta: float) -> void:
	for fb in field_bodies:
		for collider in field_colliders:
			var signed_distance: float = fb.signed_distance_func.call(collider.global_position)
			if signed_distance < collider.radius:
				handle_a_floor_clip(delta, fb, collider)

func handle_a_floor_clip(delta: float, fb: FieldedBody, fc: FieldCollider) -> void:
	#
	var signed_distance: float = fb.signed_distance_func.call(fc.global_position)
	var normal: Vector3 = fb.normal_func.call(fc.global_position)
	print(normal)
	var depth := fc.radius - signed_distance
	position += normal*depth
	var dot := velocity.dot(normal)
	if dot < 0.0:
		var vel_projection := velocity.dot(normal) * normal
		velocity -= vel_projection
	velocity *= pow(0.8, delta)
	#print("clip: " + str(depth))
