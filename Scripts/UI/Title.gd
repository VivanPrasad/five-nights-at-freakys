extends Control

@onready var buttons: VBoxContainer = $MarginContainer/Buttons
@onready var music: AudioStreamPlayer = $Music
@onready var sfx : AudioStreamPlayer = $SFX

@onready var join_button: Button = $MarginContainer/Buttons/join
@onready var line_edit: LineEdit = $MarginContainer/Buttons/join/LineEdit

const GAME : PackedScene = preload("res://Scenes/Game.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect_buttons()
	join_button.tooltip_text = "Local Join Code: %s" % Multi.get_code_from_ip("127.0.0.1")
	create_tween().tween_property(music,"volume_db",-12.0,5.0)\
	.set_delay(1.5)\
	.set_trans(Tween.TRANS_CIRC)

## Connect menu buttons with functions 
func connect_buttons() -> void:
	for button : Button in buttons.get_children():
		button.pressed.connect(_on_button_pressed.bind(button))
		button.text = button.name.to_upper()
		button.focus_mode = Control.FOCUS_NONE

func _on_button_pressed(button : Button) -> void:
	match button.name:
		"solo":
			var scene : Game = GAME.instantiate()
			scene.is_solo = true
			var packed = PackedScene.new()
			packed.pack(scene)
			get_tree().change_scene_to_packed(packed)
		"host":
			var scene : Game = GAME.instantiate()
			scene.is_host = true
			var packed = PackedScene.new()
			packed.pack(scene)
			get_tree().change_scene_to_packed(packed)
		"join":
			var scene : Game = GAME.instantiate()
			scene.ip = Multi.get_ip_from_code(line_edit.text)
			var packed = PackedScene.new()
			packed.pack(scene)
			get_tree().change_scene_to_packed(packed)
		"quit":
			get_tree().quit()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	join_button.disabled = len(line_edit.text) != 8
