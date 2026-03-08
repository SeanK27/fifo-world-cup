extends Node

func become_host() -> void:
	print("become host pressed")
	%MultiplayerHUD.hide()
	MultiplayerManager.become_host()
	
func join_as_player_2() -> void:
	print("join as player 2 pressed")
	%MultiplayerHUD.hide()
	MultiplayerManager.join_as_player_2()
