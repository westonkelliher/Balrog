extends CharacterBody3D
class_name Balrog

@export var mouse_sensitivity := 0.0055
@export var rotation_speed := 12.0

@export var SPEED := 7.0
@export var acceleration := 2.0
@export var jump_speed := 5.0

var gravities: Array[GravObject] = []
var total_gravity := Vector3.ZERO
var jumping := false
var on_floor := 0.0
const DEFLOOR_RATE := 2.0

var is_wings_tucked := true
var is_wings_raised := false

var displacement_velocity := Vector3.ZERO
var last_velocity := Vector3.ZERO

var righting_force := 0.0
var MAX_RIGHTING_FORCE := 1.0

func _ready() -> void:
	$Wings/Wing_L.set_tucked(is_wings_tucked)
	$Wings/Wing_R.set_tucked(is_wings_tucked)

func _physics_process(delta: float) -> void:
	displacement_velocity = Vector3.ZERO
	handle_gravity(delta)
	handle_move_input(delta)
	handle_jumping(delta)
	handle_wing_forces(delta)
	handle_misc_input()
	#print(str(position) + " " + str(is_on_floor())  + " " + str(on_floor))
	#
	#print(basis)
	rotation_speed = 4
	#print(str(velocity) + "  " + str(displacement_velocity))
	velocity = velocity + displacement_velocity
	last_velocity = velocity
	move_and_slide()
	if velocity.length() > 0.0:
		velocity *= (last_velocity - displacement_velocity).length()/last_velocity.length()
	handle_flooriness(delta)
	handle_floorclip_hardcode()
	#if is_on_floor() and on_floor < 0.5:
		#print(on_floor)
		#velocity = 0.1 * last_velocity.bounce(total_gravity.normalized())

func handle_floorclip_hardcode() -> void:
	if position.x > 0:
		return
	if position.y > 0 and position.y < 2.5:
		if on_floor == 0.0:
			land()
		on_floor = 1.0
		position.y = 2.5
	if position.y < 0 and position.y > -2.5:
		if on_floor == 0.0:
			land()
		position.y = -2.5
		on_floor = 1.0

func handle_flooriness(delta: float) -> void:
	if is_on_floor():
		if on_floor == 0.0:
			land()
		on_floor = 1.0
	else:
		on_floor = move_toward(on_floor, 0, DEFLOOR_RATE * delta)
	if on_floor != 0:
		stand_right_up(delta, on_floor)

func handle_gravity(delta: float) -> void:
	total_gravity = Vector3.ZERO
	for g in gravities:
		total_gravity += g.gravity_func.call(global_position) * delta
	if total_gravity.length() != 0.0:
		up_direction = -total_gravity.normalized()
	else:
		up_direction = Vector3.UP
	if true or not is_on_floor():
		velocity += total_gravity


func handle_wing_forces(delta: float) -> void:
	var dir := input_dir()
	var mult := 1.3
	if dir.length() != 0.0:
		mult = 0.9
	velocity += basis * $Wings/Wing_R.get_wing_force(dir) * mult * delta
	
	displacement_velocity += basis * $Wings/Wing_R.get_wing_velocity(dir) * mult * delta
	# righting
	var arf := pow((velocity + displacement_velocity*1000.0).length(), 0.2)*0.015
	righting_force = move_toward(righting_force, MAX_RIGHTING_FORCE, arf * delta)
	righting_force *= pow((basis*Vector3.DOWN - total_gravity.normalized()).length()+0.7, delta)
	stand_right_up(delta, righting_force)
	#print(displacement_velocity)

func handle_move_input(delta: float) -> void:
	var input_dir := input_dir()
	if input_dir == Vector3.ZERO:
		if is_on_floor():
			floor_brake(delta)
		else:
			air_brake(delta)
		return
	#
	var temp: float = $SpringArm.rotation.y
	$SpringArm.rotation.y = lerp_angle($SpringArm.rotation.y, 0.0, rotation_speed * delta)
	var rotated_amount: float = $SpringArm.rotation.y - temp
	basis = basis.rotated(basis * Vector3.UP, -rotated_amount)
	#
	if is_on_floor():
		velocity = lerp(velocity, basis * input_dir * SPEED, acceleration * delta)
	else:
		var brake_amount := air_brake(delta)
		velocity += basis * input_dir * acceleration * delta
		velocity += basis * input_dir * brake_amount*0.5

func handle_jumping(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		if on_floor > 0.5:
			jump()
		is_wings_raised = false
		$Wings/Wing_L.set_raised(is_wings_raised)
		$Wings/Wing_R.set_raised(is_wings_raised)
	elif Input.is_action_just_released("jump"):
		if is_on_floor():
			$Wings/Wing_L.set_tucked(is_wings_tucked)
			$Wings/Wing_R.set_tucked(is_wings_tucked)
		else:	
			is_wings_raised = true
			$Wings/Wing_L.set_raised(is_wings_raised)
			$Wings/Wing_R.set_raised(is_wings_raised)
	elif Input.is_action_just_pressed("comedown"):
		velocity -= basis * Vector3.UP * jump_speed
		is_wings_raised = false
		$Wings/Wing_L.set_raised(is_wings_raised)
		$Wings/Wing_R.set_raised(is_wings_raised)


func jump() -> void:
	velocity += basis * Vector3.UP * jump_speed
	on_floor = 0.0

func land() -> void:
	$Wings/Wing_L.set_tucked(is_wings_tucked)
	$Wings/Wing_R.set_tucked(is_wings_tucked)
	on_floor = 1.0
	

func floor_brake(delta: float) -> void:
	velocity *= pow(0.5, delta)
	velocity = lerp(velocity, Vector3.ZERO, acceleration * delta)

func air_brake(delta: float) -> float:
	var temp := velocity.length()
	var wing_speed: float = $Wings/Wing_R.get_wing_velocity(Vector3.ZERO).length()
	var extra_break := pow(abs(wing_speed), 0.3)*0.12
	extra_break = min(0.65, extra_break)
	print("extra break: " + str(extra_break))
	velocity *= pow(0.8-extra_break, delta)
	return temp - velocity.length()
	#velocity = lerp(velocity, Vector3.ZERO, 1.0 * delta)


func handle_misc_input() -> void:
	if Input.is_action_just_pressed("wing_tuck"):
		print("x")
		is_wings_tucked = ! is_wings_tucked
		$Wings/Wing_L.set_tucked(is_wings_tucked)
		$Wings/Wing_R.set_tucked(is_wings_tucked)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$SpringArm.rotation.x -= event.relative.y * mouse_sensitivity
		$SpringArm.rotation_degrees.x = clamp($SpringArm.rotation_degrees.x, -90.0, 30.0)
		$SpringArm.rotation.y -= event.relative.x * mouse_sensitivity

# rotate about the feet
func stand_right_up(delta: float, flooriness: float) -> void:
	# basis
	var forward: Vector3 = transform.basis[2]
	var down: Vector3 = total_gravity.normalized()
	var right: Vector3 = forward.cross(down).normalized()
	if down.dot(basis * Vector3.UP) > 0:
		basis = basis.rotated(Vector3(1, 1, 1).normalized(), 0.01)
	# Recalculate forward to ensure it's orthogonal
	forward = down.cross(right).normalized()
	# Create rotation basis
	var target_basis: Basis = Basis(right, -down, forward).orthonormalized()
	# rotate the player to the target rotation
	var mult := 5 * (basis*Vector3.DOWN - down).length() * flooriness
	var a := transform.basis[0].move_toward(target_basis[0], mult*delta)
	var b := transform.basis[1].move_toward(target_basis[1], mult*delta)
	var c := transform.basis[2].move_toward(target_basis[2], mult*delta)
	basis = Basis(a, b, c).orthonormalized()
	#velocity += basis * Vector3.UP * 0.01 * delta
		

func input_dir() -> Vector3:
	var input_dir := Vector3.ZERO
	input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_dir.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
	return input_dir.normalized()

func throw_projectile() -> void:
	pass
	
