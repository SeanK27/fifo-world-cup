extends RigidBody2D


const FRICTION = 0.9

var _reset_pending := false
var _reset_position := Vector2.ZERO
var _pending_kick := false
var _kick_velocity := Vector2.ZERO


func _ready() -> void:
	gravity_scale = 0
	# On the client the ball is purely a visual; physics are server-authoritative.
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		freeze = true


# All physics mutations happen here so the engine never overwrites them.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _reset_pending:
		state.transform = Transform2D(0.0, _reset_position)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		_reset_pending = false
	elif _pending_kick:
		state.linear_velocity = _kick_velocity
		_pending_kick = false
	else:
		state.linear_velocity *= FRICTION

	# Server broadcasts state to all clients every physics tick
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_sync_ball.rpc(global_position, state.linear_velocity)


# Called by soccer.gd (server/single-player only) after a goal.
func request_reset(pos: Vector2) -> void:
	_reset_pending = true
	_reset_position = pos


# Client receives authoritative ball state from the server.
@rpc("authority", "unreliable")
func _sync_ball(pos: Vector2, vel: Vector2) -> void:
	global_position = pos
	linear_velocity = vel


# Called by clients (via rpc_id(1, ...)) to apply a kick on the server.
@rpc("any_peer", "reliable")
func kick(direction: Vector2) -> void:
	_pending_kick = true
	_kick_velocity = direction * 400
