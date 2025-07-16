extends CollisionShape3D

@onready var animation_tree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

func idle():
	state_machine.travel("test_ship_idle")

func move():
	state_machine.travel("test_ship_idle")

func dodge_right():
	state_machine.travel("test_ship_dodge_right")

func dodge_left():
	state_machine.travel("test_ship_dodge_left")
