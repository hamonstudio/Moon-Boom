extends SpringArm3D

@export var player: Node3D

func _process(_delta):
	position = player.position
