## Multi
extends Node

const MAX_PLAYERS : int = 5 ## Max players in-game
const MAX_CHANNELS : int = 10

const PORT : int = 9999
const LOCAL_IP : String = "127.0.0.1"
var ip : String = LOCAL_IP ## IP of multiplayer game
var ip_code : String = get_code_from_ip(ip)

var is_multi : bool = false
var is_host : bool = false

## IP of multiplayer game
var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

# ---------------------------------------------------------
## Get shifted value from time
func get_shift_value() -> int:
	var time : Dictionary = Time.get_datetime_dict_from_system(true)
	var shift_value : int = abs(
		time["day"] + time["month"] - time["hour"])
	return shift_value

## Returns code from a given IP
func get_code_from_ip(ip_text:String) -> String:
	var values = ip_text.split(".")
	var code_color : Color = Color(
		float((values[0].to_int()+get_shift_value()) / 255.0),
		float((values[1].to_int()+get_shift_value()) / 255.0),
		float((values[2].to_int()+get_shift_value()) / 255.0),
		float((values[3].to_int()+get_shift_value()) / 255.0)
	)
	var ciphered = code_color.to_html()
	return ciphered

## Returns IP from a given code
func get_ip_from_code(code : String) -> String:
	var code_color = Color(code.to_lower())
	var code_arr = [
		int(code_color.r*255.0-(get_shift_value())),
		int(code_color.g*255.0-(get_shift_value())),
		int(code_color.b*255.0-(get_shift_value())),
		int(code_color.a*255.0-(get_shift_value()))
	]
	var deciphered = ".".join(code_arr)
	return deciphered
# ---------------------------------------------------------

func setup_game() -> void:
	if is_host:
		host_game()
	else:
		join_game()

## Host the multiplayer game
func host_game() -> void:
	# UPNP queries take some time.
	var upnp = UPNP.new()
	var result = upnp.discover()
	upnp.discover(2000, 2, "InternetGatewayDevice")
	ip = upnp.query_external_address()
	
	$"/root/Game".code_label.text = get_code_from_ip(ip)
	if result != OK:
		push_error("Multi::host_game() >> Unable to discover")
		push_error(error_string(result))
		return
	
	if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		upnp.add_port_mapping(PORT, PORT, ProjectSettings.get_setting("application/config/name"), "UDP")
		upnp.add_port_mapping(PORT, PORT, ProjectSettings.get_setting("application/config/name"), "TCP")
	else:
		push_error("Multi::host_game() >> Unable to get gateway")
		return
	print("Server ready!")
	
	peer.create_server(PORT,MAX_PLAYERS,MAX_CHANNELS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect($"/root/Game".add_player)
	$"/root/Game".add_player()

## Join the game with the given IP
func join_game() -> void:
	$"/root/Game".code_label.text = ip_code
	peer.create_client(ip,PORT)
	multiplayer.multiplayer_peer = peer
	#peer.get_peer(1).send(1,"hello".to_ascii_buffer(),ENetPacketPeer.FLAG_RELIABLE)
	
func get_code_expiry() -> int:
	var time : Dictionary = Time.get_datetime_dict_from_system(true)
	var min_left : int = 60 - time["minute"]
	return min_left
