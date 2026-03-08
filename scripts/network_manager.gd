extends Node

const PORT = 7777
const MAX_PLAYERS = 3

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connected_to_server
signal connection_failed
signal spectator_state_updated(p1_pos: Vector2, p2_pos: Vector2, ball_pos: Vector2)

var remote_peer_id: int = 0
var player2_peer_id: int = 0   # server stores P2's peer ID separately from spectator
var spectator_peer_id: int = 0
var is_spectator: bool = false  # local flag set before joining as spectator

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
	player2_peer_id = 0
	spectator_peer_id = 0
	is_spectator = false

# Called by host — tells all peers (including itself) to load the game scene
func start_game() -> void:
	if multiplayer.is_server():
		_load_game.rpc()

@rpc("authority", "call_local", "reliable")
func _load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/soccer.tscn")

# Spectator client calls this on the server immediately after connecting
@rpc("any_peer", "call_remote", "reliable")
func _register_as_spectator() -> void:
	spectator_peer_id = multiplayer.get_remote_sender_id()

# Server sends spectator client to the betting/spectator scene
@rpc("authority", "call_remote", "reliable")
func _send_spectator_to_betting() -> void:
	get_tree().change_scene_to_file("res://scenes/betting.tscn")

# Server relays live game positions so the spectator's SubViewport can mirror them
@rpc("authority", "call_remote", "unreliable")
func _relay_spectator_game_state(p1_pos: Vector2, p2_pos: Vector2, ball_pos: Vector2) -> void:
	spectator_state_updated.emit(p1_pos, p2_pos, ball_pos)

func _on_peer_connected(id: int) -> void:
	remote_peer_id = id
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	remote_peer_id = 1  # host is always peer 1
	connected_to_server.emit()
	if is_spectator:
		_register_as_spectator.rpc_id(1)

func _on_connection_failed_enet() -> void:
	connection_failed.emit()
