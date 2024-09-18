extends Node3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#$Balrog.gravities.append($Floor/GravObject)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("0"):
		var bun := preload("res://scenes/bunbun.tscn").instantiate()
		bun.global_position = $Balrog.global_position + Vector3.ONE*2.0
		bun.field_bodies = $Balrog.field_bodies
		$Objects.add_child(bun)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_balrog_throw_rock(rock: Rock) -> void:
	$Objects/Rocks.add_child(rock)
	if $Objects/Rocks.get_children().size() > 20:
		$Objects/Rocks.get_child(0).queue_free()
