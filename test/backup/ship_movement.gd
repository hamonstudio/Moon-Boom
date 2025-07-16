extends CharacterBody3D

@export var SPEED = 6.0
@export var DASH_VELOCITY = 12.5
@export var JUMP_VELOCITY = 4.0
@export var INERTIA = 0.98

@onready var SHIP_AIM = %ShipPivotAim
@onready var SHIP_WOB = %ShipPivotWobble

var MOMENTUM = 0.0
var DASH_COOLDOWN = true
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 2

	# Handle attack.
	if Input.is_action_just_pressed("click_left") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		print ("ATTACK PLACEHOLDER!", JUMP_VELOCITY)

	# Handle dash and cooldown.
	if Input.is_action_just_pressed("click_right") and DASH_COOLDOWN == true:
		MOMENTUM = DASH_VELOCITY
		DASH_COOLDOWN = false
		print ("DASH!", MOMENTUM)

	# Handle skill left.
	if Input.is_action_just_pressed("skill_left"):
		print ("SKILL LEFT!")

	# Handle skill right.
	if Input.is_action_just_pressed("skill_right"):
		print ("SKILL RIGHT!")

	# Get the movement input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = -direction.x * SPEED
		velocity.z = -direction.z * SPEED
		#print ("mmntm: ", MOMENTUM, " | velX:", velocity.x, " | velZ:", velocity.z)
	# Applies Dash momentum to velocity as long as momentum above minimum
	else:
		velocity.x = move_toward(velocity.x, velocity.x * INERTIA, SPEED)
		velocity.z = move_toward(velocity.z, velocity.z * INERTIA, SPEED)
		MOMENTUM = 0.0

	if MOMENTUM >= 0.1:
		MOMENTUM = MOMENTUM * INERTIA * 0.9
		velocity.x += velocity.x * MOMENTUM
		velocity.z += velocity.z * MOMENTUM
	else:
		MOMENTUM = 0.0
		DASH_COOLDOWN = true

# Get the aim input direction and handle the aiming.
	var aim_dir := Input.get_vector( "aim_up", "aim_down", "aim_left", "aim_right")
	aim_dir *= -1.0
	if aim_dir.length() > 0.2:
		SHIP_AIM.rotation = Basis(Vector3(0.0,1.0,0.0), aim_dir.angle() ).get_euler()
		print ("aiming at: ",aim_dir)

	move_and_slide()
