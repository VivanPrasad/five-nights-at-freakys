extends Control

@onready var cam_buttons: Control = $CamButtons
@onready var cam_name_label: Label = $CamName
@onready var static_bg: AnimatedSprite2D = $StaticBG

@onready var cameras: Node3D = $Cameras

var current_cam : int = 0
const CAM_NAMES = [
	"Show Stage","Dining Area","Pirate Cove",
	"West Hall","W. Hall Corner","Supply Closet",
	"East Hall","E. Hall Corner","Backstage",
	"Kitchen","Restrooms","Office"]

const STATIC_MIN : float = 0.25
const STATIC_MAX : float = 1.0

func _ready() -> void:
	connect_buttons()

func connect_buttons() -> void:
	for button : TextureButton in cam_buttons.get_children():
		button.pressed.connect(_on_button_pressed.bind(button))

func _on_button_pressed(button:TextureButton) -> void:
	current_cam = button.get_index()
	for other : TextureButton in cam_buttons.get_children():
		other.button_pressed = bool(other.get_index() == current_cam)
	Game.player.cam_switch.play()
	static_bg.modulate.a = STATIC_MAX
	cam_name_label.text = CAM_NAMES[current_cam]
func _process(delta: float) -> void:
	if static_bg.modulate.a > STATIC_MIN:
		static_bg.modulate.a -= delta * 0.8
	if visible:
		for camera : Camera3D in cameras.get_children():
			camera.current = bool(camera.get_index() == (current_cam % cameras.get_child_count()))
			if camera.get_index() == (current_cam % cameras.get_child_count()):
				camera.rotation.y += 0.0008*sin((Time.get_ticks_msec()) * 0.0005)
