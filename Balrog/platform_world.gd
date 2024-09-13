extends Node3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#$Balrog.gravities.append($Floor/GravObject)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("1"):
		$Balrog.position = $Marks/Mark1.global_position
		$Balrog.rotation = $Marks/Mark1.global_rotation
	if Input.is_action_just_pressed("2"):
		$Balrog.position = $Marks/Mark2.global_position
		$Balrog.rotation = $Marks/Mark2.global_rotation
	if Input.is_action_just_pressed("3"):
		$Balrog.position = $Marks/Mark3.global_position
		$Balrog.rotation = $Marks/Mark3.global_rotation
	if Input.is_action_just_pressed("4"):
		$Balrog.position = $Marks/Mark4.global_position
		$Balrog.rotation = $Marks/Mark4.global_rotation
	if Input.is_action_just_pressed("5"):
		$Balrog.position = $Marks/Mark5.global_position
		$Balrog.rotation = $Marks/Mark5.global_rotation
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_balrog_throw_rock(rock: Rock) -> void:
	rock.queue_free()
	#$Objects.add_child(rock)
