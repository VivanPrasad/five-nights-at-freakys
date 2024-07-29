class_name Game
extends Node3D

# ---- ONREADY ----
@onready var players: Node3D = $Entities/Players
@onready var spawner: MultiplayerSpawner = $Spawner

#@onready var multiplayer_ui: MarginContainer = $UI/MultiplayerUI

@onready var hour_tick: Timer = $HourTick
@onready var power_tick: Timer = $PowerTick

#@onready var code_label: Label = $UI/MultiplayerUI/VBoxContainer/HBoxContainer/CodeLabel
#@onready var player_count_label: Label = $UI/MultiplayerUI/VBoxContainer/HBoxContainer2/PlayerCountLabel
@onready var ui: CanvasLayer = $UI

@onready var office_area: Area3D = $Office/OfficeArea

@onready var office_amb: AudioStreamPlayer3D = $Office/OfficeAmb
@onready var office_bulb: OmniLight3D = $Office/OfficeBulb
@onready var office_light: OmniLight3D = $Office/OfficeLight

const PLAYER_SCENE = preload("res://Scenes/Instances/Player.tscn")
const MULTI_HUD = preload("res://Scenes/Menus/MultiHUD.tscn")
const COMPLETE_SCENE = preload("res://Scenes/UI/CompleteScene.tscn")
# --- Game Data ---

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

static var player : Player ## The local player

var player_count : int = 0 ## Player Count

## Initialize game
func _ready() -> void:
	connect_office()
	# --- Solo ---
	if not Multi.is_multi or Multi.is_host:
		hour_tick.start()
		power_tick.start()
		add_player()
		return
	# --- Multiplayer ---
	Multi.setup_game()
	if Multi.is_host:
		power_tick.start()
		hour_tick.start()

func connect_office() -> void:
	#multiplayer_ui.visible = Multi.is_multi
	office_area.body_entered.connect(_on_office_entered)
	office_area.body_exited.connect(_on_office_exited)

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
	if not Multi.is_multi or Multi.is_host:
		power -= (delta * clamp(usage,1,5) * 0.09)
	# Invariant Condition Updates
	if int(floor(power)) < 1 and has_power:
		power_outage()
	elif hour == 6 and not complete:
		game_complete()
	# Multiplayer Updates
	if not Global.is_multi: return
	player_count = players.get_child_count()
	#player_count_label.text = "%s/%s" % [Multi.player_count,Multi.MAX_PLAYERS]
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
	#outage_sfx.play()
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
	ui.add_child(COMPLETE_SCENE.instantiate())
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
	Multi.peer.close()
	get_tree().change_scene_to_file("res://Scenes/Menus/Title.tscn")
