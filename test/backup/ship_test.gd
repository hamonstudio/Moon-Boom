extends CharacterBody3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var impulse := 12.0

var _ship_input_direction = Vector2.ZERO
var _last_movement_direction = Vector3.BACK

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _ship_container: Node3D = %ShipContainer

func _ready() -> void:
	velocity = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click_left"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_ship_motion :=(
		event is InputEventMouseMotion and 
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	) 
	if is_ship_motion:
		_ship_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	#_camera_pivot.rotation.x += _camera_input_direction.y * delta
	#_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 6.0, PI / 6.0)
	#_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_ship_container.rotation.x += _ship_input_direction.y * delta
	_ship_container.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 6.0, PI / 6.0)
	_ship_container.rotation.y -= _ship_input_direction.x * delta

	_ship_input_direction = Vector2.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var forward := _ship_container.global_basis.z
	var right := _ship_container.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	
	var is_starting_dodge := Input.is_action_just_pressed("click_right")
	if is_starting_dodge:
		velocity.x += impulse
	
	move_and_slide()

	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_ship_container.global_rotation.y = lerp_angle(_ship_container.rotation.y, target_angle, rotation_speed * delta)

	#var ground_speed := velocity.length()
	#if ground_speed > 0.0:
		#_ship_container.move()
	#else:
		#_ship_container.idle()
