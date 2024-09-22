extends CharacterBody3D
class_name Puck

var field_colliders: Array[FieldCollider] = []
var field_bodies: Array[FieldBody] = []


var target_direction := Vector3.ZERO

var up_d := Vector3.DOWN

var mass := 2.0

func _ready() -> void:
	$Shape.shape = $Shape.shape.duplicate()
	field_colliders.append($FieldCollider)

func _physics_process(delta: float) -> void:
	calculate_fields(delta)
	reorient(delta)
	move_and_slide()
	handle_floor_clips(delta)


func reorient(delta: float) -> void:
	if velocity.length() < 0.001:
		velocity = global_basis * Vector3.FORWARD * -1.0
	var old_forward := velocity.normalized()
	var right := old_forward.cross(up_d)
	var new_forward := up_d.cross(right)
	if $StraightTimer.time_left > 0.0:
		var mult: float = $StraightTimer.time_left / $StraightTimer.wait_time
		mult = pow(mult, 0.3)
		print(mult)
		new_forward = old_forward*mult + new_forward*(1.0-mult)
	var speed := velocity.length()
	velocity = new_forward * speed
	basis = Basis(right, up_d, new_forward)
	
	

# calculate the force required to change velocities in a single frame
func required_force(old_v: Vector3, new_v: Vector3, delta: float) -> Vector3:
	return (new_v - old_v) * 1.0/delta # inconsistent delta could f**k this
	

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
	# up direction
	up_d = Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		up_d += fb.field_up(global_position) * weights[i]
	if up_d.length() < 0.0001:
		up_d = Vector3.DOWN
	else:
		up_d = up_d.normalized()


func handle_floor_clips(delta: float) -> void:
	for fb in field_bodies:
		for collider in field_colliders:
			var signed_distance: float = fb.field_sdf(collider.global_position)
			if signed_distance < collider.radius:
				handle_a_floor_clip(delta, fb, collider)

func handle_a_floor_clip(delta: float, fb: FieldBody, fc: FieldCollider) -> void:
	print("puck clip")
	var signed_distance: float = fb.field_sdf(fc.global_position)
	var normal: Vector3 = fb.field_up(fc.global_position)
	var depth := fc.radius - signed_distance
	position += normal*depth
	var dot := velocity.dot(normal)
	if dot < 0.0:
		var vel_projection := velocity.dot(normal) * normal
		velocity -= vel_projection
	velocity *= pow(0.8, delta)

func handle_impulse(impulse: Vector3) -> void:
	var knock := (1/mass) * impulse
	velocity += knock


func _on_live_timer_timeout() -> void:
	queue_free()

func set_fake_mass(m: float) -> void:
	mass = m
	var r := 0.35*pow(mass, 0.5) # use m=r^2 because more fun than m=r^3
	$BlendMesh.scale = Vector3.ONE*r * 2.0/3.0
	$FieldCollider.radius = r
	$Shape.shape.radius = r
