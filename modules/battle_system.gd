# res://modules/battle_system.gd
extends Panel

enum BattleType { PVE, PVP, PARTY, GROUP }

signal battle_finished(victory, rewards)

# === ПЕРЕМЕННЫЕ ===
var close_btn
var battle_timer = null
var time_left = 30
var player_attack_choice = null
var player_block_choice = null
var is_player_turn = true

var player_data = {}
var enemy_data = {}
var battle_active = true
var battle_type = BattleType.PVE
var party_members = []
var enemy_party = []
var current_attacker_index = 0
var battle_context = {}

var attack_buttons = {}
var block_buttons = {}
var total_damage_dealt = 0

# === УЗЛЫ ===
var player_hp_label
var player_mana_label
var player_strength_label
var player_agility_label
var player_defense_label
var player_attack_label
var player_name_label

var enemy_hp_label
var enemy_strength_label
var enemy_agility_label
var enemy_defense_label
var enemy_attack_label
var enemy_name_label

var party_players_container
var enemy_party_container
var log_container
var attack_btn
var reset_btn
var timer_label
var damage_counter_label
var main_scroll
var result_popup = null

const COLOR_SELECTED_ATTACK = Color(0.8, 0.3, 0.3, 1)
const COLOR_SELECTED_BLOCK = Color(0.3, 0.3, 0.8, 1)

# === 5 ЧАСТЕЙ ТЕЛА ДЛЯ АТАКИ ===
var attack_parts = {
	"head": {"name": "ГОЛОВА", "bonus": 1.15},
	"chest": {"name": "ГРУДЬ", "bonus": 1.0},
	"belly": {"name": "ЖИВОТ", "bonus": 1.05},
	"groin": {"name": "ПОЯС", "bonus": 1.10},
	"legs": {"name": "НОГИ", "bonus": 1.05}
}

# === 5 ПАР ДЛЯ ЗАЩИТЫ ===
var block_pairs = {
	"head_chest": {"name": "ГОЛОВА+ГРУДЬ", "parts": ["head", "chest"], "bonus": 30},
	"chest_belly": {"name": "ГРУДЬ+ЖИВОТ", "parts": ["chest", "belly"], "bonus": 35},
	"belly_groin": {"name": "ЖИВОТ+ПОЯС", "parts": ["belly", "groin"], "bonus": 25},
	"groin_legs": {"name": "ПОЯС+НОГИ", "parts": ["groin", "legs"], "bonus": 20},
	"legs_head": {"name": "НОГИ+ГОЛОВА", "parts": ["legs", "head"], "bonus": 25}
}

var mobs_db = {
	"wolf": {"name": "Волк", "level": 3, "hp": 60, "strength": 10, "agility": 8, "defense": 25, "attack": 40, "gold_min": 5, "gold_max": 15, "exp_min": 10, "exp_max": 20},
	"skeleton": {"name": "Скелет", "level": 5, "hp": 80, "strength": 12, "agility": 6, "defense": 30, "attack": 50, "gold_min": 10, "gold_max": 25, "exp_min": 15, "exp_max": 30},
	"troll": {"name": "Тролль", "level": 10, "hp": 150, "strength": 20, "agility": 5, "defense": 45, "attack": 70, "gold_min": 25, "gold_max": 50, "exp_min": 30, "exp_max": 60},
	"dragon": {"name": "Дракон", "level": 20, "hp": 500, "strength": 35, "agility": 15, "defense": 80, "attack": 120, "gold_min": 100, "gold_max": 300, "exp_min": 100, "exp_max": 200},
	"rat": {"name": "Крыса", "level": 1, "hp": 30, "strength": 5, "agility": 6, "defense": 10, "attack": 15, "gold_min": 2, "gold_max": 8, "exp_min": 5, "exp_max": 12},
	"orc": {"name": "Орк", "level": 15, "hp": 200, "strength": 25, "agility": 7, "defense": 50, "attack": 90, "gold_min": 40, "gold_max": 80, "exp_min": 50, "exp_max": 90},
	"demon": {"name": "Демон", "level": 30, "hp": 400, "strength": 40, "agility": 20, "defense": 70, "attack": 150, "gold_min": 150, "gold_max": 300, "exp_min": 150, "exp_max": 300},
	"boss": {"name": "БОСС", "level": 50, "hp": 1000, "strength": 60, "agility": 25, "defense": 100, "attack": 200, "gold_min": 500, "gold_max": 1000, "exp_min": 500, "exp_max": 1000}
}

var gold_frame_style = null
var main_content

func _ready():
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	z_index = 100
	
	create_gold_frame_style()
	build_ui()
	load_player_data()
	
	close_btn.pressed.connect(_on_close)
	attack_btn.pressed.connect(_execute_attack)
	reset_btn.pressed.connect(_reset_choices)

func create_gold_frame_style():
	gold_frame_style = StyleBoxFlat.new()
	gold_frame_style.bg_color = Color(0.2, 0.2, 0.2, 1)
	gold_frame_style.border_color = Color(1, 0.84, 0, 0.8)
	gold_frame_style.border_width_left = 2
	gold_frame_style.border_width_right = 2
	gold_frame_style.border_width_top = 2
	gold_frame_style.border_width_bottom = 2
	gold_frame_style.corner_radius_top_left = 5
	gold_frame_style.corner_radius_top_right = 5
	gold_frame_style.corner_radius_bottom_left = 5
	gold_frame_style.corner_radius_bottom_right = 5

func build_ui():
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.04, 0.03, 0.98)
	bg_style.border_color = Color(1, 0.84, 0, 0.6)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left = 10
	bg_style.corner_radius_top_right = 10
	bg_style.corner_radius_bottom_left = 10
	bg_style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", bg_style)
	
	# СКРОЛЛ
	main_scroll = ScrollContainer.new()
	main_scroll.anchor_left = 0.0
	main_scroll.anchor_top = 0.0
	main_scroll.anchor_right = 1.0
	main_scroll.anchor_bottom = 1.0
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(main_scroll)
	
	main_content = VBoxContainer.new()
	main_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_content.add_theme_constant_override("separation", 8)
	main_scroll.add_child(main_content)
	
	# === ЗАГОЛОВОК ===
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_content.add_child(top_panel)
	
	var title = Label.new()
	title.text = "⚔️ БОЙ ⚔️"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 22)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 20)
	top_panel.add_child(close_btn)
	
	# === СТАТЫ ===
	var stats_row = HBoxContainer.new()
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_theme_constant_override("separation", 30)
	main_content.add_child(stats_row)
	
	var player_stats = create_player_stats()
	stats_row.add_child(player_stats)
	
	var enemy_stats = create_enemy_stats()
	stats_row.add_child(enemy_stats)
	
	# === ЛОГ БОЯ ===
	var log_panel = create_log_panel()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_content.add_child(log_panel)
	
	# === АТАКА И ЗАЩИТА (НИЖЕ ЛОГА) ===
	var action_row = HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_theme_constant_override("separation", 20)
	main_content.add_child(action_row)
	
	var attack_panel = create_attack_panel()
	attack_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(attack_panel)
	
	var block_panel = create_block_panel()
	block_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(block_panel)
	
	# === КНОПКИ ===
	var bottom_row = HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 15)
	main_content.add_child(bottom_row)
	
	attack_btn = Button.new()
	attack_btn.text = "⚔️ АТАКОВАТЬ"
	attack_btn.custom_minimum_size = Vector2(140, 45)
	attack_btn.disabled = true
	bottom_row.add_child(attack_btn)
	
	reset_btn = Button.new()
	reset_btn.text = "❌ СБРОСИТЬ"
	reset_btn.custom_minimum_size = Vector2(140, 45)
	bottom_row.add_child(reset_btn)
	
	timer_label = Label.new()
	timer_label.text = "⏱️ 30"
	timer_label.add_theme_font_size_override("font_size", 16)
	bottom_row.add_child(timer_label)
	
	damage_counter_label = Label.new()
	damage_counter_label.text = "Урон: 0 HP"
	damage_counter_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	damage_counter_label.add_theme_font_size_override("font_size", 14)
	bottom_row.add_child(damage_counter_label)
	
	# Контейнеры для группового боя
	party_players_container = VBoxContainer.new()
	party_players_container.visible = false
	main_content.add_child(party_players_container)
	
	enemy_party_container = VBoxContainer.new()
	enemy_party_container.visible = false
	main_content.add_child(enemy_party_container)

func create_player_stats() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 65)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	style.border_color = Color(1, 0.84, 0, 0.4)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.05
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.95
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	player_name_label = Label.new()
	player_name_label.text = "👤 ИГРОК"
	player_name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	player_name_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(player_name_label)
	
	var hp_row = HBoxContainer.new()
	vbox.add_child(hp_row)
	var hp_icon = Label.new()
	hp_icon.text = "❤️"
	hp_icon.add_theme_font_size_override("font_size", 10)
	hp_row.add_child(hp_icon)
	player_hp_label = Label.new()
	player_hp_label.text = "100/100"
	player_hp_label.add_theme_font_size_override("font_size", 10)
	hp_row.add_child(player_hp_label)
	
	var mana_row = HBoxContainer.new()
	vbox.add_child(mana_row)
	var mana_icon = Label.new()
	mana_icon.text = "🔮"
	mana_icon.add_theme_font_size_override("font_size", 10)
	mana_row.add_child(mana_icon)
	player_mana_label = Label.new()
	player_mana_label.text = "50"
	player_mana_label.add_theme_font_size_override("font_size", 10)
	mana_row.add_child(player_mana_label)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 10)
	vbox.add_child(stats_grid)
	
	player_strength_label = Label.new()
	player_strength_label.text = "💪0"
	player_strength_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(player_strength_label)
	
	player_agility_label = Label.new()
	player_agility_label.text = "🎯0"
	player_agility_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(player_agility_label)
	
	player_defense_label = Label.new()
	player_defense_label.text = "🛡️0"
	player_defense_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(player_defense_label)
	
	player_attack_label = Label.new()
	player_attack_label.text = "⚔️0"
	player_attack_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(player_attack_label)
	
	return panel

func create_enemy_stats() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 65)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	style.border_color = Color(1, 0.84, 0, 0.4)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.05
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.95
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	enemy_name_label = Label.new()
	enemy_name_label.text = "👾 ПРОТИВНИК"
	enemy_name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	enemy_name_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(enemy_name_label)
	
	var hp_row = HBoxContainer.new()
	vbox.add_child(hp_row)
	var hp_icon = Label.new()
	hp_icon.text = "❤️"
	hp_icon.add_theme_font_size_override("font_size", 10)
	hp_row.add_child(hp_icon)
	enemy_hp_label = Label.new()
	enemy_hp_label.text = "100/100"
	enemy_hp_label.add_theme_font_size_override("font_size", 10)
	hp_row.add_child(enemy_hp_label)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 10)
	vbox.add_child(stats_grid)
	
	enemy_strength_label = Label.new()
	enemy_strength_label.text = "💪0"
	enemy_strength_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(enemy_strength_label)
	
	enemy_agility_label = Label.new()
	enemy_agility_label.text = "🎯0"
	enemy_agility_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(enemy_agility_label)
	
	enemy_defense_label = Label.new()
	enemy_defense_label.text = "🛡️0"
	enemy_defense_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(enemy_defense_label)
	
	enemy_attack_label = Label.new()
	enemy_attack_label.text = "⚔️0"
	enemy_attack_label.add_theme_font_size_override("font_size", 9)
	stats_grid.add_child(enemy_attack_label)
	
	return panel

func create_log_panel() -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
	style.border_color = Color(1, 0.84, 0, 0.4)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.02
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.95
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	var log_title = Label.new()
	log_title.text = "⚔️ ЛОГ БОЯ ⚔️"
	log_title.horizontal_alignment = 1
	log_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	log_title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(log_title)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)
	
	log_container = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 3)
	scroll.add_child(log_container)
	
	return panel

func create_attack_panel() -> Panel:
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", gold_frame_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.05
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.95
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "🗡️ АТАКА"
	title_label.horizontal_alignment = 1
	title_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	title_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title_label)
	
	for part_id in attack_parts:
		var part = attack_parts[part_id]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		
		var check = Label.new()
		check.text = "○"
		check.add_theme_font_size_override("font_size", 14)
		row.add_child(check)
		
		var btn = Button.new()
		var bonus = int((part["bonus"] - 1.0) * 100)
		btn.text = part["name"] + " +" + str(bonus) + "%"
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 30)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_select_attack.bind(part_id, btn, check))
		row.add_child(btn)
		
		attack_buttons[part_id] = {"btn": btn, "check": check}
	
	return panel

func create_block_panel() -> Panel:
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", gold_frame_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.05
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.95
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "🛡️ ЗАЩИТА"
	title_label.horizontal_alignment = 1
	title_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	title_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title_label)
	
	for pair_id in block_pairs:
		var pair = block_pairs[pair_id]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		
		var check = Label.new()
		check.text = "○"
		check.add_theme_font_size_override("font_size", 14)
		row.add_child(check)
		
		var btn = Button.new()
		var bonus = pair["bonus"]
		btn.text = pair["name"] + " +" + str(bonus)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 30)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_select_block.bind(pair_id, btn, check))
		row.add_child(btn)
		
		block_buttons[pair_id] = {"btn": btn, "check": check}
	
	return panel

func create_party_card(player: Dictionary, idx: int) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(80, 55)
	panel.set_meta("player_index", idx)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
	style.border_color = Color(1, 0.84, 0, 0.3)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.05
	margin.anchor_top = 0.05
	margin.anchor_right = 0.95
	margin.anchor_bottom = 0.95
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	var name = player.get("name", "Игрок")
	if name.length() > 8:
		name = name.substr(0, 8)
	var name_label = Label.new()
	name_label.text = name
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(name_label)
	
	var hp_label = Label.new()
	hp_label.text = "❤️" + str(player.get("current_hp", 100))
	hp_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	hp_label.add_theme_font_size_override("font_size", 7)
	vbox.add_child(hp_label)
	
	return panel

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
		var stats = player_data.get("stats", {})
		var base_hp = 200 + stats.get("endurance", 0) * 5
		player_data["max_hp"] = base_hp
		player_data["current_hp"] = base_hp
		player_data["mana"] = 100 + stats.get("wisdom", 0) * 3
		player_data["strength"] = stats.get("strength", 0)
		player_data["agility"] = stats.get("agility", 0)
		player_data["defense"] = 50 + stats.get("endurance", 0)
		player_data["attack"] = 100 + stats.get("strength", 0) * 2
		update_player_stats()
	else:
		player_data = {"name": "Игрок", "current_hp": 100, "max_hp": 100, "mana": 50, "strength": 10, "agility": 8, "defense": 30, "attack": 60}
		update_player_stats()

func update_player_stats():
	var name = player_data.get("name", "Игрок")
	if name.length() > 10:
		name = name.substr(0, 10)
	player_name_label.text = "👤 " + name
	player_hp_label.text = str(player_data.get("current_hp", 100)) + "/" + str(player_data.get("max_hp", 100))
	player_mana_label.text = str(player_data.get("mana", 50))
	player_strength_label.text = "💪" + str(player_data.get("strength", 0))
	player_agility_label.text = "🎯" + str(player_data.get("agility", 0))
	player_defense_label.text = "🛡️" + str(player_data.get("defense", 0))
	player_attack_label.text = "⚔️" + str(player_data.get("attack", 0))

func update_enemy_stats():
	enemy_hp_label.text = str(enemy_data.get("current_hp", 0)) + "/" + str(enemy_data.get("max_hp", 0))
	enemy_strength_label.text = "💪" + str(enemy_data.get("strength", 0))
	enemy_agility_label.text = "🎯" + str(enemy_data.get("agility", 0))
	enemy_defense_label.text = "🛡️" + str(enemy_data.get("defense", 0))
	enemy_attack_label.text = "⚔️" + str(enemy_data.get("attack", 0))
	
	var name = enemy_data.get("name", "ПРОТИВНИК")
	if name.length() > 10:
		name = name.substr(0, 10)
	enemy_name_label.text = "👾 " + name

func set_enemy(mob_id: String):
	var mob = mobs_db.get(mob_id, mobs_db["wolf"])
	enemy_data = mob.duplicate(true)
	enemy_data["current_hp"] = mob["hp"]
	enemy_data["max_hp"] = mob["hp"]
	enemy_data["mob_id"] = mob_id
	update_enemy_stats()

func set_pvp_enemy(opponent_data: Dictionary):
	enemy_data = opponent_data.duplicate(true)
	enemy_data["current_hp"] = opponent_data.get("current_hp", opponent_data.get("max_hp", 100))
	enemy_data["max_hp"] = opponent_data.get("max_hp", 100)
	enemy_data["mob_id"] = "pvp"
	update_enemy_stats()

func setup_group_mode(players: Array, enemies: Array, battle_mode: int):
	battle_type = battle_mode
	
	for child in party_players_container.get_children():
		child.queue_free()
	for child in enemy_party_container.get_children():
		child.queue_free()
	
	for i in range(players.size()):
		var card = create_party_card(players[i], i)
		party_players_container.add_child(card)
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		var card = create_party_card(enemy, i)
		enemy_party_container.add_child(card)
	
	var enemy_stats_panel = enemy_name_label.get_parent().get_parent().get_parent()
	if enemy_stats_panel:
		enemy_stats_panel.visible = false
	
	party_players_container.visible = true
	enemy_party_container.visible = true

func start_battle(opponent, battle_mode: int = BattleType.PVE, extra_data: Dictionary = {}):
	battle_type = battle_mode
	battle_active = true
	time_left = 30
	total_damage_dealt = 0
	battle_context = extra_data.duplicate()
	
	if battle_mode == BattleType.GROUP or extra_data.has("group_mode"):
		var players = extra_data.get("party_members", [])
		var enemies = extra_data.get("enemy_party", [])
		setup_group_mode(players, enemies, battle_mode)
		
		if enemies.size() > 0:
			enemy_data = enemies[0].duplicate(true)
			update_enemy_stats()
		
		add_log("⚔️ ГРУППОВОЙ БОЙ!")
		add_log("Игроков: " + str(players.size()) + ", Врагов: " + str(enemies.size()))
		add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		add_log("🎮 Ваш ход! Выберите атаку и защиту.")
		start_battle_timer()
		return
	
	if battle_mode == BattleType.PARTY:
		party_players_container.visible = true
		enemy_party_container.visible = true
		
		var enemy_stats_panel = enemy_name_label.get_parent().get_parent().get_parent()
		if enemy_stats_panel:
			enemy_stats_panel.visible = false
		
		party_members = extra_data.get("party_members", [])
		current_attacker_index = 0
		
		for child in party_players_container.get_children():
			child.queue_free()
		for i in range(party_members.size()):
			var card = create_party_card(party_members[i], i)
			party_players_container.add_child(card)
		
		enemy_party_container.visible = false
		set_enemy(opponent)
		
		add_log("⚔️ ГРУППОВОЙ БОЙ ПРОТИВ БОССА!")
		add_log("Босс: " + enemy_data.get("name", "БОСС"))
		add_log("Участников: " + str(party_members.size()))
		add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		add_log("🎮 Ваш ход! Выберите атаку и защиту.")
		start_battle_timer()
		return
	
	party_players_container.visible = false
	enemy_party_container.visible = false
	
	var enemy_stats_panel = enemy_name_label.get_parent().get_parent().get_parent()
	if enemy_stats_panel:
		enemy_stats_panel.visible = true
	
	match battle_mode:
		BattleType.PVE:
			if typeof(opponent) == TYPE_STRING:
				set_enemy(opponent)
			elif typeof(opponent) == TYPE_DICTIONARY:
				enemy_data = opponent.duplicate(true)
				enemy_data["current_hp"] = enemy_data.get("hp", 100)
				enemy_data["max_hp"] = enemy_data.get("hp", 100)
				update_enemy_stats()
			add_log("⚔️ PvE Бой! Противник: " + enemy_data.get("name", "Враг"))
		BattleType.PVP:
			if typeof(opponent) == TYPE_DICTIONARY:
				set_pvp_enemy(opponent)
			add_log("⚔️ PvP Бой! Противник: " + enemy_data.get("name", "Игрок"))
	
	add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	add_log("🎮 Ваш ход! Выберите атаку и защиту.")
	start_battle_timer()

func start_battle_timer():
	if battle_timer:
		battle_timer.stop()
	battle_timer = Timer.new()
	battle_timer.wait_time = 1.0
	battle_timer.timeout.connect(_update_timer)
	add_child(battle_timer)
	battle_timer.start()

func _update_timer():
	if not battle_active:
		return
	time_left -= 1
	timer_label.text = "⏱️ " + str(time_left)
	if time_left <= 0:
		_timeout()

func _timeout():
	battle_timer.stop()
	add_log("⏰ Время вышло! Ход пропущен!")
	_reset_choices()
	_enemy_turn()

func _reset_choices():
	player_attack_choice = null
	player_block_choice = null
	
	for id in attack_buttons:
		attack_buttons[id]["check"].text = "○"
		attack_buttons[id]["btn"].modulate = Color(1, 1, 1, 1)
	
	for id in block_buttons:
		block_buttons[id]["check"].text = "○"
		block_buttons[id]["btn"].modulate = Color(1, 1, 1, 1)
	
	attack_btn.disabled = true
	attack_btn.text = "⚔️ АТАКОВАТЬ"
	attack_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _select_attack(choice: String, btn: Button, check: Label):
	if not is_player_turn:
		add_log("Сейчас ход противника!")
		return
	
	player_attack_choice = choice
	
	for id in attack_buttons:
		attack_buttons[id]["check"].text = "○"
		attack_buttons[id]["btn"].modulate = Color(1, 1, 1, 1)
	
	check.text = "●"
	btn.modulate = COLOR_SELECTED_ATTACK
	_check_ready()

func _select_block(choice: String, btn: Button, check: Label):
	if not is_player_turn:
		add_log("Сейчас ход противника!")
		return
	
	player_block_choice = choice
	
	for id in block_buttons:
		block_buttons[id]["check"].text = "○"
		block_buttons[id]["btn"].modulate = Color(1, 1, 1, 1)
	
	check.text = "●"
	btn.modulate = COLOR_SELECTED_BLOCK
	_check_ready()

func _check_ready():
	if player_attack_choice != null and player_block_choice != null:
		attack_btn.disabled = false
		attack_btn.text = "⚔️ АТАКОВАТЬ!"
		attack_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	else:
		attack_btn.disabled = true
		attack_btn.text = "⚔️ АТАКОВАТЬ"
		attack_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _execute_attack():
	if not is_player_turn:
		add_log("Сейчас ход противника!")
		return
	if player_attack_choice == null or player_block_choice == null:
		add_log("⚠️ Выберите цель атаки и защиту!")
		return
	
	if battle_type == BattleType.PARTY or battle_type == BattleType.GROUP:
		_resolve_party_round()
	else:
		_resolve_duel_round()

func _resolve_duel_round():
	is_player_turn = false
	attack_btn.disabled = true
	
	var attack_part = attack_parts[player_attack_choice]
	var block_pair = block_pairs[player_block_choice]
	var blocked_parts = block_pair["parts"]
	
	var enemy_attack = enemy_ai_choice()
	var enemy_block = enemy_ai_block_choice()
	var enemy_blocked_parts = block_pairs[enemy_block]["parts"]
	
	var player_hit = not (player_attack_choice in blocked_parts)
	var enemy_hit = not (enemy_attack in enemy_blocked_parts)
	
	add_log("🔥 Вы бьёте в " + attack_part["name"] + ", защищаете " + block_pair["name"])
	add_log("👤 " + enemy_data["name"] + " бьёт в " + attack_parts[enemy_attack]["name"] + ", защищает " + block_pairs[enemy_block]["name"])
	
	var pdam = calculate_damage(true, player_attack_choice)
	if player_hit:
		var fd = int(pdam * attack_part["bonus"])
		enemy_data["current_hp"] -= fd
		total_damage_dealt += fd
		add_log("💥 +" + str(fd) + " урона!")
	else:
		add_log("🛡️ Блок! -0")
	
	var edam = calculate_damage(false, enemy_attack)
	if enemy_hit:
		var fd = int(edam * attack_parts[enemy_attack]["bonus"])
		player_data["current_hp"] -= fd
		add_log("💔 -" + str(fd) + " урона!")
	else:
		add_log("🛡️ Вы блок!")
	
	update_player_stats()
	update_enemy_stats()
	damage_counter_label.text = "Урон: " + str(total_damage_dealt) + " HP"
	
	if player_data["current_hp"] <= 0:
		end_battle(false)
		return
	if enemy_data["current_hp"] <= 0:
		end_battle(true)
		return
	
	_reset_choices()
	time_left = 30
	_enemy_turn()

func _resolve_party_round():
	is_player_turn = false
	attack_btn.disabled = true
	
	var current_player = party_members[current_attacker_index] if party_members.size() > 0 else player_data
	var player_name = current_player.get("name", "Игрок")
	
	var attack_part = attack_parts[player_attack_choice]
	var block_pair = block_pairs[player_block_choice]
	var blocked_parts = block_pair["parts"]
	
	var enemy_attack = enemy_ai_choice()
	var enemy_block = enemy_ai_block_choice()
	var enemy_blocked_parts = block_pairs[enemy_block]["parts"]
	
	var player_hit = not (player_attack_choice in blocked_parts)
	var enemy_hit = not (enemy_attack in enemy_blocked_parts)
	
	add_log("🔥 " + player_name + " бьёт в " + attack_part["name"] + ", защищает " + block_pair["name"])
	add_log("🐉 " + enemy_data["name"] + " бьёт в " + attack_parts[enemy_attack]["name"] + ", защищает " + block_pairs[enemy_block]["name"])
	
	var pdam = calculate_damage_party(current_player, player_attack_choice)
	if player_hit:
		var fd = int(pdam * attack_part["bonus"])
		enemy_data["current_hp"] -= fd
		total_damage_dealt += fd
		add_log("💥 +" + str(fd) + " урона!")
	else:
		add_log("🛡️ Блок!")
	
	var edam = calculate_damage(false, enemy_attack)
	if enemy_hit:
		var fd = int(edam * attack_parts[enemy_attack]["bonus"])
		if current_player.has("current_hp"):
			current_player["current_hp"] -= fd
		add_log("💔 -" + str(fd) + " урона!")
	else:
		add_log("🛡️ " + player_name + " блок!")
	
	update_enemy_stats()
	damage_counter_label.text = "Урон: " + str(total_damage_dealt) + " HP"
	
	if enemy_data["current_hp"] <= 0:
		end_battle(true)
		return
	
	current_attacker_index = (current_attacker_index + 1) % party_members.size()
	
	var found = false
	for i in range(party_members.size()):
		var idx = (current_attacker_index + i) % party_members.size()
		if party_members[idx].get("current_hp", 0) > 0:
			current_attacker_index = idx
			found = true
			break
	
	if not found:
		end_battle(false)
		return
	
	highlight_active_party_player(current_attacker_index)
	
	_reset_choices()
	time_left = 30
	_enemy_turn_party()

func highlight_active_party_player(index: int):
	for i in range(party_players_container.get_child_count()):
		var card = party_players_container.get_child(i)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.06, 0.04, 0.9)
		if i == index:
			style.border_color = COLOR_SELECTED_ATTACK
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
		else:
			style.border_color = Color(1, 0.84, 0, 0.3)
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
		card.add_theme_stylebox_override("panel", style)

func _enemy_turn():
	is_player_turn = true
	add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	add_log("🎮 Ваш ход! Выберите атаку и защиту")
	time_left = 30

func _enemy_turn_party():
	is_player_turn = true
	var name = party_members[current_attacker_index].get("name", "Игрок")
	add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	add_log("🎮 Ход: " + name)
	time_left = 30

func enemy_ai_choice() -> String:
	var parts = ["head", "chest", "belly", "groin", "legs"]
	var weights = [0.3, 0.25, 0.2, 0.15, 0.1]
	var r = randf()
	var c = 0.0
	for i in range(parts.size()):
		c += weights[i]
		if r <= c:
			return parts[i]
	return "chest"

func enemy_ai_block_choice() -> String:
	var pairs = ["head_chest", "chest_belly", "belly_groin", "groin_legs", "legs_head"]
	return pairs[randi() % pairs.size()]

func calculate_damage(is_player: bool, part: String) -> int:
	var att = player_data if is_player else enemy_data
	var def = enemy_data if is_player else player_data
	var dmg = att.get("attack", 50) - def.get("defense", 30) / 2
	dmg = int(dmg * randf_range(0.85, 1.15))
	return max(1, dmg)

func calculate_damage_party(att: Dictionary, part: String) -> int:
	var dmg = att.get("attack", 50) - enemy_data.get("defense", 30) / 2
	dmg = int(dmg * randf_range(0.85, 1.15))
	return max(1, dmg)

func add_log(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 9)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if "ПОБЕДА" in text or "ПОРАЖЕНИЕ" in text:
		label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	elif "💥" in text:
		label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	elif "🛡️" in text:
		label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	else:
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	log_container.add_child(label)
	await get_tree().process_frame
	var scroll = label.get_parent().get_parent().get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func calculate_rewards() -> Dictionary:
	return {"exp": enemy_data.get("level", 1) * 50, "gold": enemy_data.get("level", 1) * 30, "items": []}

func apply_rewards(rewards: Dictionary):
	if player_data.has("gold"):
		player_data["gold"] = player_data.get("gold", 0) + rewards["gold"]
	if player_data.has("exp"):
		player_data["exp"] = player_data.get("exp", 0) + rewards["exp"]
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()

func show_result_popup(victory: bool, rewards: Dictionary):
	if result_popup and is_instance_valid(result_popup):
		result_popup.queue_free()
	
	result_popup = Panel.new()
	result_popup.anchor_left = 0.2
	result_popup.anchor_top = 0.3
	result_popup.anchor_right = 0.8
	result_popup.anchor_bottom = 0.7
	add_child(result_popup)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.98)
	style.border_color = Color(1, 0.84, 0, 0.6)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	result_popup.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.05
	margin.anchor_top = 0.05
	margin.anchor_right = 0.95
	margin.anchor_bottom = 0.95
	result_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var result_icon = Label.new()
	result_icon.text = "🏆" if victory else "💀"
	result_icon.horizontal_alignment = 1
	result_icon.add_theme_font_size_override("font_size", 48)
	vbox.add_child(result_icon)
	
	var result_text = Label.new()
	result_text.text = "ПОБЕДА!" if victory else "ПОРАЖЕНИЕ!"
	result_text.horizontal_alignment = 1
	result_text.add_theme_color_override("font_color", Color(0.5, 1, 0.5) if victory else Color(1, 0.3, 0.3))
	result_text.add_theme_font_size_override("font_size", 24)
	vbox.add_child(result_text)
	
	var rewards_text = Label.new()
	rewards_text.text = "⭐ +" + str(rewards["exp"]) + " опыта\n💰 +" + str(rewards["gold"]) + " золота"
	rewards_text.horizontal_alignment = 1
	rewards_text.add_theme_color_override("font_color", Color(1, 0.84, 0))
	rewards_text.add_theme_font_size_override("font_size", 16)
	vbox.add_child(rewards_text)
	
	var close_result_btn = Button.new()
	close_result_btn.text = "ЗАКРЫТЬ"
	close_result_btn.custom_minimum_size = Vector2(140, 45)
	close_result_btn.pressed.connect(_close_result_popup)
	vbox.add_child(close_result_btn)

func _close_result_popup():
	if result_popup and is_instance_valid(result_popup):
		result_popup.queue_free()
		result_popup = null
	_on_close()

func end_battle(victory: bool):
	battle_active = false
	if battle_timer:
		battle_timer.stop()
	
	var rewards = calculate_rewards()
	
	if victory:
		apply_rewards(rewards)
		add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		add_log("🏆 ПОБЕДА! 🏆")
		add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		add_log("🎁 +" + str(rewards["exp"]) + " опыта, +" + str(rewards["gold"]) + " золота")
		battle_finished.emit(true, rewards)
	else:
		add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		add_log("💀 ПОРАЖЕНИЕ 💀")
		add_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		battle_finished.emit(false, {})
	
	attack_btn.disabled = true
	reset_btn.disabled = true
	
	# Показываем попап с результатом
	await get_tree().create_timer(1.0).timeout
	show_result_popup(victory, rewards)

func _on_close():
	if battle_timer:
		battle_timer.stop()
	if result_popup and is_instance_valid(result_popup):
		result_popup.queue_free()
	queue_free()
