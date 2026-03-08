extends Control

@onready var spectate_viewport: SubViewport = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/SpectateContainer/Spectate"

func _ready() -> void:
	$MenuButton.pressed.connect(_on_menu_pressed)
	if NetworkManager.is_spectator:
		_setup_spectator_view()

func _setup_spectator_view() -> void:
	var soccer_scene = load("res://scenes/soccer.tscn").instantiate()
	spectate_viewport.add_child(soccer_scene)
	# Player1's follow-camera would scroll away; use the static overview camera instead
	soccer_scene.get_node("Player1/Camera2D").enabled = false
	soccer_scene.get_node("Camera2D").make_current()
	NetworkManager.spectator_state_updated.connect(_on_spectator_state_updated)

func _on_spectator_state_updated(p1_pos: Vector2, p2_pos: Vector2, ball_pos: Vector2) -> void:
	if spectate_viewport.get_child_count() == 0:
		return
	var soccer = spectate_viewport.get_child(0)
	soccer.get_node("Player1").global_position = p1_pos
	soccer.get_node("Player2").global_position = p2_pos
	soccer.get_node("Ball").global_position = ball_pos

func _on_menu_pressed() -> void:
	NetworkManager.disconnect_network()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
