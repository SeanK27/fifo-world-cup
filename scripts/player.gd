extends CharacterBody2D


const SPEED = 300.0

func _ready() -> void:
	set_multiplayer_authority(name.to_int())
	var sync = $MultiplayerSynchronizer
	sync.set_multiplayer_authority(name.to_int())

#func _enter_tree() -> void:
	#set_multiplayer_authority(name.to_int())


# handle collision with ball objects
func kick_ball(ball):
	var direction  = (ball.global_position - global_position).normalized() # get direction from player to ball
	ball.linear_velocity = direction * 400
	

func _on_kick_area_body_entered(body):
	if body.name == "Ball":
		kick_ball(body)

func _physics_process(delta: float) -> void:
	
	if not is_multiplayer_authority(): return
	
	var input_vector =  Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")

	velocity = input_vector.normalized() * SPEED
	
	move_and_slide()
	
	
