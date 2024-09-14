extends CharacterBody3D
class_name Balrog

signal throw_rock(rock: Rock)

@export var mouse_sensitivity := 0.0055
@export var rotation_speed := 4.0

@export var WALK_SPEED := 5.0
@export var RUN_SPEED := 10.0
var speed := WALK_SPEED


@export var GROUND_ACC := 20.0
@export var AIR_ACC := 2.0
@export var JUMP_SPEED := 5.0
@export var WING_MULT := 2.5

var field_colliders: Array[FieldCollider] = []
var field_bodies: Array[FieldedBody] = []
var total_gravity := Vector3.ZERO
var on_floor := 0.0
const DEFLOOR_RATE := 6.0
const GROUND_STICK := 0.4 # measured in seconds (multiplied by gravity)

var is_wings_tucked := true
var is_wings_raised := false

var displacement_velocity := Vector3.ZERO
var last_velocity := Vector3.ZERO

var righting_force := 0.0
var MAX_RIGHTING_FORCE := 1.0

const MAX_ROCK_IMPULSE := 50.0
const MIN_ROCK_IMPULSE := 5.0
const ROCK_CHARGE_TIME := 1.5 # 
var left_throw_charge := 0.0
var right_throw_charge := 0.0

var atmosphere := 1.0

var floor_clips := []


func _ready() -> void:
	field_colliders.append($FieldCollider)
	field_colliders.append($FieldCollider2)
	#
	$Wings/Wing_L.set_tucked(is_wings_tucked)
	$Wings/Wing_R.set_tucked(is_wings_tucked)

func _process(delta: float) -> void:
	pass
	

func _physics_process(delta: float) -> void:
	displacement_velocity = Vector3.ZERO
	calculate_fields(delta)
	handle_gravity(delta)
	handle_move_input(delta)
	handle_jumping(delta)
	handle_wing_forces(delta)
	handle_misc_input(delta)
	#
	#print(on_floor)
	#
	#print(str(velocity) + "  " + str(displacement_velocity))
	velocity = velocity + displacement_velocity
	last_velocity = velocity
	#print("velocity: " + str(velocity))
	#print("on_floor: " + str(on_floor))
	handle_flooriness(delta) # shoudl this be before move_and_slide
	#print("on_floor: " + str(on_floor))
	move_and_slide()
	if velocity.length() > 0.0:
		velocity *= (last_velocity - displacement_velocity).length()/last_velocity.length()
	#calculate_floor_clips()
	handle_floor_clips(delta)

func calculate_fields(delta: float) -> void:
	# calculate weights
	var weights := []
	var total_weight := 0.0
	for fb in field_bodies:
		var signed_distance: float = fb.signed_distance_func.call(global_position)
		var grav: float = fb.gravity_func.call(global_position).length()
		var w:= grav/pow(abs(signed_distance), 0.9)
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
	up_direction = up_d.normalized()
	# atmosphere
	atmosphere = 0.0
	for i in field_bodies.size():
		var fb := field_bodies[i]
		atmosphere += fb.atmosphere_func.call(global_position) * weights[i]


func handle_floor_clips(delta: float) -> void:
	floor_clips = []
	for fb in field_bodies:
		for collider in field_colliders:
			var signed_distance: float = fb.signed_distance_func.call(collider.global_position)
			if signed_distance < collider.radius:
				handle_a_floor_clip(delta, fb, collider)
		handle_camera_clip(fb, delta)

func handle_camera_clip(fb: FieldedBody, delta: float) -> void:
	var cam := $CamPivot/SpringArm/Q/Camera3D
	var cam_fc := $CamPivot/SpringArm/Q/Camera3D/FieldCollider
	var signed_distance: float = fb.signed_distance_func.call(cam_fc.global_position)
	if signed_distance > cam_fc.radius:
		var a: Vector3 = cam.position
		cam.position *= pow(0.4, delta)
		return
	var normal: Vector3 = fb.normal_func.call(global_position)
	var depth: float = cam_fc.radius - signed_distance
	#while signed_distance < cam_fc.radius # 0:
	#$SpringArm.spring_length
	cam.position += Vector3.FORWARD*(depth*0.5 + 0.01)
	#print("cam: " + str(cam.position))
	signed_distance = fb.signed_distance_func.call(cam_fc.global_position)
	
func handle_a_floor_clip(delta: float, fb: FieldedBody, fc: FieldCollider) -> void:
	#var signed_distance: float = fb.signed_distance_func.call(fc.global_position)
	#var normal: Vector3 = fb.normal_func.call(fc.global_position)
	#var depth = fc.radius - signed_distance
	#position += normal*depth
	#var vel_projection := velocity.dot(normal) * normal
	#velocity -= vel_projection
	fc.handle_fieldedbody_collision(fb)
	if fc == $FieldCollider:
		if on_floor == 0:
			land()
		on_floor = 1.0
	#print("floor clip depth: " + str(depth))
		

func handle_flooriness(delta: float) -> void:
	if on_floor != 0:
		stand_right_up(delta)
	else:
		flight_righting(delta)
	on_floor = move_toward(on_floor, 0, DEFLOOR_RATE * delta)

func handle_gravity(delta: float) -> void:
	velocity += total_gravity * delta


func handle_wing_forces(delta: float) -> void:
	var dir := input_dir()
	var mult := WING_MULT * atmosphere
	if dir.length() != 0.0:
		mult = .64 * WING_MULT * atmosphere
	velocity += basis * $Wings/Wing_R.get_wing_force(dir) * mult * delta
	displacement_velocity += basis * $Wings/Wing_R.get_wing_velocity(dir) * mult * delta


func handle_move_input(delta: float) -> void:
	var input_dir := input_dir()
	if input_dir == Vector3.ZERO:
		if on_floor != 0:
			floor_brake(delta)
		else:
			air_brake(delta)
		return
	#
	var temp: float = $CamPivot.rotation.y
	$CamPivot.rotation.y = lerp_angle($CamPivot.rotation.y, 0.0, rotation_speed * delta)
	var rotated_amount: float = $CamPivot.rotation.y - temp
	basis = basis.rotated(basis * Vector3.UP, -rotated_amount)
	#
	if on_floor != 0:
		#print(acceleration)
		velocity = lerp(velocity, basis * input_dir * speed, GROUND_ACC * delta)
	else:
		var brake_amount := air_brake(delta)
		velocity += basis * input_dir * AIR_ACC * delta
		velocity += basis * input_dir * brake_amount*0.5

func handle_jumping(delta: float) -> void:
	if is_on_floor():
		if on_floor == 0.0:
			land()
		on_floor = 1.0
	if Input.is_action_just_pressed("jump"):
		print("a " + str(on_floor))
		if on_floor != 0:
			jump()
		is_wings_raised = false
		$Wings/Wing_L.set_raised(is_wings_raised)
		$Wings/Wing_R.set_raised(is_wings_raised)
	elif Input.is_action_just_released("jump"):
		if on_floor != 0:
			$Wings/Wing_L.set_tucked(is_wings_tucked)
			$Wings/Wing_R.set_tucked(is_wings_tucked)
		else:	
			is_wings_raised = true
			$Wings/Wing_L.set_raised(is_wings_raised)
			$Wings/Wing_R.set_raised(is_wings_raised)
	elif Input.is_action_just_pressed("comedown"):
		velocity -= basis * Vector3.UP * JUMP_SPEED
		is_wings_raised = false
		$Wings/Wing_L.set_raised(is_wings_raised)
		$Wings/Wing_R.set_raised(is_wings_raised)


func jump() -> void:
	var vel_projection: Vector3 = velocity.dot(up_direction) * up_direction
	velocity -= vel_projection
	velocity += basis * Vector3.UP * JUMP_SPEED
	on_floor = 0.0

func land() -> void:
	print("landed")
	$Wings/Wing_L.set_tucked(is_wings_tucked)
	$Wings/Wing_R.set_tucked(is_wings_tucked)
	on_floor = 1.0
	

func floor_brake(delta: float) -> void:
	velocity *= pow(0.5, delta)
	velocity = lerp(velocity, Vector3.ZERO, GROUND_ACC * delta)

func air_brake(delta: float) -> float:
	var temp := velocity.length()
	var wing_speed: float = $Wings/Wing_R.get_wing_velocity(Vector3.ZERO).length()
	var extra_break := pow(abs(wing_speed), 0.3)*0.12
	extra_break = min(0.65, extra_break)
	#print("extra break: " + str(extra_break))
	velocity *= pow(0.85-extra_break, delta)
	return temp - velocity.length()
	#velocity = lerp(velocity, Vector3.ZERO, 1.0 * delta)


func handle_misc_input(delta: float) -> void:
	if Input.is_action_just_pressed("wing_tuck"):
		print("x")
		is_wings_tucked = ! is_wings_tucked
		$Wings/Wing_L.set_tucked(is_wings_tucked)
		$Wings/Wing_R.set_tucked(is_wings_tucked)
	if Input.is_action_pressed("left_use") and left_throw_charge < 1.0:
		left_throw_charge += delta/ROCK_CHARGE_TIME
	if Input.is_action_just_released("left_use"):
		throw_projectile(false)
	if Input.is_action_pressed("right_use") and right_throw_charge < 1.0:
		right_throw_charge += delta/ROCK_CHARGE_TIME
	if Input.is_action_just_released("right_use"):
		throw_projectile(true)
	if Input.is_action_just_pressed("run"):
		speed = RUN_SPEED
	if Input.is_action_just_released("run"):
		speed = WALK_SPEED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$CamPivot/SpringArm.rotation.x -= event.relative.y * mouse_sensitivity
		$CrossHair/Sprite.position.y = $CamPivot/SpringArm.rotation.x * 150.0
		#$CamPivot/SpringArm.rotation.x = 0
		$CamPivot/SpringArm.rotation_degrees.x = clamp($CamPivot/SpringArm.rotation_degrees.x, -90.0, 80.0)
		$CamPivot.rotation.y -= event.relative.x * mouse_sensitivity

# rotate about the feet
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
	var mult := 5 * (basis*Vector3.DOWN - down).length() * on_floor
	var a := transform.basis[0].move_toward(target_basis[0], mult*delta)
	var b := transform.basis[1].move_toward(target_basis[1], mult*delta)
	var c := transform.basis[2].move_toward(target_basis[2], mult*delta)
	basis = Basis(a, b, c).orthonormalized()

func flight_righting(delta: float) -> void:
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
	var mult := pow((basis*Vector3.DOWN - down).length() + 0.1, 0.5) * 1.0
	mult *= pow(total_gravity.length(), 0.5)*0.2
	#print(total_gravity.length())
	var a := transform.basis[0].move_toward(target_basis[0], mult*delta)
	var b := transform.basis[1].move_toward(target_basis[1], mult*delta)
	var c := transform.basis[2].move_toward(target_basis[2], mult*delta)
	basis = Basis(a, b, c).orthonormalized()

func input_dir() -> Vector3:
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_dir.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
	return input_dir.normalized()

func throw_projectile(is_right: bool) -> void:
	var rock := preload("res://scenes/rock.tscn").instantiate()
	rock.field_bodies = field_bodies
	var rock_start := Vector3(-2.5, 0.0, 0.0)
	if is_right:
		rock_start = Vector3(2.5, 0.0, 0.0)
	rock.position = global_position + global_basis * rock_start
	rock.linear_velocity = velocity
	var charge := left_throw_charge
	if is_right:
		charge = right_throw_charge
	var impulse := MIN_ROCK_IMPULSE + (MAX_ROCK_IMPULSE-MIN_ROCK_IMPULSE) * charge;
	var start_d := throw_start_direction(rock.position);
	print(start_d)
	var targ_d := throw_target_direction()
	print(targ_d)
	rock.start_throw(impulse, start_d, targ_d)
	if is_right:
		right_throw_charge = 0.0
	else:
		left_throw_charge = 0.0
	throw_rock.emit(rock)

func throw_target_direction() -> Vector3:
	var d: Vector3 = Vector3.FORWARD
	d = d.rotated(Vector3.RIGHT, +0.07 -$CamPivot/SpringArm.rotation.x*0.2)
	d = $CamPivot/SpringArm.global_basis * d
	return d
	
func throw_start_direction(start_pos: Vector3) -> Vector3:
	var start_targ: Vector3 = global_position + $CamPivot/SpringArm.global_basis * Vector3(0.0, 2.5, -3.0)
	#print(start_pos)
	#print(start_targ)
	return (start_targ - start_pos).normalized()
	
