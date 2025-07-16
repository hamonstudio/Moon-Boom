extends Node3D

@export var engine: Node3D

func _process(_delta):
	position = engine.position
	#_print_up(_delta)

func _print_up(_delta) -> void:
	print("ring position : ",position)
