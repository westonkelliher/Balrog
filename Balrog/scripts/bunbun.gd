extends CharacterBody3D
class_name Bunbun

var field_colliders: Array[FieldCollider] = []
var field_bodies: Array[FieldBody] = []
var total_gravity := Vector3.ZERO

var grav_mult := 1.5

var target_direction := Vector3.ZERO

var mass := 3.0 # kilograms

var GROUND_DEC := 10.0
var GROUND_DAMP := 0.75 # 1.0 is 100% damp
var AIR_DAMP := 0.1 

var MEANDER_LEVEL := 3.5

var elasticity := 0.8 # how much kinetic energy is retained after colliding
var billiarding := 0.8 # how much of a collision impulse is along the normal vs 
					   # a straight velocity transfer
var torquing := 0.0 # not used yet

var JUMP_SPEED_CALM := 4.0
var JUMP_SPEED_PANIK := 8.0

#var floor_distance := 
var on_floor := false

func _ready() -> void:
	field_colliders.append($FieldCollider)
	#var temp := global_position
	#global_position = Vector3(100000.0, 100000.0, 100000.0)
	#global_position = temp
	#field_bodies = get_parent().get_node("Balrog").field_bodies

func _physics_process(delta: float) -> void:
	calculate_fields(delta)
	handle_floor_clips(delta)
	damp_movement(delta)
	meander(delta)
	velocity += total_gravity * delta
	move_and_slide()
	handle_collisions()
	#move_and_collide(linear_velocity)


func meander(delta: float) -> void:
	if not on_floor:
		return
	rotate(basis*Vector3.UP, (randf()-0.5) * MEANDER_LEVEL * delta)

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
	total_gravity *= grav_mult
	# up direction
	var up_d := Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		up_d += fb.field_up(global_position) * weights[i]
	if up_d.length()== 0.0:
		up_direction = Vector3.UP
	else:
		up_direction = up_d.normalized()


func handle_floor_clips(delta: float) -> void:
	on_floor = is_on_floor() # doesn't account for SDF floors
	for fb in field_bodies:
		for collider in field_colliders:
			var signed_distance: float = fb.field_sdf(collider.global_position)
			if signed_distance < collider.radius:
				handle_a_floor_clip(delta, fb, collider)
				on_floor = true
	# TODO: vv move to different function vv
	if on_floor and $JumpTimer.is_stopped():
		$JumpTimer.start()

func handle_a_floor_clip(delta: float, fb: FieldBody, fc: FieldCollider) -> void:
	stand_right_up(delta)
	#
	var signed_distance: float = fb.field_sdf(fc.global_position)
	var normal: Vector3 = fb.field_up(fc.global_position)
	var depth := fc.radius - signed_distance
	position += normal*depth
	var dot := velocity.dot(normal)
	if dot < 0.0:
		var vel_projection := velocity.dot(normal) * normal
		velocity -= vel_projection
	velocity *= pow(0.8, delta)

func damp_movement(delta: float) -> void:
	if on_floor:
		velocity *= pow(1.0 - GROUND_DAMP, delta)
		velocity = velocity.move_toward(Vector3.ZERO, GROUND_DEC * delta)
	else:
		velocity *= pow(1.0 - AIR_DAMP, delta)
		


func handle_collisions() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var other := c.get_collider()
		var relative_v := Vector3.ZERO # the collider's velocity relative to this
		if other is RigidBody3D:
			relative_v = other.linear_velocity - velocity
		else:
			relative_v = other.velocity - velocity
		var normal := c.get_normal()
		var vnorm := relative_v.normalized()
		normal = (normal*billiarding + vnorm*(1-billiarding)).normalized()
		var v_along_normal: = relative_v.dot(normal)
		var impulse_scalar := -v_along_normal
		impulse_scalar /= (1/mass) + (1/other.mass)
		var impulse := impulse_scalar * normal
		var temp_v := velocity
		self.handle_impulse(-impulse)
		if other is RigidBody3D:
			other.handle_impulse(impulse)
		else:
			other.handle_impulse(impulse)
		# calculate position of collision
		# calculate relative velocity
		# TODO: calculate relative surface velocity

func handle_impulse(impulse: Vector3) -> void:
	var knock := (1/mass) * impulse
	velocity += knock


func stand_right_up(delta: float) -> void:
	# basis
	var forward: Vector3 = transform.basis[2]
	var down: Vector3 = -up_direction
	var right: Vector3 = forward.cross(down).normalized()
	if down.dot(basis * Vector3.UP) > 0:
		basis = basis.rotated(Vector3(1, 1, 1).normalized(), 0.01)
	# Recalculate forward to ensure it's orthogonal
	forward = down.cross(right).normalized()
	# Create rotation basis
	var target_basis: Basis = Basis(right, -down, forward).orthonormalized()
	# rotate the player to the target rotation
	var mult := 5 * (basis*Vector3.DOWN - down).length()
	var a := transform.basis[0].move_toward(target_basis[0], mult*delta)
	var b := transform.basis[1].move_toward(target_basis[1], mult*delta)
	var c := transform.basis[2].move_toward(target_basis[2], mult*delta)
	basis = Basis(a, b, c).orthonormalized()


func _on_jump_timer_timeout() -> void:
	jump(60*(PI/180), JUMP_SPEED_CALM)

func jump(angle: float, speed: float) -> void:
	# damp a lot
	velocity *= 0.5
	var jump_vec := global_basis * Vector3.FORWARD.rotated(Vector3.RIGHT, angle)
	velocity += jump_vec*speed
