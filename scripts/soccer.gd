extends Node2D

@onready var ball = $Ball
var _resetting := false

func _on_left_goal_body_entered(body: Node2D) -> void:
	if body == ball and not _resetting:
		_reset_ball()

func _on_right_goal_body_entered(body: Node2D) -> void:
	if body == ball and not _resetting:
		_reset_ball()

func _reset_ball() -> void:
	_resetting = true
	ball.teleport(Vector2(0, 0))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_resetting = false
