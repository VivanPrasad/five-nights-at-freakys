extends Control

@onready var buttons: VBoxContainer = $Menu/Buttons
@onready var music: AudioStreamPlayer = $Music
@onready var static_sfx : AudioStreamPlayer = $StaticSFX
@onready var switch_sfx: AudioStreamPlayer = $SwitchSFX
@onready var loading: TextureRect = $Loading
@onready var date: Label = $Date
@onready var newsletter: TextureRect = $Newsletter
@onready var black_bg: ColorRect = $BlackBG

@onready var join_button: Button = $Menu/Buttons/join
@onready var line_edit: LineEdit = $Menu/Buttons/join/LineEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loading.hide()
	connect_buttons()
	join_button.tooltip_text = "Local Join Code: %s" % Multi.get_code_from_ip("127.0.0.1")
	create_tween().tween_property(music,"volume_db",-8.0,5.0)\
	.set_delay(1.0)\
	.set_trans(Tween.TRANS_CIRC)


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
		button.focus_mode = Control.FOCUS_NONE

func _on_button_entered(button : Button) -> void:
	if not button.disabled: button.text = "> %s" \
		% button.name.to_upper()
func _on_button_exited(button : Button) -> void:
	button.text = button.name.to_upper()
func _on_button_pressed(button : Button) -> void:
	
	match button.name.to_lower():
		"solo":
			await play_intro()
			var scene : Game = load("res://Scenes/Game.tscn").instantiate()
			scene.is_solo = true
			var packed = PackedScene.new()
			packed.pack(scene)
			get_tree().change_scene_to_packed(packed)
		"host":
			await play_intro()
			var scene : Game = load("res://Scenes/Game.tscn").instantiate()
			scene.is_host = true
			var packed = PackedScene.new()
			packed.pack(scene)
			get_tree().change_scene_to_packed(packed)
		"join":
			await play_intro()
			var scene : Game = load("res://Scenes/Game.tscn").instantiate()
			scene.ip = Multi.get_ip_from_code(line_edit.text)
			var packed = PackedScene.new()
			packed.pack(scene)
			get_tree().change_scene_to_packed(packed)
		"quit":
			get_tree().quit()

func _on_line_edit_text_changed(_new_text: String) -> void:
	join_button.disabled = len(line_edit.text) != 8 or not Multi.get_ip_from_code(line_edit.text).is_valid_ip_address()

func play_intro() -> void:
	var continue_button : Button = newsletter.get_child(0)
	newsletter.show()
	await create_tween().tween_property(newsletter,"modulate:a",1.0,0.5).finished
	continue_button.show()
	await continue_button.pressed
	black_bg.show()
	newsletter.hide()
	date.show()
	switch_sfx.play()
	music.stop()
	static_sfx.stop()
	loading.show()
	await get_tree().create_timer(0.5).timeout
