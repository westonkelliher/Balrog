@tool
extends Node2D
class_name ChargeBar


#### Constants ####
@export var START_WIDTH := 4.0
@export var END_WIDTH := 100.0 :
	set(value):
		END_WIDTH = value
		if $Outer == null:
			return
		$Outer.size.x = END_WIDTH + 4.0
		$Outer.position.x = -0.5*(END_WIDTH + 4.0)
		$Fill.position.x = -0.5*END_WIDTH
	get:
		return END_WIDTH

@export var HEIGHT := 20.0 :
	set(value):
		HEIGHT = value
		if $Outer == null:
			return
		$Outer.size.y = HEIGHT + 4.0
		$Fill.size.y = HEIGHT
	get:
		return HEIGHT


#### Members ####
var _fill := 0.0
var _shown_fill := 0.0

#### Builtins ####
func _ready() -> void:
	END_WIDTH = END_WIDTH

func _process(delta: float) -> void:
	var move_amt: float = 0.005 + abs(_fill - _shown_fill)*10.0*delta
	_shown_fill = move_toward(_shown_fill, _fill, move_amt)
	if _fill == 0.0:
		_shown_fill = 0.0
	$Fill.size.x = lerp(START_WIDTH, END_WIDTH, _shown_fill)


#### Other ####
func set_progress(p: float) -> void:
	_fill = clamp(p, 0.0, 1.0)
