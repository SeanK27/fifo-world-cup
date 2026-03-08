extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var player_id := 1:
	# when we have any peer except server, need to set
	set(id):
		player_id = id

# handle collision with ball objects
func kick_ball(ball):
	var direction  = (ball.global_position - global_position).normalized() # get direction from player to ball
	ball.linear_velocity = direction * 400
	

func _on_kick_area_body_entered(body):
	if body.name == "Ball":
		kick_ball(body)

func _physics_process(_delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
		# velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	var input_vector =  Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)

	velocity = input_vector.normalized() * SPEED
	
	move_and_slide()
