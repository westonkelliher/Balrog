@tool
extends Node3D


func _notification(what: int) -> void:
	if what == Node3D.NOTIFICATION_TRANSFORM_CHANGED:
		$Box.mesh.material.set("shader_parameter/scale", global_basis.get_scale().x)
	

func _ready() -> void:
	$FieldBody.sdf_func = get_signed_distance
	$FieldBody.up_func = get_up
	#
	$Box.mesh = $Box.mesh.duplicate()
	$Box.mesh.material = preload("res://mats/field_body_mat.tres").duplicate()
	$Box.mesh.material.set("shader_parameter/type", 1)

func get_signed_distance(rp: Vector3) -> float:
	#print("rp: " + str(rp.length()))
	return rp.length() - 1.0

func get_up(rp: Vector3) -> Vector3:
	return rp.normalized()
