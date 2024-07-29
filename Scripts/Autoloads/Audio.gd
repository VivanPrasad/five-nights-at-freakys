## Audio
extends Node3D

@onready var local_ambience: Node3D = $LocalAmbience
@onready var local_sfx: Node3D = $LocalSFX

@onready var global_ambience: Node = $GlobalAmbience
@onready var global_sfx: Node = $GlobalSFX

@onready var music: Node = $Music

class SFX:
	extends AudioStream

@rpc("any_peer","call_local")
func play_global_sfx() -> void:
	pass

@rpc("any_peer","call_local")
func play_audio(node_name : String):
	var node : AudioStreamPlayer = get_audio(node_name)
	if node: node.play()

func stop_audio(node_name : String):
	var node : AudioStreamPlayer = get_audio(node_name)
	if node: node.stop()

func fade_in(node : Variant,
		volume:float=0.0,duration:float=1.0,
		delay:float=0.0) -> Tween:
	var ref : AudioStreamPlayer
	if node is String:
		ref = get_audio(node)
	else:
		ref = node
	assert(ref)
	ref.volume_db = -80.0
	var tween = create_tween()
	tween\
	.tween_property(ref,"volume_db",volume,duration)\
	.set_delay(delay)
	return tween

func get_audio(node_name : String) -> AudioStreamPlayer:
	return find_child(node_name,true,true)
