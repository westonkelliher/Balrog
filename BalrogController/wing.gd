extends Node3D


class WingPosition:
	var base_stretch := 0.0 # to 1.0
	var fore_stretch := 0.0 # to 1.0
	var raised := 0.7 # 0.0 to 1.0
	var preened := 0.0 # 0.0 to 1.0
	var flair := 0.0 # 0.0 to 1.0
	
	func is_equal(wp: WingPosition) -> bool:
		return (base_stretch == wp.base_stretch and 
			fore_stretch == wp.fore_stretch and
			raised == wp.raised and
			preened == wp.preened and
			flair == wp.flair)
	func distance(wp: WingPosition) -> float:
		return ( abs(base_stretch - wp.base_stretch) +
			abs(fore_stretch - wp.fore_stretch) +
			abs(raised - wp.raised)*3.0 +
			abs(preened - wp.preened) +
			abs(flair - wp.flair) )

var wp_tuck: WingPosition = WingPosition.new()
var wp_spread: WingPosition = WingPosition.new()
var wp_tuck_raised: WingPosition = WingPosition.new()
var wp_tuck_lowered: WingPosition = WingPosition.new()

var saved_wp: WingPosition = WingPosition.new()
var target_wp: WingPosition = WingPosition.new()

var current_wp: WingPosition = WingPosition.new()

var flap_progress := 0.0 # to 1.0

const FLAP_ACC := 40.0 #*0.2
const FLAP_SPEED_MAX := 8.0 #*0.2
var flap_speed := 0.0

func _ready() -> void:
	wp_tuck.base_stretch = 0.2
	wp_tuck.fore_stretch = 0.4
	#
	wp_spread.base_stretch = 0.9
	wp_spread.fore_stretch = 0.9
	#
	wp_tuck_raised.base_stretch = 0.9
	wp_tuck_raised.fore_stretch = 0.0
	wp_tuck_raised.raised = 0.9
	wp_tuck_raised.flair = -0.4
	#
	wp_tuck_lowered.base_stretch = 0.7
	wp_tuck_lowered.fore_stretch = 1.1
	wp_tuck_lowered.raised = 0.1
	wp_tuck_lowered.preened = 0.9
	wp_tuck_lowered.flair = 1.2
	#
	current_wp = wp_tuck
	saved_wp = current_wp
	target_wp = current_wp


func _process(delta: float) -> void:
	if flap_progress < 1.0:
		flap_speed = move_toward(flap_speed, FLAP_SPEED_MAX, FLAP_ACC * delta)
		flap_speed *= pow(1.0 - flap_progress, delta*15.0*pow(flap_progress, 2))
		flap_progress = move_toward(flap_progress, 1.0, flap_speed * delta)
		current_wp = wing_interp(saved_wp, target_wp, flap_progress)
		apply_wing_position(current_wp)
	else:
		flap_speed = 0.0
	#elif flap_progress > 1.0:
		#var flap_dec := 4.0 * flap_speed * FLAP_ACC
		#flap_speed -= flap_dec * delta
		#flap_speed *= pow(0.00000000000001, delta)
		##if flap_speed < 0.0:
			##flap_speed *= pow(0.0001, delta)
		#flap_progress += flap_speed * delta
		#apply_wing_position(current_wp)
		
	

func apply_wing_position(wp: WingPosition) -> void:
	var FocalA := $Focal
	var FocalB := $Focal/Base/Focal
	var FocalC := $Focal/Base/Focal/Limb/Focal
	var FocalD := $Focal/Base/Focal/Limb/Focal/ForeLimb/Focal
	var FocalE := $Focal/Base/Focal/Limb/Focal/ForeLimb/Focal/HandLimb/Focal
	var BladePivotB := $Focal/Base/Focal/Limb/BladePivot
	var BladePivotC := $Focal/Base/Focal/Limb/Focal/ForeLimb/BladePivot
	var BladePivotD := $Focal/Base/Focal/Limb/Focal/ForeLimb/Focal/HandLimb/BladePivot
	var BladePivotE := $Focal/Base/Focal/Limb/Focal/ForeLimb/Focal/HandLimb/Focal/HandLimb/BladePivot
	# base_stretch
	FocalA.rotation.z = lerp(-PI, -PI*0.25, wp.base_stretch)
	FocalB.rotation.z = lerp(PI, -PI*0.2, wp.base_stretch)
	FocalC.rotation.z = lerp(-PI*.65, -PI*0.05, wp.base_stretch)
	BladePivotB.rotation.y = lerp(PI*0.6, PI*0.32, wp.base_stretch)
	# fore_stretch
	FocalD.rotation.z = lerp(-PI/3, 0.0, wp.fore_stretch)
	FocalE.rotation.z = lerp(-PI/3, 0.0, wp.fore_stretch)
	BladePivotC.rotation.y = lerp(PI*0.4, PI*0.33, wp.base_stretch)
	BladePivotD.rotation.y = lerp(PI*0.45, PI*0.33, wp.base_stretch)
	BladePivotE.rotation.y = lerp(PI*0.5, PI*0.33, wp.base_stretch)
	# raised
	FocalA.rotation.z += lerp(-PI/2, PI/4, wp.raised)
	# preened
	FocalC.rotation.z += lerp(0.0, PI/2, wp.preened)
	# flair
	BladePivotB.rotation.y += lerp(0.0, -PI*0.25, wp.flair)
	BladePivotC.rotation.y += lerp(0.0, -PI*0.25, wp.flair)
	BladePivotD.rotation.y += lerp(0.0, -PI*0.25, wp.flair)
	BladePivotE.rotation.y += lerp(0.0, -PI*0.25, wp.flair)


func set_tucked(tuck: bool) -> void:
	flap_progress = 0.0
	flap_speed = 0.0
	saved_wp = current_wp
	if tuck:
		target_wp = wp_tuck
	else:
		target_wp = wp_spread

func set_raised(raise: bool) -> void:
	flap_progress = 0.0
	flap_speed = 0.0
	saved_wp = current_wp
	if raise:
		target_wp = wp_tuck_raised
	else:
		target_wp = wp_tuck_lowered


func wing_interp(wp1: WingPosition, wp2: WingPosition, amount: float) -> WingPosition:
	var new := WingPosition.new()
	new.base_stretch = lerp(wp1.base_stretch, wp2.base_stretch, amount)
	new.fore_stretch = lerp(wp1.fore_stretch, wp2.fore_stretch, amount)
	new.raised = lerp(wp1.raised, wp2.raised, amount)
	new.preened = lerp(wp1.preened, wp2.preened, amount)
	new.flair = lerp(wp1.flair, wp2.flair, pow(amount, 0.5))
	return new

func get_wing_force(dir: Vector3) -> Vector3:
	var jim := (Vector3.UP*2 + dir).normalized()
	if target_wp == wp_tuck_lowered:
		return saved_wp.distance(target_wp) * flap_speed * jim * 1.4
	elif target_wp == wp_tuck_raised:
		return saved_wp.distance(target_wp) * flap_speed * jim * -0.3
	else:
		return Vector3.ZERO

func get_wing_velocity(dir: Vector3) -> Vector3:
	var jim := (Vector3.UP*2 + dir).normalized()
	if target_wp == wp_tuck_lowered:
		return saved_wp.distance(target_wp) * flap_speed * jim * 1.0
	elif target_wp == wp_tuck_raised:
		return saved_wp.distance(target_wp) * flap_speed * jim * -0.25
	else:
		return Vector3.ZERO
