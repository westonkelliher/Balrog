extends CharacterBody3D
class_name Balrog

signal throw_rock(rock: Rock)

@export var mouse_sensitivity := 0.0055
@export var rotation_speed := 4.0

@export var WALK_SPEED := 5.0
@export var RUN_SPEED := 10.0
var speed := WALK_SPEED


@export var GROUND_ACC := 30.0
@export var AIR_ACC := 2.0
@export var JUMP_SPEED := 5.0
@export var WING_MULT := 2.5

@onready var CAMERA := $CamPivot/SpringArm/Q/Camera3D

var field_colliders: Array[FieldCollider] = []
var field_bodies: Array[FieldBody] = []
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

const MAX_ROCK_IMPULSE := 100.0 # this is the impulse at mass = 1 ...
const MIN_ROCK_IMPULSE := 5.0  # but will 0.35be multiplied by sqrt(mass)
const MAX_ROCK_MASS := 30.0
const MIN_ROCK_MASS := 0.5
const ROCK_CHARGE_TIME := 1.5 # 
const ROCK_SIZE_INCR := 0.1 # 
var left_throw_charge := 0.0
var right_throw_charge := 0.0
var left_rock_size := 0.2  # size is a lerp for mass
var right_rock_size:= 0.2

var is_right_selector := false

var atmosphere := 1.0

var floor_clips := []


func _ready() -> void:
	field_colliders.append($FieldCollider)
	field_colliders.append($FieldCollider2)
	#
	$Wings/Wing_L.set_tucked(is_wings_tucked)
	$Wings/Wing_R.set_tucked(is_wings_tucked)
	#
	$UI/Centroid/SizeBarL.set_progress(left_rock_size)
	$UI/Centroid/SizeBarR.set_progress(right_rock_size)
	if is_right_selector:
		$UI/Centroid/SizeBarL.modulate = Color(1.0, 1.0, 1.0, 0.5)
		$UI/Centroid/SizeBarR.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		$UI/Centroid/SizeBarL.modulate = Color(1.0, 1.0, 1.0, 1.0)
		$UI/Centroid/SizeBarR.modulate = Color(1.0, 1.0, 1.0, 0.5)

func _process(delta: float) -> void:
	if $UI/ChargeBarL.visible:
		var screen_size: Vector2 = get_viewport().size
		var world_point := global_position + global_basis * Vector3(-3.5, 0.0, 0.0)
		var screen_point: Vector2 = CAMERA.unproject_position(world_point) + Vector2(250.0, -150.0)
		screen_point.y = (screen_point.y + screen_size.y*1.6)/3.0
		screen_point.y = clamp(screen_point.y,  screen_size.y*0.3, screen_size.y*0.7)
		screen_point.x = (screen_point.x + screen_size.x*0.3)/2.0
		screen_point.x = clamp(screen_point.x, screen_size.x*0.3, screen_size.x*0.7)
		$UI/ChargeBarL.global_position = screen_point
	if $UI/ChargeBarR.visible:
		var screen_size: Vector2 = get_viewport().size
		var world_point := global_position + global_basis * Vector3(3.5, 0.0, 0.0)
		var screen_point: Vector2 = CAMERA.unproject_position(world_point) + Vector2(-250.0, -150.0)
		screen_point.y = (screen_point.y + screen_size.y*1.6)/3.0
		screen_point.y = clamp(screen_point.y,  screen_size.y*0.3, screen_size.y*0.7)
		screen_point.x = (screen_point.x + screen_size.x*0.7)/2.0
		screen_point.x = clamp(screen_point.x, screen_size.x*0.3, screen_size.x*0.7)
		$UI/ChargeBarR.global_position = screen_point

func _physics_process(delta: float) -> void:
	displacement_velocity = Vector3.ZERO
	calculate_fields(delta)
	handle_gravity(delta)
	handle_move_input(delta)
	handle_jumping(delta)
	handle_wing_forces(delta)
	handle_misc_input(delta)
	#
	velocity = velocity + displacement_velocity
	last_velocity = velocity
	handle_flooriness(delta) # shoudl this be before move_and_slide
	move_and_slide()
	if velocity.length() > 0.0:
		velocity *= (last_velocity - displacement_velocity).length()/last_velocity.length()
	handle_floor_clips(delta)

func calculate_fields(delta: float) -> void:
	# calculate weights
	var weights := []
	var total_weight := 0.0
	for fb in field_bodies:
		var signed_distance: float = fb.field_sdf(global_position)
		var grav: float = fb.field_gravity(global_position).length()
		var w:= grav/pow(abs(signed_distance), 0.9)
		total_weight += w
		weights.append(w)
	for i in weights.size():
		weights[i] /= total_weight
	# gravity
	total_gravity = Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		total_gravity += fb.field_gravity(global_position) * weights[i]
	# up direction
	var up_d := Vector3.ZERO
	for i in field_bodies.size():
		var fb := field_bodies[i]
		up_d += fb.field_up(global_position) * weights[i]
	if up_d.length() > 0.0001:
		up_direction = up_d.normalized()
	# atmosphere
	atmosphere = 0.0
	for i in field_bodies.size():
		var fb := field_bodies[i]
		atmosphere += fb.field_atmosphere(global_position) * weights[i]


func handle_floor_clips(delta: float) -> void:
	floor_clips = []
	for fb in field_bodies:
		for collider in field_colliders:
			var signed_distance: float = fb.field_sdf(collider.global_position)
			if signed_distance < collider.radius:
				handle_a_floor_clip(delta, fb, collider)
		handle_camera_clip(fb, delta)

func handle_camera_clip(fb: FieldBody, delta: float) -> void:
	var cam_fc := $CamPivot/SpringArm/Q/Camera3D/FieldCollider
	var signed_distance: float = fb.field_sdf(cam_fc.global_position)
	if signed_distance > cam_fc.radius:
		var a: Vector3 = CAMERA.position
		CAMERA.position *= pow(0.4, delta)
		return
	var normal: Vector3 = fb.field_up(global_position)
	var depth: float = cam_fc.radius - signed_distance
	CAMERA.position += Vector3.FORWARD*(depth*0.5 + 0.01)
	signed_distance = fb.field_sdf(cam_fc.global_position)
	
func handle_a_floor_clip(delta: float, fb: FieldBody, fc: FieldCollider) -> void:
	fc.handle_fieldedbody_collision(fb)
	if fc == $FieldCollider:
		if on_floor == 0:
			land()
		on_floor = 1.0
		

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
	turn_toward_camera(delta)
	#
	if on_floor != 0:
		print()
		print(velocity)
		velocity = velocity.move_toward(basis * input_dir * speed, GROUND_ACC * delta)
		print(velocity)
		print(str(basis * input_dir * speed) + " " + str(GROUND_ACC) + " " + str(delta))
	else:
		print("abc")
		var brake_amount := air_brake(delta)
		velocity += basis * input_dir * AIR_ACC * delta
		velocity += basis * input_dir * brake_amount*0.5

func handle_jumping(delta: float) -> void:
	if is_on_floor():
		if on_floor == 0.0:
			land()
		on_floor = 1.0
	if Input.is_action_just_pressed("jump"):
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
	$Wings/Wing_L.set_tucked(is_wings_tucked)
	$Wings/Wing_R.set_tucked(is_wings_tucked)
	on_floor = 1.0


func turn_toward_camera(delta: float) -> void:
	var temp: float = $CamPivot.rotation.y
	$CamPivot.rotation.y = lerp_angle($CamPivot.rotation.y, 0.0, rotation_speed * delta)
	var rotated_amount: float = $CamPivot.rotation.y - temp
	basis = basis.rotated(basis * Vector3.UP, -rotated_amount)


func floor_brake(delta: float) -> void:
	velocity *= pow(0.5, delta)
	velocity = velocity.move_toward(Vector3.ZERO, GROUND_ACC * delta)

func air_brake(delta: float) -> float:
	var temp := velocity.length()
	var wing_speed: float = $Wings/Wing_R.get_wing_velocity(Vector3.ZERO).length()
	var extra_break := pow(abs(wing_speed), 0.3)*0.12
	extra_break = min(0.65, extra_break)
	velocity *= pow(0.85-extra_break, delta)
	return temp - velocity.length()
	#velocity = lerp(velocity, Vector3.ZERO, 1.0 * delta)


func handle_misc_input(delta: float) -> void:
	if Input.is_action_just_pressed("wing_tuck"):
		is_wings_tucked = ! is_wings_tucked
		$Wings/Wing_L.set_tucked(is_wings_tucked)
		$Wings/Wing_R.set_tucked(is_wings_tucked)
	#
	handle_selector_input(delta)
	# left and right throws
	var using := handle_use(delta)
	#
	if using:
		turn_toward_camera(delta)
		speed = WALK_SPEED
	elif Input.is_action_pressed("run"):
		speed = RUN_SPEED
	if Input.is_action_just_released("run"):
		speed = WALK_SPEED


func handle_selector_input(delta: float) -> void:
	if Input.is_action_just_pressed("switch_selector"):
		if is_right_selector:
			is_right_selector = false
			$UI/Centroid/SizeBarL.modulate = Color(1.0, 1.0, 1.0, 1.0)
			$UI/Centroid/SizeBarR.modulate = Color(1.0, 1.0, 1.0, 0.5)
		else:
			is_right_selector = true
			$UI/Centroid/SizeBarL.modulate = Color(1.0, 1.0, 1.0, 0.5)
			$UI/Centroid/SizeBarR.modulate = Color(1.0, 1.0, 1.0, 1.0)
	# rock size
	if Input.is_action_just_released("sizeup"):
		if is_right_selector:
			right_rock_size = move_toward(right_rock_size, 1.0, ROCK_SIZE_INCR)
			$UI/Centroid/SizeBarR.set_progress(right_rock_size)
		else:
			left_rock_size = move_toward(left_rock_size, 1.0, ROCK_SIZE_INCR)
			$UI/Centroid/SizeBarL.set_progress(left_rock_size)
	if Input.is_action_just_released("sizedown"):
		if is_right_selector:
			right_rock_size = move_toward(right_rock_size, 0.0, ROCK_SIZE_INCR)
			$UI/Centroid/SizeBarR.set_progress(right_rock_size)
		else:
			left_rock_size = move_toward(left_rock_size, 0.0, ROCK_SIZE_INCR)
			$UI/Centroid/SizeBarL.set_progress(left_rock_size)
	

# returns true if currently using something
func handle_use(delta: float) -> bool:
	if on_floor == 0.0:
		$UI/ChargeBarL.visible = false
		$UI/ChargeBarR.visible = false
		left_throw_charge = 0.0
		$UI/ChargeBarL.set_progress(0.0)
		right_throw_charge = 0.0
		$UI/ChargeBarR.set_progress(0.0)
		return false
	#
	var using := false
	if Input.is_action_just_pressed("left_use"):
		$Wings/Wing_L.start_charge()
	if Input.is_action_just_pressed("right_use"):
		$Wings/Wing_R.start_charge()
	if Input.is_action_pressed("left_use"):
		if left_throw_charge < 1.0:
			left_throw_charge += delta/ROCK_CHARGE_TIME
			$UI/ChargeBarL.set_progress(left_throw_charge)
		$Wings/Wing_L.set_charge(left_throw_charge)
		using = true
		$UI/ChargeBarL.visible = true
	elif Input.is_action_just_released("left_use"):
		throw_projectile(false)
		$Wings/Wing_L.throw()
		$UI/ChargeBarL.visible = false
	if Input.is_action_pressed("right_use"):
		if right_throw_charge < 1.0:
			right_throw_charge += delta/ROCK_CHARGE_TIME
			$UI/ChargeBarR.set_progress(right_throw_charge)
		$Wings/Wing_R.set_charge(right_throw_charge)
		using = true
		$UI/ChargeBarR.visible = true
	elif Input.is_action_just_released("right_use"):
		throw_projectile(true)
		$Wings/Wing_R.throw()
		$UI/ChargeBarR.visible = false
	return using

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$CamPivot/SpringArm.rotation.x -= event.relative.y * mouse_sensitivity
		$UI/CrossHair.position.y = $CamPivot/SpringArm.rotation.x * 150.0
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
	var rock_start := Vector3(-2.5, -1.0, 0.0)
	if is_right:
		rock_start = Vector3(2.5,-1.0, 0.0)
	rock.position = global_position + global_basis * rock_start
	rock.linear_velocity = velocity
	if is_right:
		rock.set_fake_mass(MIN_ROCK_MASS + pow(right_rock_size, 2)*MAX_ROCK_MASS)
	else:
		rock.set_fake_mass(MIN_ROCK_MASS + pow(left_rock_size, 2)*MAX_ROCK_MASS)
	var charge := left_throw_charge
	if is_right:
		charge = right_throw_charge
	var impulse := MIN_ROCK_IMPULSE + (MAX_ROCK_IMPULSE-MIN_ROCK_IMPULSE) * charge;
	impulse = impulse * sqrt(rock.mass)
	# TODO: drain energy proportional to impulse (plus initial cost based on mass)
	var start_d := throw_start_direction(rock.position);
	var targ_d := throw_target_direction()
	rock.start_throw(impulse, start_d, targ_d)
	if is_right:
		right_throw_charge = 0.0
		$UI/ChargeBarR.set_progress(right_throw_charge)
	else:
		left_throw_charge = 0.0
		$UI/ChargeBarL.set_progress(left_throw_charge)
	throw_rock.emit(rock)

func throw_target_direction() -> Vector3:
	var d: Vector3 = Vector3.FORWARD
	d = d.rotated(Vector3.RIGHT, +0.07 -$CamPivot/SpringArm.rotation.x*0.2)
	d = $CamPivot/SpringArm.global_basis * d
	return d
	
func throw_start_direction(start_pos: Vector3) -> Vector3:
	var start_targ: Vector3 = global_position + $CamPivot/SpringArm.global_basis * Vector3(0.0, 2.5, -3.0)
	return (start_targ - start_pos).normalized()
	
