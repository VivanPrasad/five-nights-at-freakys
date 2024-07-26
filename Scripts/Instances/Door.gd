extends Node3D
class_name Door
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var open_sfx: AudioStreamPlayer3D = $Open
@onready var close_sfx: AudioStreamPlayer3D = $Close

var is_open : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

@rpc("any_peer","call_local")
func toggle_door() -> void:
	if not animation_player.is_playing():
		is_open = !is_open
		if !is_open:
			animation_player.play_backwards("Open")
			await animation_player.animation_finished
			close_sfx.play()
		else:
			animation_player.play("Open")
			open_sfx.play()
