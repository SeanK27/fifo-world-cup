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

func _physics_process(delta: float) -> void:
	linear_velocity *= FRICTION
	gravity_scale = 0
