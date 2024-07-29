extends Control

@onready var newsletter: TextureRect = $Newsletter
@onready var continue_button: Button = $Newsletter/continue
@onready var black_bg: ColorRect = $BlackBG
@onready var date: Label = $Date
@onready var loading: TextureRect = $Loading

func play_intro() -> void:
	get_tree().set_pause(true)
	show()
	newsletter.show()
	await create_tween()\
		.tween_property(newsletter,"modulate:a",1.0,1.0)\
		.finished
	continue_button.show()
	await continue_button.pressed
	black_bg.show()
	newsletter.hide()
	date.show()
	Audio.stop_audio("title")
	Audio.stop_audio("menu_static")
	Audio.play_audio("cam_switch")
	loading.show()
	await get_tree().create_timer(0.2).timeout
	get_tree().set_pause(false)
