extends Control

@onready var buttons: VBoxContainer = $Panel/MarginContainer/Buttons
@onready var game : Game = $"/root/Game"

func _ready() -> void:
	connect_buttons()
	
func connect_buttons() -> void:
	if Multi.is_multi:
		buttons.get_children()[-1].name = "disconnect"
		buttons.get_children()[-2].disabled = false
		buttons.get_children()[-2].show()
	for button : Button in buttons.get_children():
		button.pressed.connect(
			_on_button_pressed.bind(button))
		button.text = button.name.to_upper()
		button.focus_mode = Control.FOCUS_NONE

func _on_button_pressed(button : Button) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Audio.play_audio("cam_switch")
	match str(button.name).to_lower():
		"resume": hide()
		"invite":
			DisplayServer.clipboard_set("Game Code: %s\n Expires in %s min" \
				% [Multi.ip_code,Multi.get_code_expiry()])
			var b: Button = buttons.get_children()[-2]
			b.disabled = true
			b.text = "<Copied>"
			await get_tree().create_timer(5.0).timeout
			b.disabled = false
			b.text = "INVITE"
		"quit":
			game.return_to_menu()
		"disconnect":
			game.return_to_menu()
	
