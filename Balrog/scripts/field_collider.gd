@tool
extends CollisionShape3D
class_name FieldCollider

@export var radius := 1.0 :
	set(value):
		radius = value
		if shape == null:
			return
		shape.radius = value
	get:
		return radius

func _ready() -> void:
	shape = shape.duplicate()
	radius = radius
