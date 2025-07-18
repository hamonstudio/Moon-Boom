extends Node3D

enum {IDLE,SPECIAL}
var anim_now_playing = IDLE

@onready var anim_tree = $AnimationTree
@export var blend_speed = 15

var b_special = 0

func _physics_process(delta: float) -> void:
	handle_animation(delta)

func handle_animation(delta):
	match anim_now_playing:
		IDLE:
			b_special = lerpf(b_special, 0 , blend_speed*delta)
		SPECIAL:
			b_special = lerpf(b_special, 1 , blend_speed*delta)

func update_tree():
	anim_tree["parameters/b_special/blend_amount"] = b_special
 
