extends Node3D
class_name Wing

@onready var door_sfx: AudioStreamPlayer3D = $DoorSFX
@onready var light_sfx: AudioStreamPlayer3D = $LightSFX

@onready var door_animation: AnimationPlayer = $AnimationPlayer
@onready var light_animation: AnimationPlayer = $AnimationPlayer2

@onready var game : Game = $"/root/Game"
@rpc("any_peer","call_local")
func toggle_door() -> void:
	if not can_toggle(): return 
	if not door_animation.is_playing():
		var state = Game.doors[get_index()]
		Game.doors[get_index()] = !state # On -> Off
		door_sfx.play()
		if state: #Off
			if multiplayer.is_server():
				game.rpc("update_usage",game.usage - 1)
			door_animation.play_backwards("Door"+str(get_index()))
		else:
			if multiplayer.is_server():
				game.rpc("update_usage",game.usage + 1)
			door_animation.play("Door"+str(get_index()))
@rpc("any_peer","call_local")
func toggle_light() -> void:
	if not Game.has_power: return 
	var i : int = get_index()
	var state = Game.lights[i]
	Game.lights[i] = !state
	if state:
		if multiplayer.is_server():
			game.rpc("update_usage",game.usage - 1)
		light_sfx.stop()
		light_animation.stop()
	else:
		if Game.lights[0] == Game.lights[1]:
			get_other_wing().toggle_light()
		if multiplayer.is_server():
			game.rpc("update_usage",game.usage + 1)
		light_sfx.play()
		light_animation.play("Light"+str(i))
func can_toggle() -> bool:
	return bool(Game.has_power and not Game.player.in_cams
		and Game.player.in_office)
func get_other_wing() -> Wing:
	return get_parent().get_child((get_index() + 1) % 2)
