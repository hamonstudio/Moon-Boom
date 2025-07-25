extends RayCast3D

const IMPACT = preload("res://vfx/vfx_explosion_small.tscn")

@export var projectile_speed := 60.0
@export var impact_duration := 1.0

@onready var remote_transform := RemoteTransform3D.new()

func _physics_process(delta: float) -> void:
	position += global_basis * Vector3.FORWARD * projectile_speed * delta
	target_position = Vector3.FORWARD * projectile_speed * delta
	force_raycast_update()
	var collider = get_collider()

	if is_colliding():
		global_position = get_collision_point()
		set_physics_process(false)
		var impact_child = IMPACT.instantiate()
		collider.add_child(impact_child)
		collider.add_child(remote_transform)
		
		impact_child.global_transform = global_transform
		remote_transform.global_transform = global_transform
		remote_transform.remote_path = remote_transform.get_path_to(self)
		
		await get_tree().create_timer(impact_duration).timeout
		remote_transform.tree_exited.connect(cleanup)

func cleanup() -> void:
	queue_free()
