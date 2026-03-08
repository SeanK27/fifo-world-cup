extends Control

const STARTING_CURRENCY := 1000
const PIXEL_FONT = preload("res://assets/fonts/PixelOperator8-Bold.ttf")

const SHOP_PRICES := {"Speed":   [100, 300, 600], "Damage":  [100, 300, 600], "Stamina": [100, 300, 600],
}

const STAKE_AMOUNTS := [50, 100, 250]

@onready var spectate_viewport: SubViewport = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/SpectateContainer/Spectate"
@onready var currency_label: Label = $"MarginContainer/VBoxContainer/Bet Menu Title/Label2"
@onready var gambling_options: VBoxContainer = $"MarginContainer/VBoxContainer/Tab Switcher/Watch and Gamble/HBoxContainer/Gambling Options"
@onready var shop_player_upgrades: HBoxContainer = $"MarginContainer/VBoxContainer/Tab Switcher/Upgrade Shop/Player vs Other Upgrades/Player Upgrades"

# Live betting vars
var active_bet_player: int = 0   # 0=none  1=P1  2=P2
var active_bet_amount: int = 0
var active_bet_odds: float = 0.0
var selected_stake: int = 50
var current_score_left: int = 0
var current_score_right: int = 0

var score_label: Label
var p1_bet_btn: Button
var p2_bet_btn: Button
var active_bet_label: Label
var live_result_label: Label
var stake_btns: Array[Button] = []
var quick_result_label: Label

func _ready() -> void:
	NetworkManager.spectator_currency = STARTING_CURRENCY
	_update_currency_display()
	$MenuButton.pressed.connect(_on_menu_pressed)
	_setup_gambling_ui()
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
	if quick_result_label:
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
	#  who scored this update
	var scorer := 0
	if score_left > current_score_left:
		scorer = 1
	elif score_right > current_score_right:
		scorer = 2
	current_score_left = score_left
	current_score_right = score_right
	score_label.text = "P1: %d  —  P2: %d" % [current_score_left, current_score_right]

	# Resolve active bet
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

# Gambling UI

func _make_label(text_val: String, size: int = 28, color: Color = Color(1, 0.88, 0.1, 1)) -> Label:
	var lbl := Label.new()
	lbl.text = text_val
	lbl.add_theme_font_override("font", PIXEL_FONT)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _setup_gambling_ui() -> void:
	# Live betings
	gambling_options.add_child(_make_label("── Live Betting ──", 30))

	score_label = _make_label("P1: 0  —  P2: 0", 26, Color.WHITE)
	gambling_options.add_child(score_label)

	gambling_options.add_child(_make_label("Stake:", 24))

	var stake_row := HBoxContainer.new()
	stake_row.add_theme_constant_override("separation", 8)
	for amount: int in STAKE_AMOUNTS:
		var s_btn := Button.new()
		s_btn.text = "$%d" % amount
		s_btn.custom_minimum_size = Vector2(80, 50)
		s_btn.add_theme_font_override("font", PIXEL_FONT)
		s_btn.add_theme_font_size_override("font_size", 22)
		s_btn.toggle_mode = true
		s_btn.button_pressed = (amount == selected_stake)
		s_btn.toggled.connect(_on_stake_toggled.bind(amount, s_btn))
		stake_row.add_child(s_btn)
		stake_btns.append(s_btn)
	gambling_options.add_child(stake_row)

	var bet_row := HBoxContainer.new()
	bet_row.add_theme_constant_override("separation", 10)
	p1_bet_btn = Button.new()
	p1_bet_btn.custom_minimum_size = Vector2(130, 60)
	p1_bet_btn.add_theme_font_override("font", PIXEL_FONT)
	p1_bet_btn.add_theme_font_size_override("font_size", 22)
	p1_bet_btn.pressed.connect(_on_live_bet_pressed.bind(1))
	bet_row.add_child(p1_bet_btn)
	p2_bet_btn = Button.new()
	p2_bet_btn.custom_minimum_size = Vector2(130, 60)
	p2_bet_btn.add_theme_font_override("font", PIXEL_FONT)
	p2_bet_btn.add_theme_font_size_override("font_size", 22)
	p2_bet_btn.pressed.connect(_on_live_bet_pressed.bind(2))
	bet_row.add_child(p2_bet_btn)
	gambling_options.add_child(bet_row)
	_update_bet_buttons()

	active_bet_label = _make_label("No active bet", 22, Color(0.8, 0.8, 0.8, 1))
	gambling_options.add_child(active_bet_label)

	live_result_label = _make_label("", 24, Color.WHITE)
	gambling_options.add_child(live_result_label)

	# Quick cash (huge scam)
	var sep := HSeparator.new()
	gambling_options.add_child(sep)

	gambling_options.add_child(_make_label("── Quick Cash ──", 30))
	gambling_options.add_child(_make_label("Coin Flip:", 24))

	for amount: int in STAKE_AMOUNTS:
		var btn := Button.new()
		btn.text = "Flip $%d" % amount
		btn.custom_minimum_size = Vector2(150, 56)
		btn.add_theme_font_override("font", PIXEL_FONT)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_coinflip_pressed.bind(amount))
		gambling_options.add_child(btn)

	quick_result_label = _make_label("", 24, Color.WHITE)
	gambling_options.add_child(quick_result_label)

func _on_stake_toggled(is_on: bool, amount: int, pressed_btn: Button) -> void:
	if not is_on:
		return
	selected_stake = amount
	for s_btn: Button in stake_btns:
		s_btn.set_pressed_no_signal(s_btn == pressed_btn)

# Coinflip mechanics

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
