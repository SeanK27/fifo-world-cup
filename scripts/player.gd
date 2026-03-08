extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const MAX_SPEED = 150.0 # max magnitude of player 
const ACCELERATION_FACTOR = 17.0 #multiplier for direction added to current vel
const TURNARROUND_FACTOR = 100 #multiplier for direction when trying to turn arround
const FRICTION = 0.85 #fraction decrease each frame when no controlls are held
const PLAYER_FRICTION = 0.1 #fraction of the ball direction that comes from the player's direction and velocity

var blue_sprites = [1, 2]
var red_sprites = [3 ,4]

var spritenum = "1"

func _ready():
	randomize()
	
	if get_meta("player_id") == 1:
		spritenum = str(red_sprites.pick_random())
	else:
		spritenum = str(blue_sprites.pick_random())
		
	$AnimatedSprite2D.play("down"+spritenum)
		
	

# Direct kick (used server-side and in single-player)
func kick_ball(ball: RigidBody2D) -> void:
	var direction = ((ball.global_position - global_position).normalized()*(1-PLAYER_FRICTION) 
					+ velocity*(PLAYER_FRICTION)).normalized()
	# print("kick in direction:", direction, " ball pos:", ball.global_position,"player pos:", global_position)
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

	#if no input was pressed, apply friction
	if input_vector == Vector2.ZERO:
		velocity *= FRICTION
		
	# otherwise, add the current inputs direction scaled by the acceleration factor
	else:
		if (velocity + input_vector.normalized() * TURNARROUND_FACTOR).length() < velocity.length():
			velocity += input_vector.normalized() * TURNARROUND_FACTOR
		else:
			velocity += input_vector.normalized() * ACCELERATION_FACTOR
		
	# clamp to max speed
	velocity = velocity.limit_length(MAX_SPEED)
	
	var anim = "down"+spritenum
	var flip = false
	if velocity.length() > 0:
		if abs(velocity.x) > abs(velocity.y):
			flip = velocity.x > 0
			anim = "left"+spritenum
		else:
			if velocity.y > 0:
				anim = "down"+spritenum
			else:
				anim = "up"+spritenum
	sprite.flip_h = flip
	sprite.play(anim)
	
	if multiplayer.has_multiplayer_peer():
		_sync_animation.rpc(anim, flip)
		
			
	
	move_and_slide()

	# Broadcast position to all remote peers
	if multiplayer.has_multiplayer_peer():
		_sync_position.rpc(global_position)


# Receives authoritative position updates from the controlling peer
@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector2) -> void:
	if not is_multiplayer_authority():
		global_position = pos

@rpc("any_peer", "unreliable")
func _sync_animation(anim: String, flip: bool) -> void:
	if is_multiplayer_authority():
		return
	sprite.flip_h = flip
	sprite.play(anim)
