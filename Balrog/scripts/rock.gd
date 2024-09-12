extends RigidBody3D
class_name Rock

var field_colliders: Array[FieldCollider] = []
var field_bodies: Array[FieldedBody] = []
var total_gravity := Vector3.ZERO


func _ready() -> void:
	field_colliders.append($FieldCollider)

func _physics_process(delta: float) -> void:
	#print(field_bodies)
	calculate_fields(delta)
	handle_floor_clips(delta)
	#print(total_gravity)
	apply_force(total_gravity)
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
	# up direction
	var up_d := Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		up_d += fb.normal_func.call(global_position) * weights[i]


func handle_floor_clips(delta: float) -> void:
	for fb in field_bodies:
		for collider in field_colliders:
			var signed_distance: float = fb.signed_distance_func.call(collider.global_position)
			if signed_distance < collider.radius:
				handle_a_floor_clip(delta, fb, collider)

func handle_a_floor_clip(delta: float, fb: FieldedBody, fc: FieldCollider) -> void:
	var signed_distance: float = fb.signed_distance_func.call(fc.global_position)
	var normal: Vector3 = fb.normal_func.call(fc.global_position)
	var depth = fc.radius - signed_distance
	position += normal*depth
	var vel_projection := linear_velocity.dot(normal) * normal
	linear_velocity -= vel_projection
	linear_velocity *= pow(0.8, delta)
	#print("clip: " + str(depth))


func _on_timer_timeout() -> void:
	queue_free()
