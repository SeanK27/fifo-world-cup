extends Control

func _ready() -> void:
	$VBoxContainer/HostButton.pressed.connect(_on_host_pressed)
	$VBoxContainer/JoinButton.pressed.connect(_on_join_pressed)
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _on_host_pressed() -> void:
	NetworkManager.host_game()
	_set_status("Hosting on port 7777 — waiting for Player 2...")

func _on_join_pressed() -> void:
	var ip: String = $VBoxContainer/IPLineEdit.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	NetworkManager.join_game(ip)
	_set_status("Connecting to %s" % ip)

func _on_player_connected(_peer_id: int) -> void:
	# Host sees the client join — start the game for both peers
	if multiplayer.is_server():
		_set_status("Player 2 connected. Starting game...")
		NetworkManager.start_game()

func _on_connected_to_server() -> void:
	_set_status("Connected. Waiting for host to start.")

func _on_connection_failed() -> void:
	_set_status("failed")

func _on_back_pressed() -> void:
	NetworkManager.disconnect_network()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _set_status(msg: String) -> void:
	$VBoxContainer/StatusLabel.text = msg
