@tool
extends Node3D



func _ready() -> void:
	$FieldBody.sdf_func = get_signed_distance

func get_signed_distance(rp: Vector3) -> float:
	#print("rp: " + str(rp.length()))
	return rp.length() - 1.0
