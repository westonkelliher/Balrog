extends Node2D


var active := false :
	set(value):
		active = value
		print(value)
		if value:
			$Timer.start()
	get:
		return active

func _ready() -> void:
	set_fill(1.0)

func _process(delta: float) -> void:
	if !active:
		visible = false
		return
	var parent := get_parent()
	var p_3d: Vector3 = parent.global_position + parent.global_basis * Vector3.DOWN*0.45
	if !is_in_front_of_camera(p_3d):
		visible = false
	else:
		visible = true
		set_screen_appearance(p_3d)
		
	

func set_screen_appearance(p: Vector3) -> void:
	var cam := get_viewport().get_camera_3d()
	position = cam.unproject_position(p)
	var distance := p.distance_to(cam.global_position)
	scale = Vector2.ONE * pow(distance, -0.6) * 6.0

func is_in_front_of_camera(p: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d()
	var inv := cam.global_transform.affine_inverse()
	return (inv * p).z < 0.0



func set_fill(fill: float) -> void:
	$ChargeBar.set_progress(fill)
	if fill <= 0.0:
		$ChargeBar.COLOR = Color(0.5, 0.0, 0.0, 0.2)


func _on_timer_timeout() -> void:
	active = false
