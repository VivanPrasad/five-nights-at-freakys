extends Control

@onready var cam_buttons: Control = $CamButtons
@onready var cam_name_label: Label = $CamName
@onready var static_bg: AnimatedSprite2D = $StaticBG
@onready var rec_label: Label = $Rec/Label

@onready var cameras: Node3D = $Cameras

var current_cam : int = 0
const CAM_NAMES = [
	"Show Stage","Dining Area","Pirate Cove",
	"West Hall","W. Hall Corner","Supply Closet",
	"East Hall","E. Hall Corner","Backstage",
	"Kitchen","Restrooms","Office"]

const STATIC_MIN : float = 0.25
const STATIC_MAX : float = 0.9
const STATIC_DECAY : float = 1.8

func _ready() -> void:
	connect_buttons()

func connect_buttons() -> void:
	for button : TextureButton in cam_buttons.get_children():
		button.pressed.connect(_on_button_pressed.bind(button))

func _on_button_pressed(button:TextureButton) -> void:
	if current_cam == button.get_index(): button.button_pressed = true; return
	current_cam = button.get_index()
	for other : TextureButton in cam_buttons.get_children():
		other.button_pressed = false
	cam_buttons.get_children()[current_cam].button_pressed = true
	
	Audio.play_audio("cam_switch")
	static_bg.modulate.a = STATIC_MAX
	cam_name_label.text = CAM_NAMES[current_cam]
func _process(delta: float) -> void:
	if static_bg.modulate.a > STATIC_MIN:
		static_bg.modulate.a -= delta * STATIC_DECAY
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		for camera : Camera3D in cameras.get_children():
			camera.current = bool(camera.get_index() == (current_cam % cameras.get_child_count()))
			if camera.get_index() == (current_cam % cameras.get_child_count()):
				camera.rotation.y += 0.0008*sin((Time.get_ticks_msec()) * 0.0005)


func _on_rec_timer_timeout() -> void:
	rec_label.visible = !rec_label.visible


func _on_cam_down_mouse_entered() -> void:
	Game.player.toggle_cams()
