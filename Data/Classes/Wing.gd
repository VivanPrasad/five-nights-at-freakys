extends Node3D
class_name Wing

@onready var door_sfx: AudioStreamPlayer3D = $DoorSFX
@onready var light_sfx: AudioStreamPlayer3D = $LightSFX

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@rpc("any_peer","call_local")
func toggle_door() -> void:
	if not animation_player.is_playing():
		var state = Game.doors[get_index()]
		Game.doors[get_index()] = !state # On -> Off
		door_sfx.play()
		if state: #Off
			animation_player.play_backwards("Door"+str(get_index()))
		else:
			animation_player.play("Door"+str(get_index()))
@rpc("any_peer","call_local")
func toggle_light() -> void:
	var state = Game.lights[get_index()]
	
	Game.lights[get_index()] = !state
	if state:
		light_sfx.stop()
		animation_player.stop()
	else:
		light_sfx.play()
		animation_player.play("Light"+str(get_index()))
	
