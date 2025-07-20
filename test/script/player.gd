extends RigidBody3D

@export var camera : Camera3D # <- only for camera ray mouse position
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

# Mecha stats
@export var aiming_speed := 1.5
@export var max_speed := 40.0
@export var acc_move := 200.0
@export var acc_dash := 10.0
@export var acc_curve : Curve
@export var friction_curve : Curve
@export var world_density := .1
@export var cooldown_dash := 5.0


@onready var _is_mouse_active := true
@onready var pivot_aim = %CHARACTER
@onready var anim_arms = %ANIM_ARMS
@onready var anim_legs = %ANIM_LEGS
@onready var particle_drift_r = %PARTICLES_DRIFT_R
@onready var particle_drift_l = %PARTICLES_DRIFT_L
@onready var particle_engine_r = %PARTICLES_ENGINE_R
@onready var particle_engine_l = %PARTICLES_ENGINE_L
@onready var timer_dash: Timer = %Timer_Dash


var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var damp_default : float = ProjectSettings.get_setting("physics/3d/default_linear_damp")
var aim_dir := Vector2()
var aim_angle := Vector3.UP
var move_dir := Vector2()
var move_force := Vector3.ZERO
var engine_input := 0.0
var drift := false
var dash := false
var force_vector := Vector3.ZERO


# Signals
signal s_shoot
signal s_shoot_stop


func _physics_process(delta: float) -> void:
	if timer_dash.is_stopped() and Input.is_action_just_pressed("skill_left"):
		timer_dash.start(cooldown_dash)
		dash = true
		print("dashing")


func _process(_delta):
	aiming(_delta)
	moving(_delta)

	# Free mouse from capture
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click_left"):
		pass
	
	if event.is_action_pressed("click_right"):
		emit_signal("s_shoot")
		anim_arms.play("a_arms_idle")
	elif event.is_action_released("click_right"):
		emit_signal("s_shoot_stop")

	if event.is_action_pressed("skill_right"):
		anim_arms.play("a_punch_cyclone")

	if event.is_action_pressed("skill_left"):
		drift = true
		engine_input = 1.0
		physics_material_override.friction = 0.0
	elif event.is_action_released("skill_left"):
		drift = false
		engine_input = 0.0
		physics_material_override.friction = 1.0
	
	#if Input.is_action_just_pressed("skill_left"):
		#dash = true
		#print("dashing")


func _unhandled_input(event: InputEvent) -> void:
	# Containing mouse cursor
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and Input.is_action_pressed("click_left"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

	# Get the Mouse aim input direction and handle the Mouse aiming.
	if event is InputEventMouseMotion:
		_is_mouse_active = true

		# NOT GOOD _ PLACEHOLDER
		if Input.MOUSE_MODE_CONFINED_HIDDEN:
			var mouse_dir = event.screen_relative * mouse_sensitivity
			aim_dir = Vector2( mouse_dir.y, mouse_dir.x )
			aim_dir *= -1.0
			#print("aim dir : ",aim_dir, " | mouse dir : ", mouse_dir)
			aim_angle = Basis(Vector3(0.0,1.0,0.0), aim_dir.angle()).get_euler()

		# NOT GOOD _ Previous Camera Ray mouse position 
		#if Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED_HIDDEN:
			#var mouse_pos = get_viewport().get_mouse_position()
			#var mouse_ray_origin = camera.project_ray_origin(mouse_pos)
			#var mouse_ray_dir = mouse_ray_origin + camera.project_ray_normal(mouse_pos) * 1000
			#var mouse_ray_query = PhysicsRayQueryParameters3D.create(mouse_ray_origin, mouse_ray_dir)
			#mouse_ray_query.collide_with_bodies = true
			#var space_state = get_world_3d().direct_space_state
			#var mouse_ray_result = space_state.intersect_ray(mouse_ray_query)
			#if !mouse_ray_result.is_empty():
				#if mouse_ray_result.collider != self:
					#var mouse_ray_target_pos = mouse_ray_result.position - global_position
					#mouse_ray_target_pos.y += 2  # Adjust to point a couple meters above the hit point
					#mouse_ray_target_pos.x = mouse_ray_target_pos.x 
					#mouse_ray_target_pos.z = mouse_ray_target_pos.z
					#aim_dir = Vector2( mouse_ray_target_pos.z, mouse_ray_target_pos.x)
					#aim_dir *= -1.0
					#if aim_dir.length() > 0.2:
						#aim_angle = Basis(Vector3(0.0,1.0,0.0), aim_dir.angle()).get_euler()

	# Get the Joystick input
	elif event is InputEventJoypadMotion:
		_is_mouse_active = false
		# Containing mouse cursor
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

		# Handle the aiming
		aim_dir = Input.get_vector( "aim_up", "aim_down", "aim_left", "aim_right")
		aim_dir *= -1.0
		aim_angle = Basis(Vector3(0.0,1.0,0.0), aim_dir.angle()).get_euler()

	# Handle the moving for both contorl
	move_dir = Input.get_vector("move_right", "move_left", "move_down", "move_up")
	move_dir *= -1.0
	move_force = Vector3(move_dir.x, 0.0, move_dir.y)

	particule_move(move_dir)

############################ Movement v0.2 #####################################
func moving(delta: float) -> void:
	var dash_boost := 0.0
	var acc_total := acc_move + acc_dash * engine_input
	var vel := (dash_boost * linear_velocity.length()) / 10 
	var ac := acc_curve.sample_baked(acc_move) * acc_total

	
	if dash:
		dash_boost = 10
		dash = false

	if move_force.length() > 0.2:
		force_vector = move_force * ac * max_speed
		print("force_vector : ",force_vector , " | ac : ",ac , " | vel : ",vel , " | move_force : ", move_force)
	else:
		force_vector = force_vector * world_density

	
	apply_central_force(force_vector)
	
	###########################################################################


############################# Movement v0.1 #####################################
#func moving(delta: float) -> void:
	##var forward_dir := Vector3.FORWARD
	##var vel := forward_dir.dot(linear_velocity)
	#var vel := move_force.normalized().dot(linear_velocity)
	#var speed_ratio := vel / max_speed
	#var ac := acc_curve.sample_baked(speed_ratio)
	#var fc := friction_curve.sample_baked(speed_ratio)
	#var force_vector := ac * move_force
	## Drift movement
	#if move_force.length() > 0.2 and drift:
		#force_vector = force_vector * acc_dash * vel
		#force_vector.y = 0.0
		#apply_central_force(force_vector)
		##print("B vel : ", vel, "B fc : ", fc )
	## Base movement
	#elif move_force.length() > 0.2:
		#force_vector = force_vector * acc_move * fc
		#force_vector.y = 0.0
		#apply_central_force(force_vector)
		##print("vel : ", vel, "fc : ", fc )
	#force_vector = force_vector / damp_default
	############################################################################




func aiming(delta: float) -> void:
	if aim_dir.length() > 0.2:
		pivot_aim.rotation.y = lerp_angle(pivot_aim.rotation.y, aim_angle.y, aiming_speed * delta)
		#print ("aiming at: ",aim_dir)

#func _get_point_velocity(point: Vector3) -> Vector3:
	#return linear_velocity + angular_velocity.cross(point - global_position)

func particule_move(move_dir):
	# Move Animation and particles
	if move_dir.length() > 0.2 and dash:
		anim_legs.play("a_legs_dash")
		particle_engine_l.emitting = true
		particle_engine_r.emitting = true
		particle_drift_l.emitting = true
		particle_drift_r.emitting = true
	elif move_dir.length() > 0.2 and drift:
		anim_legs.play("a_legs_dash")
		particle_engine_l.emitting = false
		particle_engine_r.emitting = false
		particle_drift_l.emitting = true
		particle_drift_r.emitting = true
	elif move_dir.length() > 0.2:
		anim_legs.play("a_legs_dash")
		particle_engine_l.emitting = false
		particle_engine_r.emitting = false
		particle_drift_l.emitting = false
		particle_drift_r.emitting = false
	else:
		anim_legs.play("a_legs_idle")
		particle_engine_l.emitting = false
		particle_engine_r.emitting = false
		particle_drift_l.emitting = false
		particle_drift_r.emitting = false
