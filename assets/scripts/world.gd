extends Node3D

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const Player = preload("res://assets/prefabs/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()
var players = []

var started = false

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _process(delta):
	if started: return
	
	if (players.size() > 1): 
		players[0].set_infectation.rpc(true)
		print(players[0].infected)
		started = true
	

func _on_host_button_pressed():
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	# upnp_setup()

func _on_join_button_pressed():
	main_menu.hide()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	players.push_back(player)
	add_child(player)
	

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	players.remove_at(players.find(player))
	if player:
		player.queue_free()	
		
func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
