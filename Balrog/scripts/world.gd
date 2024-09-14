extends Node3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#$Balrog.gravities.append($Floor/GravObject)


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
