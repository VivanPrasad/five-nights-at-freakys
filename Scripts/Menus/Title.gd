extends Control

@onready var buttons: VBoxContainer = $Menu/Buttons

@onready var ui: CanvasLayer = $UI
@onready var intro_scene: Control = $UI/IntroScene

const GAME : PackedScene = preload("res://Scenes/Game.tscn")
const LOBBY : PackedScene = preload("res://Scenes/Menus/Lobby.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_buttons()
	Audio.play_audio("title")
	Audio.play_audio("menu_static")
	Audio.fade_in("title",0.0,2.0,1.5)

## Connect menu buttons with functions 
func connect_buttons() -> void:
	for button : Button in buttons.get_children():
		button.pressed.connect(
			_on_button_pressed.bind(button))
		button.mouse_entered.connect(
			_on_button_entered.bind(button))
		button.mouse_exited.connect(
			_on_button_exited.bind(button))
		button.text = button.name.to_upper()
		button.pivot_offset = button.size / 2
		button.focus_mode = Control.FOCUS_NONE

# Button Functionality
func _on_button_entered(button : Button) -> void:
	if button.disabled: return
	create_tween().\
		tween_property(button,"position:x",10.0,0.05).\
			set_trans(Tween.TRANS_CIRC)
	create_tween().\
		tween_property(button,"rotation_degrees",4.0,0.05).\
			set_trans(Tween.TRANS_CIRC)
func _on_button_exited(button : Button) -> void:
	if button.disabled: return
	create_tween().\
		tween_property(button,"position:x",0.0,0.04).\
			set_trans(Tween.TRANS_CIRC)
	create_tween().\
		tween_property(button,"rotation_degrees",0.0,0.04).\
			set_trans(Tween.TRANS_CIRC)
func _on_button_pressed(button : Button) -> void:
	match button.name.to_lower():
		"solo":
			await intro_scene.play_intro()
			get_tree().change_scene_to_packed(GAME)
		"multi":
			get_tree().change_scene_to_packed(LOBBY)
		"quit":
			get_tree().quit()
