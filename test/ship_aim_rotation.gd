extends RigidBody3D

@export var engine: Node3D
@export var camera : Camera3D
@export var aiming_speed := 10.0

@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

@onready var _is_mouse_active := true
@onready var aim_pivot = %AIM_PIVOT

var mouse_aim_dir := Vector2.ZERO
var mouse_aim_angle := Vector3.UP
var joy_aim_dir := Vector2.ZERO
var joy_aim_angle := Vector3.UP


func _process(_delta):
	# Ship cabin follow engine with offset
	position.x = engine.position.x
	position.y = engine.position.y + 0.5
	position.z = engine.position.z
	
	if _is_mouse_active:
		_mouse_aiming(_delta)
	else:
		_joy_aiming(_delta)
	
	
	# Free mouse from capture
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _mouse_aiming(delta: float) -> void:
	if mouse_aim_dir.length() > 0.2:
		aim_pivot.rotation.y = lerp_angle(aim_pivot.rotation.y, mouse_aim_angle.y, aiming_speed * delta )
		#print ("MOUSE aiming at: ",mouse_aim_dir)

func _joy_aiming(delta: float) -> void:
	if joy_aim_dir.length() > 0.2:
		aim_pivot.rotation.y = lerp_angle(aim_pivot.rotation.y, joy_aim_angle.y, aiming_speed * delta )
		#print ("JOYSTICK aiming at: ",joy_aim_dir)


func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:
		_is_mouse_active = true
		# Containing mouse cursor
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and Input.is_action_just_pressed("click_left"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
				
		# Get the Mouse aim input direction and handle the Mouse aiming.
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED_HIDDEN:
			var mouse_pos = get_viewport().get_mouse_position()
			var mouse_ray_origin = camera.project_ray_origin(mouse_pos)
			var mouse_ray_dir = mouse_ray_origin + camera.project_ray_normal(mouse_pos) * 1000
			var mouse_ray_query = PhysicsRayQueryParameters3D.create(mouse_ray_origin, mouse_ray_dir)
		
			mouse_ray_query.collide_with_bodies = true
			var space_state = get_world_3d().direct_space_state
			var mouse_ray_result = space_state.intersect_ray(mouse_ray_query)
		
			if !mouse_ray_result.is_empty():
				if mouse_ray_result.collider != self:
					var mouse_ray_target_pos = mouse_ray_result.position - global_position
					mouse_ray_target_pos.y += 2  # Adjust to point a couple meters above the hit point
					mouse_ray_target_pos.x = mouse_ray_target_pos.x * mouse_sensitivity
					mouse_ray_target_pos.z = mouse_ray_target_pos.z * mouse_sensitivity
					mouse_aim_dir = Vector2( mouse_ray_target_pos.z, mouse_ray_target_pos.x)
					mouse_aim_dir *= -1.0
					if mouse_aim_dir.length() > 0.2:
						mouse_aim_angle = Basis(Vector3(0.0,1.0,0.0), mouse_aim_dir.angle()).get_euler()

		# Get the Joystick aim input direction and handle the Joystick aiming.
	elif event is InputEventJoypadMotion:
		_is_mouse_active = false
		joy_aim_dir = Input.get_vector( "aim_up", "aim_down", "aim_left", "aim_right")
		joy_aim_dir *= -1.0
		if joy_aim_dir.length() > 0.2:
			joy_aim_angle = Basis(Vector3(0.0,1.0,0.0), joy_aim_dir.angle()).get_euler()
