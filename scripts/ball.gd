extends RigidBody2D


# Called when the node enters the scene tree for the first time.
#func _ready():
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

const FRICTION = 0.9

var teleport_requested := false
var teleport_position := Vector2.ZERO

func teleport(pos: Vector2) -> void:
	teleport_position = pos
	teleport_requested = true

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if teleport_requested:
		state.transform = Transform2D(0, teleport_position)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		teleport_requested = false

func _physics_process(_delta: float) -> void:
	linear_velocity *= FRICTION
	gravity_scale = 0
