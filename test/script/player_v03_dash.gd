extends RigidBody3D

@export var camera : Camera3D # <- only for camera ray mouse position
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

# Mecha stats
@export var aiming_speed := 2.5
@export var steering_speed_base := 2.5
@export var max_speed := 16.0
@export var speed := 1500.0
@export var acc_dash := 8000.0
@export var acc_curve : Curve
@export var world_density := .1

@export var driftDuration := 0.8
@export var dashCooldown := 2.0



@onready var _is_mouse_active := true
@onready var pivot_aim: Node3D = %CHARACTER
@onready var pivot_hip: Node3D = %PIVOT_HIP
@onready var pivot_knee_l: Node3D = %PIVOT_KNEE_L
@onready var pivot_knee_r: Node3D = %PIVOT_KNEE_R

@onready var anim_arms = %ANIM_ARMS
@onready var anim_legs = %ANIM_LEGS

@onready var particle_drift_r = %PARTICLES_DRIFT_R
@onready var particle_drift_l = %PARTICLES_DRIFT_L
@onready var particle_engine_r = %PARTICLES_ENGINE_R
@onready var particle_engine_l = %PARTICLES_ENGINE_L

@onready var target_dash : Node3D = %TARGET_DASH


var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var damp_default : float = ProjectSettings.get_setting("physics/3d/default_linear_damp")
var aim_dir := Vector2()
var aim_angle := Vector3.UP
var move_dir := Vector2()
var move_angle := Vector3.UP
var move_force := Vector3.ZERO	
var direction := Vector3(move_dir.x, 0, move_dir.y).normalized()
var velocity = Vector3.ZERO

var doDrift := false
var doDash := false
var canDash := true
var dashDuration = 0.015
var force_vector := Vector3.ZERO
var steering_speed_modified = 1.0


# Signals
signal s_shoot
signal s_shoot_stop


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("skill_left") and canDash:
		dashing()
	
	#if doDash:
		#var dashDirection = transform.basis.z.normalized()
		#velocity = dashDirection * speed * 5
		#velocity.y = 0.0
		##print("do dash move | dash direction : ", dashDirection, " | direction : ", direction, " | move dir : ", move_dir)
	#elif direction:
		#velocity.x = direction.x * speed
		#velocity.z = direction.z * speed
	#else:
		#velocity.x = move_toward(velocity.x, 0.0, speed)
		#velocity.z = move_toward(velocity.z, 0.0, speed)
		#
	#var lookDirection = global_position + direction
	#lookDirection.y = global_position.y
	
	#look_at(lookDirection, Vector3.UP, true)
	#move_and_collide(velocity)


func _process(_delta):
	aiming(_delta)
	moving(_delta)
	steering(_delta)

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



func _unhandled_input(event: InputEvent) -> void:
	# Containing mouse cursor
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and Input.is_action_pressed("click_left"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

	# Get the Mouse aim input direction and handle the Mouse aiming.
	if event is InputEventMouseMotion:
		_is_mouse_active = true

		# NOT GOOD - CURRENT PLACEHOLDER
		if Input.MOUSE_MODE_CONFINED_HIDDEN:
			var mouse_dir = event.screen_relative * mouse_sensitivity
			aim_dir = Vector2( mouse_dir.y, mouse_dir.x )
			aim_dir *= -1.0
			#print("aim dir : ",aim_dir, " | mouse dir : ", mouse_dir)
			aim_angle = Basis(Vector3(0.0,1.0,0.0), aim_dir.angle()).get_euler()

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

	# Handle the moving for both contorl Joystick and WASD
	move_dir = Input.get_vector("move_right", "move_left", "move_down", "move_up")
	var steering_dir = Vector2(move_dir.y, move_dir.x) # declared before the sign invertion
	move_dir *= -1.0
	move_force = Vector3(move_dir.x, 0.0, move_dir.y)
	move_angle = Basis(Vector3(0.0,1.0,0.0), steering_dir.angle()).get_euler()

	particule_move(move_dir)


func moving(delta: float) -> void:
	var forward_dir := -target_dash.global_basis.z
	var vel := forward_dir.dot(linear_velocity)
	var speed_ratio := vel / max_speed
	var ac := acc_curve.sample_baked(speed_ratio)
	
	if move_force.length() > 0.2 and doDash:
		steering_speed_modified = steering_speed_base * 8
		#var dashDirection = target_dash.transform.basis.z.normalized()
		force_vector = move_force * acc_dash #- dashDirection
		#pivot_knee_l.rotation.x = lerp_angle(pivot_knee_l.rotation.x, -45.0, delta)
		#pivot_knee_r.rotation.x = lerp_angle(pivot_knee_r.rotation.x, -45.0, delta)
	elif move_force.length() > 0.2 and doDrift:
		steering_speed_modified = steering_speed_base * 4
		force_vector = move_force * ac * acc_dash
	elif move_force.length() > 0.2:
		steering_speed_modified = steering_speed_base
		force_vector = move_force * ac * speed
		#pivot_knee_l.rotation.x = lerp_angle(pivot_knee_l.rotation.x, -100.0, delta)
		#pivot_knee_r.rotation.x = lerp_angle(pivot_knee_r.rotation.x,-100.0, delta)
	else:
		steering_speed_modified = steering_speed_base
		force_vector = force_vector * world_density
		#pivot_knee_l.rotation.x = lerp_angle(pivot_knee_l.rotation.x, -5.0, delta)
		#pivot_knee_r.rotation.x = lerp_angle(pivot_knee_r.rotation.x, -5.0, delta)

	apply_central_force(force_vector)


func steering(delta: float) -> void:
	if move_dir.length() > 0.2:
		target_dash.rotation.y = lerp_angle(target_dash.rotation.y, move_angle.y, steering_speed_modified * delta)

	var steering_influence = ( move_angle.y / 3 ) #* aim_angle.y
	pivot_hip.rotation.y = lerp_angle(pivot_hip.rotation.y, steering_influence, steering_speed_base * 1.5 * delta)
	pivot_knee_l.rotation.y = lerp_angle(pivot_knee_l.rotation.y, steering_influence, steering_speed_base * 3 * delta)
	pivot_knee_r.rotation.y = lerp_angle(pivot_knee_r.rotation.y, steering_influence, steering_speed_base * 3 * delta)

	#clampf(%PIVOT_HIP.rotation.y, -1.0, 1.0)
	#clampf(pivot_knee_l.rotation.y, -0.5, 1.0)
	#clampf(pivot_knee_r.rotation.y, -1.0, 0.5)
	#%PIVOT_KNEE_R.look_at(%STEERING_ARROW.rotation, Vector3(0,1,0),false)



func drifting ():
	if doDrift:
		physics_material_override.friction = 0.1
	else:
		physics_material_override.friction = 1.0


func dashing():
	drifting()
	print("is dashing")
	canDash = false
	doDash = true
	doDrift = true
	await get_tree().create_timer(dashDuration).timeout
	doDash = false
	await get_tree().create_timer(driftDuration).timeout
	print("is drifting")
	doDrift = false
	print("dash cooldown")
	await get_tree().create_timer(dashCooldown).timeout
	canDash = true
	print("can dash now")


func aiming(delta: float) -> void:
	if aim_dir.length() > 0.2:
		pivot_aim.rotation.y = lerp_angle(pivot_aim.rotation.y, aim_angle.y, aiming_speed * delta)
		#print ("aiming at: ",aim_dir)

func particule_move(move_dir):
	# Move Animation and particles
	if move_dir.length() > 0.2 and doDash:
		anim_legs.play("a_legs_dash")
		particle_engine_l.emitting = true
		particle_engine_r.emitting = true
		particle_drift_l.emitting = true
		particle_drift_r.emitting = true
	elif move_dir.length() > 0.2 and doDrift:
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
