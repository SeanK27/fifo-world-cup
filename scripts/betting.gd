extends Control

const STARTING_CURRENCY := 1000
const PIXEL_FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")

# Prices per upgrade category (index 0 = Level 1, 1 = Level 2, 2 = Level 3)
const SHOP_PRICES := {"Speed":   [100, 300, 600], "Damage":  [100, 300, 600], "Stamina": [100, 300, 600],
}

const GAMBLE_AMOUNTS := [50, 100, 250]

@onready var spectate_viewport: SubViewport = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/SpectateContainer/Spectate"
@onready var currency_label: Label = $"MarginContainer/VBoxContainer/Bet Menu Title/Label2"
@onready var gambling_options: VBoxContainer = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options"
@onready var shop_player_upgrades: HBoxContainer = $"MarginContainer/VBoxContainer/Tab Switcher/Upgrade Shop/Player vs Other Upgrades/Player Upgrades"

var result_label: Label

func _ready() -> void:
	NetworkManager.spectator_currency = STARTING_CURRENCY
	_update_currency_display()
	$MenuButton.pressed.connect(_on_menu_pressed)
	_setup_gambling_ui()
	_setup_shop_buttons()
	if NetworkManager.is_spectator:
		_setup_spectator_view()

# Currency helpers

func _update_currency_display() -> void:
	currency_label.text = "$%d" % NetworkManager.spectator_currency

func _try_spend(amount: int) -> bool:
	if NetworkManager.spectator_currency < amount:
		_show_result("Not enough money!", Color(1.0, 0.4, 0.4, 1))
		return false
	NetworkManager.spectator_currency -= amount
	_update_currency_display()
	return true

func _show_result(message: String, color: Color = Color.WHITE) -> void:
	if result_label:
		result_label.text = message
		result_label.add_theme_color_override("font_color", color)

# Gambling

func _setup_gambling_ui() -> void:
	var header := Label.new()
	header.text = "── Coin Flip ──"
	header.add_theme_font_override("font", PIXEL_FONT)
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(1, 0.88, 0.1, 1))
	gambling_options.add_child(header)

	for amount: int in GAMBLE_AMOUNTS:
		var btn := Button.new()
		btn.text = "Bet $%d" % amount
		btn.custom_minimum_size = Vector2(180, 60)
		btn.add_theme_font_override("font", PIXEL_FONT)
		btn.add_theme_font_size_override("font_size", 26)
		btn.pressed.connect(_on_gamble_pressed.bind(amount))
		gambling_options.add_child(btn)

	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(180, 0)
	result_label.add_theme_font_override("font", PIXEL_FONT)
	result_label.add_theme_font_size_override("font_size", 26)
	result_label.add_theme_color_override("font_color", Color.WHITE)
	gambling_options.add_child(result_label)

func _on_gamble_pressed(amount: int) -> void:
	if not _try_spend(amount):
		return
	if randi() % 2 == 0:
		NetworkManager.spectator_currency += amount * 2
		_show_result("Won $%d!" % amount, Color(0.2, 1.0, 0.2, 1))
	else:
		_show_result("Lost $%d!" % amount, Color(1.0, 0.3, 0.3, 1))
	_update_currency_display()

# Shop

func _setup_shop_buttons() -> void:
	for category: String in SHOP_PRICES.keys():
		var category_node := shop_player_upgrades.get_node(category)
		var prices: Array = SHOP_PRICES[category]
		for i in range(prices.size()):
			var level := i + 1
			var price: int = prices[i]
			var btn: Button = category_node.get_node("Level %d" % level)
			btn.text = "Lv%d  $%d" % [level, price]
			btn.pressed.connect(_on_shop_pressed.bind(category, level, price, btn))

func _on_shop_pressed(category: String, level: int, price: int, btn: Button) -> void:
	if not _try_spend(price):
		return
	btn.disabled = true
	btn.text = "Lv%d ✓" % level
	_show_result("Bought %s Lv%d!" % [category, level], Color(0.2, 1.0, 0.2, 1))
	# TODO: tell server to apply the upgrad to the playr

# ── Spectator view ────────────────────────────────────────────────────────────

func _setup_spectator_view() -> void:
	var soccer_scene = load("res://scenes/soccer.tscn").instantiate()
	spectate_viewport.add_child(soccer_scene)
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
