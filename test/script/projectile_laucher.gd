extends Node3D

const PROJECTILE = preload("res://test/scenes/projectile.tscn")

@export var cooldown := 0.75

@onready var timer: Timer = $Timer

var trigger_held = false

func _physics_process(delta: float) -> void:
	if timer.is_stopped() and trigger_held:
		timer.start(cooldown)
		var projectile_child = PROJECTILE.instantiate()
		add_child(projectile_child)
		projectile_child.global_transform = global_transform


func _on_player_s_shoot() -> void:
	trigger_held = true
	#print("trigger held")


func _on_player_s_shoot_stop() -> void:
	trigger_held = false
	#print("trigger released")
