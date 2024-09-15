extends Node3D


class WingPosition:
	var base_stretch := 0.2 # 0.0 to 1.0
	var fore_stretch := 0.4 # 0.0 to 1.0
	var back_reach := 0.1 # 0.0 to 1.0
	var foreward_reach := 0.1 # 0.0 to 1.0
	var raised := 0.7 # 0.0 to 1.0
	var preened := 0.0 # 0.0 to 1.0
	var flair := 0.0 # 0.0 to 3.0+
	var arm_raise := 0.2 # 0.0 to 1.0
	var arm_outward := 0.2 # 0.0 to 1.0
	
	func distance(wp: WingPosition) -> float:
		return ( abs(base_stretch - wp.base_stretch) +
			abs(fore_stretch - wp.fore_stretch) +
			abs(raised - wp.raised)*3.0 +
			abs(preened - wp.preened) +
			abs(flair - wp.flair) +
			abs(back_reach - wp.back_reach) +
			abs(foreward_reach - wp.foreward_reach) +
			abs(arm_raise - wp.arm_raise) +
			abs(arm_outward - wp.arm_outward) )
	
	func is_equal(wp: WingPosition) -> bool:
		return distance(wp) < 0.00001
	
	func print() -> void:
		print( str(base_stretch)
		+ " " + str(fore_stretch)
		+ " " + str(back_reach)
		+ " " + str(foreward_reach)
		+ " " + str(raised)
		+ " " + str(preened)
		+ " " + str(flair)
		+ " " + str(arm_raise)
		+ " " + str(arm_outward)
		)

var wp_tuck: WingPosition = WingPosition.new()
var wp_spread: WingPosition = WingPosition.new()
var wp_tuck_raised: WingPosition = WingPosition.new()
var wp_tuck_lowered: WingPosition = WingPosition.new()
#
var wp_charge_full: WingPosition = WingPosition.new()
var wp_charge_release: WingPosition = WingPosition.new()

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
	wp_spread.arm_outward = 1.0
	#
	wp_tuck_raised.base_stretch = 0.9
	wp_tuck_raised.fore_stretch = 0.0
	wp_tuck_raised.raised = 0.9
	wp_tuck_raised.flair = -0.4
	#wp_tuck_raised.arm_raise = 0.1
	wp_tuck_raised.arm_outward = 0.9
	#
	wp_tuck_lowered.base_stretch = 0.7
	wp_tuck_lowered.fore_stretch = 1.1
	wp_tuck_lowered.raised = 0.1
	wp_tuck_lowered.preened = 0.9
	wp_tuck_lowered.flair = 1.2
	wp_tuck_lowered.arm_outward = 1.0
	#
	wp_charge_full.base_stretch = 0.3
	wp_charge_full.fore_stretch = 0.9
	wp_charge_full.back_reach = 1.0
	wp_charge_full.flair = 2.5
	wp_charge_full.arm_raise = 0.4
	#
	wp_charge_release.base_stretch = 0.9
	wp_charge_release.fore_stretch = 0.1
	wp_charge_release.back_reach = -0.3
	wp_charge_release.foreward_reach = 0.8
	wp_charge_release.flair = 0.1
	wp_charge_release.arm_raise = 0.7
	#
	current_wp = wp_tuck
	saved_wp = current_wp
	target_wp = current_wp


func _process(delta: float) -> void:
	if flap_progress < 1.0:
		print("A")
		flap_speed = move_toward(flap_speed, FLAP_SPEED_MAX, FLAP_ACC * delta)
		flap_speed *= pow(1.0 - flap_progress, delta*15.0*pow(flap_progress, 2))
		flap_progress = move_toward(flap_progress, 1.0, flap_speed * delta)
		current_wp = wing_interp(saved_wp, target_wp, flap_progress)
		apply_wing_position(current_wp)
	else:
		flap_speed = 0.0
		print()
		current_wp.print()
		wp_charge_release.print()
		print(current_wp.distance(wp_charge_release))
		print( current_wp.is_equal(wp_charge_release))
		if current_wp.is_equal(wp_charge_release):
			set_target(wp_tuck)
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
	var ArmFocalA := $Focal/Base/Focal/ArmFocal
	var ArmFocalB := $Focal/Base/Focal/ArmFocal/ArmLimb/Focal
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
	# backreach
	FocalA.rotation.x = lerp(0.0, -20*(PI/180), wp.back_reach)
	FocalA.rotation.y = lerp(0.0, -40*(PI/180), wp.back_reach)
	print(wp.back_reach)
	# foreward_reach
	FocalB.rotation.x = lerp(0.0, -40*(PI/180), wp.foreward_reach)
	#FocalC.rotation.y = lerp(0.0, 90*(PI/180), wp.foreward_reach)
	#FocalC.rotation.x = lerp(0.0, -40*(PI/180), wp.foreward_reach)
	# arms 
	ArmFocalA.rotation.x = lerp(-150*(PI/180), 0.0, wp.arm_raise)
	ArmFocalA.rotation.y = lerp(-40*(PI/180), 30*(PI/180), wp.arm_raise)
	ArmFocalA.rotation.z = lerp(0.0, 30*(PI/180), wp.arm_raise)
	# arm out
	ArmFocalA.rotation.x += lerp(0.0, 120*(PI/180), wp.arm_outward)
	ArmFocalA.rotation.y += lerp(0.0, 10*(PI/180), wp.arm_outward)
	ArmFocalA.rotation.z += lerp(0.0, -30*(PI/180), wp.arm_outward)
	#
	ArmFocalB.rotation.x = lerp(0.0, -50*(PI/180), wp.arm_outward)
	ArmFocalB.rotation.y  = lerp(0.0, 20*(PI/180), wp.arm_outward)
	
	


func set_target(targ: WingPosition, reset_start: bool = true) -> void:
	targ.print()
	if reset_start:
		flap_progress = 0.0
		flap_speed = 0.0
		saved_wp = current_wp
	target_wp = targ
		


func start_charge() -> void:
	print("ASASAS")
	set_target(wp_tuck)

# called many times in sequence
func set_charge(charge: float) -> void:
	var targ := wing_interp(wp_tuck, wp_charge_full, charge)
	print("targ " + str(targ.back_reach))
	flap_progress = sqrt(charge)
	set_target(targ, false)

func throw() -> void:
	set_target(wp_charge_release)
	flap_speed = FLAP_SPEED_MAX

func set_tucked(tuck: bool) -> void:
	if tuck:
		set_target(wp_tuck)
	else:
		set_target(wp_spread)

func set_raised(raise: bool) -> void:
	if raise:
		set_target(wp_tuck_raised)
	else:
		set_target(wp_tuck_lowered)


func wing_interp(wp1: WingPosition, wp2: WingPosition, amount: float) -> WingPosition:
	var new := WingPosition.new()
	new.base_stretch = lerp(wp1.base_stretch, wp2.base_stretch, amount)
	new.fore_stretch = lerp(wp1.fore_stretch, wp2.fore_stretch, amount)
	new.raised = lerp(wp1.raised, wp2.raised, amount)
	new.preened = lerp(wp1.preened, wp2.preened, amount)
	new.flair = lerp(wp1.flair, wp2.flair, pow(amount, 0.5))
	new.back_reach = lerp(wp1.back_reach, wp2.back_reach, amount)
	new.foreward_reach = lerp(wp1.foreward_reach, wp2.foreward_reach, amount)
	new.arm_outward = lerp(wp1.arm_outward, wp2.arm_outward, amount)
	new.arm_raise = lerp(wp1.arm_raise, wp2.arm_raise, amount)
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
