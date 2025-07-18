extends Node3D

@onready var particle_drift_r = %PARTICLES_DRIFT_R
@onready var particle_drift_l = %PARTICLES_DRIFT_L
@onready var particle_engine_r = %PARTICLES_ENGINE_R
@onready var particle_engine_l = %PARTICLES_ENGINE_L

@onready var anim_arms = %ANIM_ARMS

# INPUTS RECEIVER

func _on_player_s_shoot() -> void:
	anim_arms.play("a_arms_idle")
	#print("s_shoot")

func _on_player_s_special() -> void:
	anim_arms.play("a_punch_cyclone")
	print("s_special")


# PREVIOUS RAY CAST FOR REF

#@export var wheels: Array[RaycastWheel]
#@export var acceleration := 600.0
#@export var max_speed := 24.0
#@export var accel_curve : Curve
#@export var tire_turn_speed := 1.0
#@export var tire_max_turn_degrees := 30
#@export var tire_back_turn_speed := 0.25
#@export var tire_back_max_turn_degrees := 2
#@export var aim_turn_speed := 30
#
#
#
#var motor_input := 0
#var drift := false
#var is_drifting := false
#var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
#
#func _unhandled_input(event: InputEvent) -> void:
	##handles drift hand break
	#if event.is_action_pressed("drift"):
		#drift = true
		#is_drifting = true
	#elif event.is_action_released("drift"):
		#drift = false
#
	## handles Acceleration
	#if event.is_action_pressed("move_up"):
		#motor_input = 1
		#print("acc UP")
	#elif event.is_action_released("move_up"):
		#motor_input = 0
	## handles Deceleration
	#if event.is_action_pressed("move_down"):
		#motor_input = -1
		#print("acc DOWN")
	#elif event.is_action_released("move_down"):
		#motor_input = 0
#
#func _basic_steering_rotation(delta: float) -> void:
	#var turn_input := Input.get_axis("move_right","move_left") * tire_turn_speed
	#var turn_input_back := Input.get_axis("move_right","move_left") * tire_back_turn_speed
	#if turn_input:
		#$WHEEL_FR.rotation.y = clampf($WHEEL_FR.rotation.y + turn_input * delta,
		#deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
		#$WHEEL_FL.rotation.y = clampf($WHEEL_FL.rotation.y + turn_input * delta,
		#deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
		#$WHEEL_RR.rotation.y = clampf($WHEEL_RR.rotation.y + turn_input_back * delta,
		#deg_to_rad(-tire_back_max_turn_degrees), deg_to_rad(tire_back_max_turn_degrees))
		#$WHEEL_RL.rotation.y = clampf($WHEEL_RL.rotation.y + turn_input_back * delta,
		#deg_to_rad(-tire_back_max_turn_degrees), deg_to_rad(tire_back_max_turn_degrees))
	#else:
		#$WHEEL_FR.rotation.y = move_toward($WHEEL_FR.rotation.y, 0, tire_max_turn_degrees * delta / 40)
		#$WHEEL_FL.rotation.y = move_toward($WHEEL_FL.rotation.y, 0, tire_max_turn_degrees * delta / 40)
		#$WHEEL_RR.rotation.y = move_toward($WHEEL_RR.rotation.y, 0, tire_back_max_turn_degrees * delta / 60)
		#$WHEEL_RL.rotation.y = move_toward($WHEEL_RL.rotation.y, 0, tire_back_max_turn_degrees * delta / 60)
#
#
#func _physics_process(_delta: float) -> void:
	#_basic_steering_rotation(_delta)
	#var grounded := false
	#
	#for wheel in wheels:
		#if wheel.is_colliding():
			#grounded = true
		#wheel.force_raycast_update()
		#_do_single_wheel_suspension(wheel)
		#_do_single_wheel_acceleration(wheel)
		#_do_single_wheel_traction(wheel)
	#
	#if grounded:
		#center_of_mass = Vector3.ZERO
	#else:
		#center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		#center_of_mass = Vector3.DOWN * 0.5
#
#func _get_point_velocity(point: Vector3) -> Vector3:
	#return linear_velocity + angular_velocity.cross(point - global_position)
#
#func _do_single_wheel_traction(ray: RaycastWheel) -> void: 
	#if not ray.is_colliding(): return
	#
	#var steer_side_dir := ray.global_basis.x
	#var tire_vel := _get_point_velocity(ray.wheel.global_position)
	#var steering_x_vel := steer_side_dir.dot(tire_vel)
	#
	#var grip_factor := absf(steering_x_vel/tire_vel.length())
	#var x_traction := ray.grip_curve.sample_baked(grip_factor)
	#
#
	#if not drift and grip_factor < 0.2:
		#is_drifting = false
		#particle_drift_r.emitting = false
		#particle_drift_l.emitting = false
#
	#if drift:
		#x_traction = 0.06
		#if not particle_drift_r.emitting:
			#particle_drift_r.emitting = true
			#particle_drift_l.emitting = true
	#elif is_drifting:
		#x_traction = 0.2
#
	#var x_force := -steer_side_dir * steering_x_vel * x_traction * ((mass*gravity)/2.0)
	#
	#var force_pos := ray.wheel.global_position- global_position
	#apply_force(x_force, force_pos)
#
#func _do_single_wheel_acceleration(ray: RaycastWheel) -> void:
	#var forward_dir := -ray.global_basis.z
	#var vel := forward_dir.dot(linear_velocity)
	#
	#if ray.is_colliding():
		#var contact := ray.wheel.global_position
		#var force_pos := contact - global_position
#
		#if ray.is_motor and motor_input:
			#var speed_ratio := vel / max_speed
			#var ac := accel_curve.sample_baked(speed_ratio)
			#var force_vector := forward_dir * acceleration * motor_input * ac
			#apply_force(force_vector, force_pos)
			#
			#particle_engine_r.emitting = true
			#particle_engine_l.emitting = true
		#else:
			#particle_engine_r.emitting = false
			#particle_engine_l.emitting = false
#
#func _do_single_wheel_suspension(ray: RaycastWheel) -> void:
	#if ray.is_colliding():
		##next like makes raycast work only on negative offset
		#ray.target_position.y = -(ray.rest_dist + ray.wheel_radius + ray.over_extend)
		#var contact := ray.get_collision_point()
		#var spring_up_dir := ray.global_transform.basis.y
		#var spring_len := maxf(0.0, ray.global_position.distance_to(contact))
		#var offset := ray.rest_dist - spring_len
		#
		#ray.wheel.position.y = -spring_len
		#
		#var spring_force := ray.spring_strength * offset
		#
		## damping force = damping * relative velocity
		#var world_vel := _get_point_velocity(contact)
		#var relative_vel := spring_up_dir.dot(world_vel)
		#var spring_damp_force := ray.spring_damping * relative_vel
		#
		#var force_vector := (spring_force - spring_damp_force) * ray.get_collision_normal()
		#
		#contact = ray.wheel.global_position
		#var force_pos_offset := contact - global_position
		#apply_force(force_vector, force_pos_offset)
