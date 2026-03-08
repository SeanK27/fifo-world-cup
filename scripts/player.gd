extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


# Direct kick (used server-side and in single-player)
func kick_ball(ball: RigidBody2D) -> void:
	var direction := (ball.global_position - global_position).normalized()
	ball.kick(direction)  # routes through _integrate_forces so physics can't overwrite it


func _on_kick_area_body_entered(body: Node2D) -> void:
	if body.name != "Ball":
		return
	# Only the authoritative peer for this player initiates a kick
	if not is_multiplayer_authority():
		return
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		kick_ball(body)
	else:
		# Client: request the server to apply the kick on the authoritative ball
		var direction := (body.global_position - global_position).normalized()
		body.kick.rpc_id(1, direction)


func _physics_process(_delta: float) -> void:
	# Only the controlling peer processes input for this player
	if not is_multiplayer_authority():
		return

	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	velocity = input_vector.normalized() * SPEED
	move_and_slide()

	# Broadcast position to all remote peers
	if multiplayer.has_multiplayer_peer():
		_sync_position.rpc(global_position)


# Receives authoritative position updates from the controlling peer
@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector2) -> void:
	if not is_multiplayer_authority():
		global_position = pos
