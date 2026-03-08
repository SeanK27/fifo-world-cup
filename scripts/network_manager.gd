extends Node

const PORT = 7777
const MAX_PLAYERS = 2

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connected_to_server
signal connection_failed

# The ID of the remote peer (for host: the client's ID; for client: 1/host)
var remote_peer_id: int = 0

func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		push_error("NetworkManager: Failed to create server (error %d)" % err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func join_game(ip: String = "127.0.0.1") -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		push_error("NetworkManager: Failed to connect to %s (error %d)" % [ip, err])
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed_enet)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func disconnect_network() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	remote_peer_id = 0

# Called by host — tells all peers (including itself) to load the game scene
func start_game() -> void:
	if multiplayer.is_server():
		_load_game.rpc()

@rpc("authority", "call_local", "reliable")
func _load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/soccer.tscn")

func _on_peer_connected(id: int) -> void:
	remote_peer_id = id
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	remote_peer_id = 1  # host is always peer 1
	connected_to_server.emit()

func _on_connection_failed_enet() -> void:
	connection_failed.emit()
