class_name Game
extends Node3D

# ---- ONREADY ----
@onready var players: Node3D = $Entities/Players
@onready var spawner: MultiplayerSpawner = $Spawner

@onready var multiplayer_ui: MarginContainer = $UI/MultiplayerUI

@onready var hour_tick: Timer = $HourTick
@onready var power_tick: Timer = $PowerTick

@onready var code_label: Label = $UI/MultiplayerUI/VBoxContainer/HBoxContainer/CodeLabel
@onready var player_count_label: Label = $UI/MultiplayerUI/VBoxContainer/HBoxContainer2/PlayerCountLabel

@onready var office_area: Area3D = $Office/OfficeArea

@onready var outage_sfx: AudioStreamPlayer3D = $Office/OutageSFX
@onready var complete_animation: AnimationPlayer = $UI/CompleteScreen/AnimationPlayer

@onready var office_amb: AudioStreamPlayer3D = $Office/OfficeAmb
@onready var office_bulb: OmniLight3D = $Office/OfficeBulb
@onready var office_light: OmniLight3D = $Office/OfficeLight

const PLAYER_SCENE = preload("res://Scenes/Instances/Player.tscn")

static var player_count : int = 0
static var player : Player ## The local player

const PORT : int = 9999

static var is_host : bool = false
static var is_solo : bool = false
## IP of multiplayer game
static var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

static var ip : String ## IP of multiplayer game

const MAX_PLAYERS : int = 5 ## Max players in-game
const MAX_CHANNELS : int = 10

# Game Data

# [Left State, Right State]
static var doors : Array[bool] = [false,false]
static var lights : Array[bool] = [false,false]
static var power : float = 100.50 :
	set(value): power = clamp(value,0.0,100.50)
static var usage : int = 1 :
	set(value): usage = clamp(value,1,5)
static var hour : int = 0 : #0 = 12AM 
	set(value) : hour = clamp(value,0,6)

static var has_power : bool = true # Office Power
static var complete : bool = false # Game Completion

## Initialize game
func _ready() -> void:
	setup_game()
	# --- Solo ---
	if is_solo:
		hour_tick.start()
		power_tick.start()
		add_player()
		return
	# --- Multiplayer ---
	if is_host:
		host_game()
	else:
		join_game()

func setup_game() -> void:
	multiplayer_ui.visible = not is_solo
	office_area.body_entered.connect(_on_office_entered)
	office_area.body_exited.connect(_on_office_exited)

## Host the multiplayer game
func host_game() -> void:
	# UPNP queries take some time.
	var upnp = UPNP.new()
	var result = upnp.discover()
	upnp.discover(2000, 2, "InternetGatewayDevice")
	ip = upnp.query_external_address()
	
	code_label.text = Multi.get_code_from_ip(ip)
	if result != OK:
		push_error("Game::host_game() >> Unable to discover")
		push_error(error_string(result))
		return
	
	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		upnp.add_port_mapping(PORT, PORT, ProjectSettings.get_setting("application/config/name"), "UDP")
		upnp.add_port_mapping(PORT, PORT, ProjectSettings.get_setting("application/config/name"), "TCP")
	else:
		push_error("Game::host_game() >> Unable to get gateway")
		return
	print("Server ready!")
	
	peer.create_server(PORT,MAX_PLAYERS,MAX_CHANNELS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	power_tick.start()
	hour_tick.start()

## Join the game with the given IP
func join_game() -> void:
	code_label.text = Multi.get_code_from_ip(ip)
	peer.create_client(ip,PORT)
	multiplayer.multiplayer_peer = peer
	#peer.get_peer(1).send(1,"hello".to_ascii_buffer(),ENetPacketPeer.FLAG_RELIABLE)
	
## Creates new Player classes to be added into the game
func add_player(id : int = 1) -> void:
	var new_player : Player = PLAYER_SCENE.instantiate()
	new_player.name = str(id)
	players.add_child(new_player)

func remove_player(id : int = 1) -> void:
	players.find_child(str(id)).queue_free()

## Disconnect player
func _player_disconnected(node : Node):
	prints("Player",node.name,"left the game!")

## Game Process
func _process(delta: float) -> void:
	# Power Updates
	if is_solo or is_host:
		power -= (delta * clamp(usage,1,5) * 0.09)
	# Invariant Condition Updates
	if int(floor(power)) < 1 and has_power:
		power_outage()
	elif hour == 6 and not complete:
		game_complete()
	# Multiplayer Updates
	if is_solo: return
	player_count = players.get_child_count()
	player_count_label.text = "%s/%s" % [player_count,MAX_PLAYERS]
# --- OFFICE METHODS ---
func _on_office_entered(body : Node3D):
	if body is Player:
		if body.is_multiplayer_authority():
			body.in_office = true
func _on_office_exited(body : Node3D):
	if body is Player:
		if body.is_multiplayer_authority():
			body.in_office = false

# ----- Game Events -----

func power_outage() -> void:
	var office_node := $Office
	office_light.hide()
	office_bulb.hide()
	office_amb.stop()
	player.horror_amb.stop()
	player.bass_amb.stop()
	outage_sfx.play()
	usage = 1
	for i in [0,1]:
		var wing : Wing = office_node.get_child(i)
		wing.light_sfx.stop()
		wing.light_animation.stop()
		wing.door_animation.stop()
		if doors[i]:
			wing.door_animation.play_backwards("Door"+str(i))
			wing.door_sfx.play()
	if player.in_cams:
		player.cam_animation.stop()
		player.cam_animation.play_backwards("OpenCam")
		player.cam_open.stop()
		player.cam_close.play()
		player.in_cams = false
		player.camera_hud.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.camera.current = true
	has_power = false

func game_complete() -> void:
	get_tree().paused = true
	complete_animation.play("Complete")
	complete = true

# ------------- Multiplayer Stuff -------------

@rpc("any_peer","call_local")
static func update_cam_usage(new_value:int) -> void:
	usage = new_value
	player.usage_hud.frame = clamp(usage,1,5) - 1

@rpc("authority","call_local")
static func update_usage(new_value:int) -> void:
	usage = new_value
	player.usage_hud.frame = clamp(usage,1,5) - 1

@rpc("authority","call_local")
static func update_power(new_value:float) -> void:
	power = new_value
	player.power_hud.text = str(int(floor(power))) + "%"
	
@rpc("authority","call_local")
static func update_hour(new_value:int) -> void:
	hour = new_value
	player.hour_hud.text = str(hour)

func _on_power_tick_timeout() -> void:
	rpc("update_power",power)

func _on_hour_tick_timeout() -> void:
	hour += 1
	rpc("update_hour",hour)
	if hour < 6: hour_tick.start()

func return_to_menu() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	power = 100
	hour = 0
	usage = 1
	complete = false
	has_power = true
	doors = [false,false]
	lights = [false,false]
	for d : Door in $Doors.get_children():
		d.is_open = false
	peer.close()
	get_tree().change_scene_to_file("res://Scenes/Menus/Title.tscn")
