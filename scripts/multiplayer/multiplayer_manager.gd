extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

func become_host() -> void:
	print("Starting host!")
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	
	multiplayer.multiplayer_peer = server_peer
	
	# detect when a peer connects to your server
	multiplayer.peer_connected.connect(_add_player_to_game)
	# detect and handle disconnection
	multiplayer.peer_disconnected.connect(_del_player)
	
	
func join_as_player_2() -> void:
	print("Player 2 joining!")
	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)
	
func _del_player(id: int):
	print("Player %s left the game!" % id)
	
