extends Control

const STARTING_CURRENCY := 1000

const SHOP_PRICES := {"Speed":   [100, 300, 600], "Damage":  [100, 300, 600], "Stamina": [100, 300, 600],}
const STAKE_AMOUNTS := [50, 100, 250]

@onready var currency_label: Label = $"MarginContainer/VBoxContainer/Bet Menu Title/Label2"
@onready var spectate_viewport: SubViewport = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/SpectateContainer/Spectate"
@onready var shop_player_upgrades: HBoxContainer = $"MarginContainer/VBoxContainer/Tab Switcher/Upgrade Shop/Player vs Other Upgrades/Player Upgrades"
@onready var score_label: Label = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options/ScoreLabel"
@onready var p1_bet_btn: Button = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options/BetRow/P1BetButton"
@onready var p2_bet_btn: Button = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options/BetRow/P2BetButton"
@onready var active_bet_label: Label = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options/ActiveBetLabel"
@onready var live_result_label: Label = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options/LiveResultLabel"
@onready var quick_result_label: Label = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options/QuickResultLabel"

var stake_btns: Array[Button] = []
var active_bet_player: int = 0
var active_bet_amount: int = 0
var active_bet_odds: float = 0.0
var selected_stake: int = 50
var current_score_left: int = 0
var current_score_right: int = 0

func _ready() -> void:
	NetworkManager.spectator_currency = STARTING_CURRENCY
	_update_currency_display()
	$MenuButton.pressed.connect(_on_menu_pressed)
	p1_bet_btn.pressed.connect(_on_live_bet_pressed.bind(1))
	p2_bet_btn.pressed.connect(_on_live_bet_pressed.bind(2))
	var stake_row: HBoxContainer = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options/StakeRow"
	for i in range(STAKE_AMOUNTS.size()):
		var btn: Button = stake_row.get_child(i)
		stake_btns.append(btn)
		btn.toggled.connect(_on_stake_toggled.bind(STAKE_AMOUNTS[i], btn))
	var go := $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options"
	go.get_node("CoinFlip50").pressed.connect(_on_coinflip_pressed.bind(50))
	go.get_node("CoinFlip100").pressed.connect(_on_coinflip_pressed.bind(100))
	go.get_node("CoinFlip250").pressed.connect(_on_coinflip_pressed.bind(250))
	_update_bet_buttons()
	_setup_shop_buttons()
	NetworkManager.spectator_score_updated.connect(_on_spectator_score_updated)
	if NetworkManager.is_spectator:
		_setup_spectator_view()

# Currency helpers

func _update_currency_display() -> void:
	currency_label.text = "$%d" % NetworkManager.spectator_currency

func _try_spend(amount: int) -> bool:
	if NetworkManager.spectator_currency < amount:
		_show_quick_result("Not enough money!", Color(1.0, 0.4, 0.4, 1))
		return false
	NetworkManager.spectator_currency -= amount
	_update_currency_display()
	return true

func _show_quick_result(message: String, color: Color = Color.WHITE) -> void:
	quick_result_label.text = message
	quick_result_label.add_theme_color_override("font_color", color)

# Gambling

func _calculate_odds(for_player: int) -> float:
	var gap := absi(current_score_left - current_score_right)
	if gap == 0:
		return 2.0
	var leading := 1 if current_score_left > current_score_right else 2
	return maxf(1.2, 2.0 - gap * 0.25) if for_player == leading else minf(10.0, 2.0 + gap * 1.5)

func _update_bet_buttons() -> void:
	p1_bet_btn.text = "P1  %.1fx" % _calculate_odds(1)
	p2_bet_btn.text = "P2  %.1fx" % _calculate_odds(2)
	p1_bet_btn.disabled = active_bet_player != 0
	p2_bet_btn.disabled = active_bet_player != 0

func _on_live_bet_pressed(player: int) -> void:
	if active_bet_player != 0:
		return
	if not _try_spend(selected_stake):
		return
	active_bet_player = player
	active_bet_amount = selected_stake
	active_bet_odds = _calculate_odds(player)
	active_bet_label.text = "$%d on P%d @%.1fx  →  wins $%d" % [
		active_bet_amount, active_bet_player, active_bet_odds,
		int(active_bet_amount * active_bet_odds)
	]
	live_result_label.text = ""
	_update_bet_buttons()

func _on_spectator_score_updated(score_left: int, score_right: int) -> void:
	var scorer := 0
	if score_left > current_score_left:
		scorer = 1
	elif score_right > current_score_right:
		scorer = 2
	current_score_left = score_left
	current_score_right = score_right
	score_label.text = "P1: %d  —  P2: %d" % [current_score_left, current_score_right]
	if active_bet_player != 0 and scorer != 0:
		if scorer == active_bet_player:
			var winnings := int(active_bet_amount * active_bet_odds)
			NetworkManager.spectator_currency += winnings
			_update_currency_display()
			live_result_label.text = "Won! +$%d" % winnings
			live_result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1))
		else:
			live_result_label.text = "Lost! -$%d" % active_bet_amount
			live_result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
		active_bet_player = 0
		active_bet_amount = 0
		active_bet_odds = 0.0
		active_bet_label.text = "No active bet"
	_update_bet_buttons()

func _on_stake_toggled(is_on: bool, amount: int, pressed_btn: Button) -> void:
	if not is_on:
		return
	selected_stake = amount
	for s_btn: Button in stake_btns:
		s_btn.set_pressed_no_signal(s_btn == pressed_btn)

func _on_coinflip_pressed(amount: int) -> void:
	if not _try_spend(amount):
		return
	if randi() % 2 == 0:
		NetworkManager.spectator_currency += amount * 2
		_show_quick_result("Won $%d!" % amount, Color(0.2, 1.0, 0.2, 1))
	else:
		_show_quick_result("Lost $%d!" % amount, Color(1.0, 0.3, 0.3, 1))
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
	_show_quick_result("Bought %s Lv%d!" % [category, level], Color(0.2, 1.0, 0.2, 1))
	# TODO: tell server to apply the upgrad to the playr

# Spectator view

func _setup_spectator_view() -> void:
	var soccer_scene = load("res://scenes/soccer.tscn").instantiate()
	spectate_viewport.add_child(soccer_scene)
	soccer_scene.get_node("Player1/Camera2D").enabled = false
	soccer_scene.get_node("Player2/Camera2D").enabled = false
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
