extends RigidBody3D

@export var wheels: Array[RaycastWheel]
@export var acceleration := 1200.0
@export var max_speed := 10.0
@export var accel_curve : Curve
@export var tire_turn_speed := 5.0
@export var tire_max_turn_degrees := 45
@export var tire_back_turn_speed := 0.75
@export var tire_back_max_turn_degrees := 60

var motor_input := 0

func _unhandled_input(event: InputEvent) -> void:
	# handles Acceleration
	if event.is_action_pressed("move_up"):
		motor_input = 1
		print("acc UP")
	elif event.is_action_released("move_up"):
		motor_input = 0
		
	# handles Deceleration
	if event.is_action_pressed("move_down"):
		motor_input = -1
		print("acc DOWN")
	elif event.is_action_released("move_down"):
		motor_input = 0

func _basic_steering_rotation(delta: float) -> void:
	var turn_input := Input.get_axis("move_right","move_left") * tire_turn_speed
	var turn_input_back := Input.get_axis("move_right","move_left") * tire_back_turn_speed
	if turn_input:
		$WHEEL_FR.rotation.y = clampf($WHEEL_FR.rotation.y + turn_input * delta,
		deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
		$WHEEL_FL.rotation.y = clampf($WHEEL_FL.rotation.y + turn_input * delta,
		deg_to_rad(-tire_max_turn_degrees), deg_to_rad(tire_max_turn_degrees))
		$WHEEL_RR.rotation.y = clampf($WHEEL_RR.rotation.y + turn_input_back * delta,
		deg_to_rad(-tire_back_max_turn_degrees), deg_to_rad(tire_back_max_turn_degrees))
		$WHEEL_RL.rotation.y = clampf($WHEEL_RL.rotation.y + turn_input_back * delta,
		deg_to_rad(-tire_back_max_turn_degrees), deg_to_rad(tire_back_max_turn_degrees))
	else:
		$WHEEL_FR.rotation.y = move_toward($WHEEL_FR.rotation.y, 0, tire_max_turn_degrees * delta)
		$WHEEL_FL.rotation.y = move_toward($WHEEL_FL.rotation.y, 0, tire_max_turn_degrees * delta)
		$WHEEL_RR.rotation.y = move_toward($WHEEL_RR.rotation.y, 0, tire_back_max_turn_degrees * delta)
		$WHEEL_RL.rotation.y = move_toward($WHEEL_RL.rotation.y, 0, tire_back_max_turn_degrees * delta)

func _physics_process(_delta: float) -> void:
	_basic_steering_rotation(_delta)
	var grounded := false
	for wheel in wheels:
		if wheel.is_colliding():
			grounded = true
		wheel.force_raycast_update()
		_do_single_wheel_suspension(wheel)
		_do_single_wheel_acceleration(wheel)
	
	if grounded:
		center_of_mass = Vector3.ZERO
	else:
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = Vector3.DOWN * 0.5

func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)

func _do_single_wheel_traction(ray: RaycastWheel) -> void:
	if not ray.is_colliding(): return

func _do_single_wheel_acceleration(ray: RaycastWheel) -> void:
	var forward_dir := -ray.global_basis.z
	var vel := forward_dir.dot(linear_velocity)
	
	if ray.is_colliding():
		#animate engines based on direction
		#ray.wheel.rotate_z((-vel * get_process_delta_time())/ray.wheel_radius)
		
		#engine animation test
		ray.wheel.rotate_x((motor_input * vel * 0.1 * get_process_delta_time())/ray.wheel_radius)

		var contact := ray.wheel.global_position
		var force_pos := contact - global_position

		if ray.is_motor and motor_input:
			var speed_ratio := vel / max_speed
			var ac := accel_curve.sample_baked(speed_ratio)
			var force_vector := forward_dir * acceleration * motor_input * ac
			apply_force(force_vector, force_pos)

func _do_single_wheel_suspension(ray: RaycastWheel) -> void:
	if ray.is_colliding():
		#next like makes raycast work only on negative offset
		ray.target_position.y = -(ray.rest_dist + ray.wheel_radius + ray.over_extend)
		var contact := ray.get_collision_point()
		var spring_up_dir := ray.global_transform.basis.y
		var spring_len := ray.global_position.distance_to(contact)
		var offset := ray.rest_dist - spring_len
		
		ray.wheel.position.y = -spring_len
		
		var spring_force := ray.spring_strength * offset
		
		# damping force = damping * relative velocity
		var world_vel := _get_point_velocity(contact)
		var relative_vel := spring_up_dir.dot(world_vel)
		var spring_damp_force := ray.spring_damping * relative_vel
		
		var force_vector := (spring_force - spring_damp_force) * ray.get_collision_normal()
		
		contact = ray.wheel.global_position
		var force_pos_offset := contact - global_position
		apply_force(force_vector, force_pos_offset)
