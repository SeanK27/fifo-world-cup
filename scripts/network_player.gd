extends CharacterBody2D

const SPEED: float = 500.0

func _ready() -> void:
	set_multiplayer_authority(name.to_int())
	var sync = $MultiplayerSynchronizer
	sync.set_multiplayer_authority(name.to_int())

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED

	move_and_slide()
