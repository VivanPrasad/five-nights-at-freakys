class_name Game
extends Node3D

# ---- ONREADY ----
@onready var players: Node3D = $Entities/Players
@onready var spawner: MultiplayerSpawner = $Spawner

@onready var multiplayer_ui: MarginContainer = $UI/MultiplayerUI

@onready var code_label: Label = $UI/MultiplayerUI/VBoxContainer/HBoxContainer/CodeLabel
@onready var player_count_label: Label = $UI/MultiplayerUI/VBoxContainer/HBoxContainer2/PlayerCountLabel

@onready var office_area: Area3D = $Office/OfficeArea

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
static var usage : int = 1
static var hour : int = 0 #0 = 12AM

## Initialize game
func _ready() -> void:
	setup_game()
	# --- Solo ---
	if is_solo:
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

## Join the game with the given IP
func join_game() -> void:
	code_label.text = Multi.get_code_from_ip(ip)
	peer.create_client(ip,PORT)
	multiplayer.multiplayer_peer = peer
	await get_tree().create_timer(0.1).timeout
	if player_count < 1:
		multiplayer.multiplayer_peer.close()
		get_tree().change_scene_to_file("res://Scenes/UI/Title.tscn")
	
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
func _process(_delta: float) -> void:
	# Player Count Updates
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
