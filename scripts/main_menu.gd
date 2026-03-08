extends Control

func _ready() -> void:
	$VBoxContainer/Button3.pressed.connect(_on_shoppe_pressed)
	$VBoxContainer/Button4.pressed.connect(_on_quit_pressed)
	$VBoxContainer/Button2.pressed.connect(_on_play_pressed)
	$VBoxContainer/Button5.pressed.connect(_on_multiplayer_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/soccer.tscn")

func _on_multiplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_shoppe_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/betting.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
