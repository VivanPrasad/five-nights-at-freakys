class_name Player
extends CharacterBody3D

@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var footstep: AudioStreamPlayer3D = $Footstep
@onready var flashlight: SpotLight3D = $Neck/Camera/Flashlight
@onready var face: Sprite3D = $Neck/Face

const WALK_SPEED : float = 2.8
const RUN_SPEED : float = WALK_SPEED * 1.3
const DECELERATION : float = 0.08

const IDLE_ANIM_SPEED : float = 0.3
const WALK_ANIM_SPEED : float = 1.8
const RUN_ANIM_SPEED : float = 2.8


const TILT_SPEED : float = 0.003
const TILT_STRENGTH : float = 0.65

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = is_multiplayer_authority()
	flashlight.visible = camera.current
	face.visible = not is_multiplayer_authority()
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	# --- Gravity ---
	if not is_on_floor():
		velocity += get_gravity() * delta
	# --- Input Movement ---
	var input_dir := Input.get_vector(
		"left", "right", "up", "down")
	var direction := (neck.transform.basis * Vector3(
		input_dir.x, 0, input_dir.y)).normalized()
	var speed : float = WALK_SPEED
	var anim_speed : float = WALK_ANIM_SPEED
	var is_running : bool = bool(
		Input.get_action_strength("run"))
	if direction:
		# Moving
		if is_running:
			speed = RUN_SPEED
			anim_speed = RUN_ANIM_SPEED
		else:
			speed = WALK_SPEED
			anim_speed = WALK_ANIM_SPEED
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		camera.rotation_degrees.z = (TILT_STRENGTH+float(
			is_running)/5.0)*sin(
				Time.get_ticks_msec()*(TILT_SPEED
				+float(is_running)/900.0))
		animation.speed_scale = anim_speed
		if not footstep.is_playing():
			footstep.play(0.70*[0,1,2,3].pick_random())
		footstep.pitch_scale = 1.2 + (
			float(is_running) / 2.0)
	else:
		# Idle
		velocity.x = move_toward(velocity.x, 0, 
			WALK_SPEED*DECELERATION)
		velocity.z = move_toward(velocity.z, 0, 
			WALK_SPEED*DECELERATION)
		camera.rotation.z = move_toward(
			camera.rotation.z, 0, DECELERATION)
		animation.speed_scale = IDLE_ANIM_SPEED
		footstep.stop()

	move_and_slide()

func _unhandled_input(event) -> void:
	# Mouse Capture
	if not is_multiplayer_authority(): return
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Camera Movement
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, 
				deg_to_rad(-70), deg_to_rad(70))
