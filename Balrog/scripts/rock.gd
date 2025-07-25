extends RigidBody3D
class_name Rock

var field_colliders: Array[FieldCollider] = []
var field_bodies: Array[FieldBody] = []
var total_gravity := Vector3.ZERO

var grav_mult := 1.0

var target_direction := Vector3.ZERO

func _ready() -> void:
	field_colliders.append($FieldCollider)
	$Shape.shape = $Shape.shape.duplicate()

func _physics_process(delta: float) -> void:
	calculate_fields(delta)
	if $RedirectTimer.time_left > 0.0:
		apply_redirect()
	#print(field_bodies)
	handle_floor_clips(delta)
	#print(total_gravity)
	apply_force(total_gravity)
	#move_and_collide(linear_velocity)

func apply_redirect() -> void:
	var current_dir := linear_velocity.normalized()
	var proj := target_direction.dot(current_dir.normalized()) * current_dir
	var perp_proj := target_direction - proj
	$RayCast3D.target_position = perp_proj
	#assert()
	var mult := pow(linear_velocity.length(), 2.0)*0.24 * mass
	apply_force(perp_proj*mult)
	var grav_resistance: float = 0.4 + 0.5*($RedirectTimer.time_left / $RedirectTimer.wait_time)
	apply_force(-total_gravity * grav_resistance)

func calculate_fields(delta: float) -> void:
	# calculate weights
	var weights := []
	var total_weight := 0.0
	for fb in field_bodies:
		var signed_distance: float = fb.field_sdf(global_position)
		var w:= 1.0/pow(abs(signed_distance), 0.7)
		total_weight += w
		weights.append(w)
	for i in weights.size():
		weights[i] /= total_weight
	# gravity
	total_gravity = Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		total_gravity += fb.field_gravity(global_position) * weights[i]
	total_gravity *= grav_mult * mass
	# up direction
	var up_d := Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		up_d += fb.field_up(global_position) * weights[i]


func handle_floor_clips(delta: float) -> void:
	for fb in field_bodies:
		for collider in field_colliders:
			var signed_distance: float = fb.field_sdf(collider.global_position)
			if signed_distance < collider.radius:
				handle_a_floor_clip(delta, fb, collider)

func handle_a_floor_clip(delta: float, fb: FieldBody, fc: FieldCollider) -> void:
	var rt := $RedirectTimer
	#print(str(rt.is_stopped()) and rt.time_left > rt.wait_time)
	#print(str(rt.time_left) + " " + str(rt.wait_time))
	#if rt.time_left > rt.wait_time*0.25:
		#return
	#
	var signed_distance: float = fb.field_sdf(fc.global_position)
	var normal: Vector3 = fb.field_up(fc.global_position)
	var depth := fc.radius - signed_distance
	position += normal*depth
	var dot := linear_velocity.dot(normal)
	if dot < 0.0:
		var vel_projection := linear_velocity.dot(normal) * normal
		linear_velocity -= vel_projection
	linear_velocity *= pow(0.8, delta)
	#print("clip: " + str(depth))

func handle_impulse(impulse: Vector3) -> void:
	apply_impulse(impulse)
	$RedirectTimer.stop()


func _on_live_timer_timeout() -> void:
	queue_free()

func set_fake_mass(m: float) -> void:
	mass = m
	var r := 0.35*pow(mass, 0.5) # use m=r^2 because more fun than m=r^3
	$BlendMesh.scale = Vector3.ONE*r * 2.0/3.0
	$FieldCollider.radius = r
	$Shape.shape.radius = r

func start_throw(impulse: float, start_d: Vector3, targ_d: Vector3) -> void:
	#apply_impulse(start_d * impulse)
	target_direction = targ_d
	linear_velocity += start_d * impulse / mass
	$RedirectTimer.wait_time = 20.0 / linear_velocity.length() # 5 comes from ~length*2 of start targ position
