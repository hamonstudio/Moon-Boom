extends CharacterBody3D

@export var SPEED = 7.0
@export var DASH_VELOCITY = 12.5
@export var JUMP_VELOCITY = 4.0
@export var INERTIA = 0.97
@export var CAMERA : Camera3D 

@onready var SHIP_AIM = %ShipPivotAim
@onready var SHIP_WOB = %ShipPivotWobble

var MOMENTUM = 0.0
var DASH_COOLDOWN = true
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
# Mouse input variables
var MOUSE_SENSITIVITY := 0.001
var MOUSE_HORIZONTAL := 0.0
var MOUSE_VERTICAL := 0.0

# Capture mouse
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * 2

	# Free mouse from capture
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
	var JOY_INPUT_DIR := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var JOY_DIR := (transform.basis * Vector3(JOY_INPUT_DIR.x, 0, JOY_INPUT_DIR.y)).normalized()
	if JOY_DIR:
		velocity.x = -JOY_DIR.x * SPEED
		velocity.z = -JOY_DIR.z * SPEED
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Get the Mouse aim input direction and handle the Mouse aiming.
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE and Input.is_action_just_pressed("click_left"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
			
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED_HIDDEN:
			var MOUSE_POS = get_viewport().get_mouse_position()
			var MOUSE_RAY_ORIGIN = CAMERA.project_ray_origin(MOUSE_POS)
			var MOUSE_RAY_DIR = MOUSE_RAY_ORIGIN + CAMERA.project_ray_normal(MOUSE_POS) * 500
			var MOUSE_RAY_QUERY = PhysicsRayQueryParameters3D.create(MOUSE_RAY_ORIGIN, MOUSE_RAY_DIR)
	
			MOUSE_RAY_QUERY.collide_with_bodies = true
			var SPACE_STATE = get_world_3d().direct_space_state
			var MOUSE_RAY_RESULT = SPACE_STATE.intersect_ray(MOUSE_RAY_QUERY)
	
			if !MOUSE_RAY_RESULT.is_empty():
				if MOUSE_RAY_RESULT.collider != self:
					var MOUSE_RAY_TARGET = MOUSE_RAY_RESULT.position * -1.0
					MOUSE_RAY_TARGET.y += 1.0  # Adjust to point 1 meter above the hit point
					SHIP_AIM.look_at(MOUSE_RAY_TARGET)
	
	elif event is InputEventJoypadMotion:
		# Get the Joystick aim input direction and handle the Joystick aiming.
		var JOY_AIM_DIR := Input.get_vector( "aim_up", "aim_down", "aim_left", "aim_right")
		JOY_AIM_DIR *= -1.0
		if JOY_AIM_DIR.length() > 0.2:
			SHIP_AIM.rotation = Basis(Vector3(0.0,1.0,0.0), JOY_AIM_DIR.angle() ).get_euler()
			#print ("JOYSTICK aiming at: ",JOY_AIM_DIR)

	move_and_slide()
