extends Control

@onready var code_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/code
@onready var players_label: Label = $MarginContainer/VBoxContainer/HBoxContainer2/players

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	code_label.text = Multi.ip_code
	players_label.text = "%s/%s" % [Multi.player_count,Multi.MAX_PLAYERS]
