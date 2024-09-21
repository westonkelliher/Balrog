extends Node3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#$Balrog.gravities.append($Floor/GravObject)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("0"):
		var bun := preload("res://scenes/bunbun.tscn").instantiate()
		$Objects.add_child(bun)
		var cam :=  get_viewport().get_camera_3d()
		bun.global_position = $Balrog.global_position + cam.global_basis * Vector3(0.0, 3.0, -8.0)
		#bun.field_bodies = $Balrog.field_bodies

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_balrog_throw_rock(rock: Rock) -> void:
	$Objects.add_child(rock)
	if $Objects.get_children().size() > 30:
		$Objects.get_child(0).queue_free()

func _on_balrog_throw_puck(puck: Puck) -> void:
	$Objects.add_child(puck)
	if $Objects.get_children().size() > 30:
		$Objects.get_child(0).queue_free()
