extends Node2D

# Center of the field — used to reset the ball after a goal
const BALL_RESET_POSITION := Vector2(0, -5)

var score_left: int = 0
var score_right: int = 0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_go_to_main_menu()
	_relay_spectator_state()

func _relay_spectator_state() -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	if NetworkManager.spectator_peer_id == 0:
		return
	NetworkManager._relay_spectator_game_state.rpc_id(
		NetworkManager.spectator_peer_id,
		$Player1.global_position,
		$Player2.global_position,
		$Ball.global_position
	)

func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _ready() -> void:
	if not multiplayer.has_multiplayer_peer():
		# Local / single-player mode: remove Player2 so only one player is active
		$Player2.queue_free()
		return

	# Give the client 150 ms to finish loading the scene before sending RPCs
	await get_tree().create_timer(0.15).timeout
	if multiplayer.is_server():
		_assign_authorities.rpc(NetworkManager.player2_peer_id)
		# Listen for any peer that joins while the game is already running (spectator)
		multiplayer.peer_connected.connect(_on_spectator_joined)
		# If a spectator connected during the lobby phase, route them now
		if NetworkManager.spectator_peer_id != 0:
			NetworkManager._send_spectator_to_betting.rpc_id(NetworkManager.spectator_peer_id)

# Runs on EVERY peer so each machine applies the same authority mapping
@rpc("authority", "call_local", "reliable")
func _assign_authorities(client_peer_id: int) -> void:
	$Player1.set_multiplayer_authority(1)             # host always controls Player1
	$Player2.set_multiplayer_authority(client_peer_id) # client controls Player2

func _setup_cameras() -> void:
	var local_id := multiplayer.get_unique_id()
	# Enable camera only for the player this peer controls
	$Player1/Camera2D.enabled = ($Player1.get_multiplayer_authority() == local_id)
	$Player2/Camera2D.enabled = ($Player2.get_multiplayer_authority() == local_id)
	$Player1/AnimatedSprite

# Called when a peer connects while the game is already running — must be spectator
func _on_spectator_joined(peer_id: int) -> void:
	NetworkManager.spectator_peer_id = peer_id
	NetworkManager._send_spectator_to_betting.rpc_id(peer_id)

func _update_score_display() -> void:
	$HUD/ScoreLeft.text = str(score_left)
	$HUD/ScoreRight.text = str(score_right)	
	
# ── Goal handlers (wired in soccer.tscn) ──────────────────────────────────────

func _on_left_goal_body_entered(body: Node2D) -> void:
	if body.name == "Ball":
		score_right += 1
		print("Score — Left: %d  Right: %d" % [score_left, score_right])
		_relay_score_to_spectator()
		_update_score_display()
		_reset_ball()

func _on_right_goal_body_entered(body: Node2D) -> void:
	if body.name == "Ball":
		score_left += 1
		print("Score — Left: %d  Right: %d" % [score_left, score_right])
		_relay_score_to_spectator()
		_update_score_display()
		_reset_ball()

func _relay_score_to_spectator() -> void:
	if not multiplayer.has_multiplayer_peer() or not multiplayer.is_server():
		return
	if NetworkManager.spectator_peer_id == 0:
		return
	NetworkManager._relay_spectator_score.rpc_id(
		NetworkManager.spectator_peer_id,
		score_left,
		score_right
	)

func _reset_ball() -> void:
	# Only authoritative side triggers resets; clients receive the new state via sync
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	$Ball.request_reset(BALL_RESET_POSITION)
