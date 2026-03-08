extends MultiplayerSpawner

@export var player: PackedScene

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)
	
func spawn_player(id: int) -> void:
	if not multiplayer.is_server(): return
	
	var new_player: Node = player.instantiate()
	new_player.name = str(id)
	
	get_node(spawn_path).call_deferred("add_child", player)
