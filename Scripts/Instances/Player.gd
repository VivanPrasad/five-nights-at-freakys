class_name Player
extends CharacterBody3D

@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var flashlight: SpotLight3D = $Neck/Camera/Flashlight
@onready var selector: RayCast3D = $Neck/Camera/Selector

@onready var cam_animation: AnimationPlayer = $HUD/CamAnimation/AnimationPlayer
@onready var cam_open: AudioStreamPlayer = $SFX/CamOpen
@onready var cam_close: AudioStreamPlayer = $SFX/CamClose
@onready var cam_switch: AudioStreamPlayer = $SFX/CamSwitch

@onready var flashlight_sfx: AudioStreamPlayer3D = $Flashlight
@onready var footstep_sfx: AudioStreamPlayer3D = $Footstep

@onready var bass_amb: AudioStreamPlayer = $Ambience/BassAmb
@onready var horror_amb: AudioStreamPlayer = $Ambience/HorrorAmb


@onready var face: Sprite3D = $Neck/Face

@onready var hud: CanvasLayer = $HUD
@onready var office_hud: Control = $HUD/OfficeHUD
@onready var camera_hud: Control = $HUD/CameraHUD
@onready var selector_hud: Sprite2D = $HUD/SelectorHUD

@onready var usage_hud: Sprite2D = $HUD/OfficeHUD/MarginContainer/VBoxContainer2/HBoxContainer2/usage
@onready var power_hud: Label = $HUD/OfficeHUD/MarginContainer/VBoxContainer2/HBoxContainer/power
@onready var hour_hud: Label = $HUD/OfficeHUD/MarginContainer/VBoxContainer/HBoxContainer/hour

@onready var fade_in: AnimationPlayer = $HUD/Fade/FadeIn

@onready var game : Game = $"/root/Game"

const SPAWN_POSITION : Vector3 = Vector3(0,1.15,10)
const WALK_SPEED : float = 2.5
const RUN_SPEED : float = WALK_SPEED * 1.15
const DECELERATION : float = 0.08

const IDLE_ANIM_SPEED : float = 0.3
const WALK_ANIM_SPEED : float = 1.8
const RUN_ANIM_SPEED : float = 2.8

const TILT_SPEED : float = 0.005
const TILT_STRENGTH : float = 0.8

var selector_node : Node = null
var in_office : bool = false
var in_cams : bool = false

# -----------------  Main Loops  -----------------

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))
func _ready() -> void:
	validate_authority()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	# --- Gravity ---
	if not is_on_floor(): velocity += get_gravity() * delta
	# --- Input Movement ---
	handle_movement()
	move_and_slide()
	# --- Heads Up Display ---
	handle_hud(delta)
	# --- Selector ---
	selector_node = selector.get_collider()

func _unhandled_input(event) -> void:
	if not is_multiplayer_authority(): return
	# Mouse Capture
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
	# Flashlight Toggle
	if Input.is_action_just_pressed("flashlight") and not in_office:
		flashlight.visible = !flashlight.visible
		flashlight_sfx.play()
	if flashlight.visible and in_office:
		flashlight.hide()
		flashlight_sfx.play()
	if in_cams and not in_office:
		toggle_cams()
	# Selector Interaction
	if Input.is_action_just_released("interact") and selector_node:
		handle_interaction()
	if Input.is_action_just_pressed("cams") and in_office:
		toggle_cams()

# ---------------------------------------

## Validate Multiplayer Authority 
func validate_authority() -> void:
	var authority : bool = is_multiplayer_authority()
	if authority:
		set_position(SPAWN_POSITION)
		Game.player = self
		fade_in.get_parent().show()
		fade_in.play("FadeIn")
		bass_amb.play()
		horror_amb.play()
	
	hud.visible = authority
	set_physics_process(authority)
	set_process_unhandled_input(authority)
	camera.current = authority
	face.visible = not authority
	Input.set_mouse_mode(2*int(authority))

## Handle Player HUD every frame
func handle_hud(delta:float) -> void:
	office_hud.modulate.a += 2 * delta * (float(in_office)-0.5)
	office_hud.modulate.a = clamp(
		office_hud.modulate.a,0.0,1.0) 
	selector_hud.visible = bool(selector_node != null)

## Handle Player Movement
func handle_movement() -> void:
	var input_dir := Input.get_vector(
		"left", "right", "up", "down")
	var direction := (neck.transform.basis * Vector3(
		input_dir.x, 0, input_dir.y)).normalized()
	var speed : float = WALK_SPEED
	var anim_speed : float = WALK_ANIM_SPEED
	var is_running : bool = bool(
		Input.get_action_strength("run"))
	
	direction *= int(not in_cams) # Check for in cams
	
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
		if not footstep_sfx.is_playing():
			footstep_sfx.play(0.70*[0,1,2,3].pick_random())
		footstep_sfx.pitch_scale = 1.2 + (
			float(is_running) / 2.0)
	else:
		# Idle
		velocity.x = move_toward(velocity.x, 0, 
			WALK_SPEED*DECELERATION)
		velocity.z = move_toward(velocity.z, 0, 
			WALK_SPEED*DECELERATION)
		camera.rotation.z = 0
		animation.speed_scale = IDLE_ANIM_SPEED
		footstep_sfx.stop()


func handle_interaction() -> void:
	var interact_node = selector_node.get_parent().get_parent()
	if interact_node is Door:
		if Game.is_solo:
			interact_node.toggle_door()
		else:
			interact_node.rpc("toggle_door")
	elif interact_node is Wing:
		if Game.is_solo:
			interact_node.call_deferred("toggle_"+\
				selector_node.name.to_lower())
		else:
			interact_node.rpc("toggle_"+\
				selector_node.name.to_lower())

func toggle_cams() -> void:
	if not Game.has_power: return
	if not cam_animation.is_playing():
		in_cams = !in_cams
		if in_cams:
			game.rpc("update_usage",game.usage + 1)
			cam_open.play()
			cam_close.stop()
			cam_animation.play("OpenCam")
			await cam_animation.animation_finished
			camera.current = false
			camera_hud.show()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			camera.current = true
			game.rpc("update_usage",game.usage - 1)
			cam_open.stop()
			cam_close.play()
			cam_animation.play_backwards("OpenCam")
			camera_hud.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
# ------------- Multiplayer Stuff -------------
