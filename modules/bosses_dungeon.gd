# res://modules/bosses_dungeon.gd
extends Panel

var close_btn
var content_container
var player_data = {}
var purchased_rumors = []
var update_timer = null

var boss_availability = {}

var bosses_db = {
	"crypt_king": {
		"name": "Лорд Лич, Пожиратель Душ",
		"icon": "💀",
		"level": 10,
		"hp": 1000,
		"attack_min": 50,
		"attack_max": 80,
		"defense": 40,
		"location": "crypt",
		"location_name": "Склеп",
		"available_duration": 600,
		"description": "Древний правитель мёртвых, восставший из гробницы.",
		"enemies": [
			{"name": "Костяной воин", "level": 5, "damage": "25-40", "icon": "💀", "drops": "Кость"},
			{"name": "Призрачный слуга", "level": 8, "damage": "35-55", "icon": "👻", "drops": "Призрачная пыль"}
		],
		"rewards": {"exp": 100, "gold": 200, "points": 10},
		"drops": [
			{"item": "lich_crystal", "name": "Лич-кристалл", "chance": 10, "icon": "💎"},
			{"item": "bone_staff", "name": "Костяной посох", "chance": 5, "icon": "🔮"}
		],
		"rumor": "Говорят, Лич спрятал свою душу в кристалле."
	},
	"tower_guardian": {
		"name": "Страж Забытой Башни",
		"icon": "🗿",
		"level": 20,
		"hp": 2500,
		"attack_min": 70,
		"attack_max": 100,
		"defense": 60,
		"location": "tower",
		"location_name": "Башня",
		"available_duration": 900,
		"description": "Каменный страж, охраняющий древнюю башню.",
		"enemies": [
			{"name": "Каменный солдат", "level": 15, "damage": "40-65", "icon": "🗿", "drops": "Каменное ядро"},
			{"name": "Магический шар", "level": 18, "damage": "55-80", "icon": "🔮", "drops": "Магический кристалл"}
		],
		"rewards": {"exp": 200, "gold": 400, "points": 20},
		"drops": [
			{"item": "guardian_core", "name": "Ядро стража", "chance": 10, "icon": "⚙️"},
			{"item": "ancient_scroll", "name": "Древний свиток", "chance": 15, "icon": "📜"}
		],
		"rumor": "Башня хранит тайны древних магов."
	},
	"verdant_wyrm": {
		"name": "Зелёный Змей",
		"icon": "🐉",
		"level": 30,
		"hp": 5000,
		"attack_min": 100,
		"attack_max": 150,
		"defense": 80,
		"location": "forest",
		"location_name": "Лес",
		"available_duration": 1200,
		"description": "Древний змей, опутавший корнями лес.",
		"enemies": [
			{"name": "Лесной змеёныш", "level": 22, "damage": "60-90", "icon": "🐍", "drops": "Змеиная чешуя"},
			{"name": "Древесный дух", "level": 25, "damage": "70-110", "icon": "🌳", "drops": "Древесная сердцевина"}
		],
		"rewards": {"exp": 300, "gold": 600, "points": 30},
		"drops": [
			{"item": "wyrm_scale", "name": "Чешуя змея", "chance": 15, "icon": "🛡️"},
			{"item": "wyrm_heart", "name": "Сердце змея", "chance": 8, "icon": "❤️"}
		],
		"rumor": "Змей охраняет древо жизни."
	},
	"magma_behemoth": {
		"name": "Повелитель Магмы, Сердце Вулкана",
		"icon": "🔥",
		"level": 40,
		"hp": 8000,
		"attack_min": 120,
		"attack_max": 180,
		"defense": 100,
		"location": "volcano",
		"location_name": "Вулкан",
		"available_duration": 1500,
		"description": "Гигантское существо из лавы и камня.",
		"enemies": [
			{"name": "Лавовый слизень", "level": 30, "damage": "80-120", "icon": "🟠", "drops": "Кусок лавы"},
			{"name": "Огненный дух", "level": 35, "damage": "100-150", "icon": "🔥", "drops": "Искра пламени"}
		],
		"rewards": {"exp": 500, "gold": 1000, "points": 50},
		"drops": [
			{"item": "magma_heart", "name": "Сердце магмы", "chance": 8, "icon": "❤️"},
			{"item": "lava_sword", "name": "Лавовый клинок", "chance": 10, "icon": "⚔️"}
		],
		"rumor": "Бегемот куёт оружие в лаве."
	},
	"shadow_wraith": {
		"name": "Теневой Убийца, Дух Тьмы",
		"icon": "👤",
		"level": 50,
		"hp": 12000,
		"attack_min": 150,
		"attack_max": 220,
		"defense": 120,
		"location": "castle",
		"location_name": "Замок",
		"available_duration": 1800,
		"description": "Бестелесное существо из чистой тьмы.",
		"enemies": [
			{"name": "Теневой сгусток", "level": 40, "damage": "100-150", "icon": "⬛", "drops": "Осколок тьмы"},
			{"name": "Тёмный дух", "level": 45, "damage": "120-170", "icon": "🌑", "drops": "Тёмная эссенция"}
		],
		"rewards": {"exp": 800, "gold": 1500, "points": 80},
		"drops": [
			{"item": "shadow_sword", "name": "Теневой меч", "chance": 8, "icon": "⚔️"},
			{"item": "shadow_crystal", "name": "Теневой кристалл", "chance": 5, "icon": "💎"}
		],
		"rumor": "Призрак собирает тени павших."
	},
	"frost_drake": {
		"name": "Ледяной Дрейк, Хранитель Вечного Холода",
		"icon": "❄️",
		"level": 60,
		"hp": 20000,
		"attack_min": 200,
		"attack_max": 300,
		"defense": 150,
		"location": "ruins",
		"location_name": "Руины",
		"available_duration": 2400,
		"description": "Древний дракон, покрытый вечным льдом.",
		"enemies": [
			{"name": "Ледяной дракончик", "level": 50, "damage": "120-180", "icon": "🐉", "drops": "Ледяная чешуя"},
			{"name": "Снежный элементаль", "level": 55, "damage": "150-220", "icon": "❄️", "drops": "Снежный кристалл"}
		],
		"rewards": {"exp": 1200, "gold": 2500, "points": 120},
		"drops": [
			{"item": "drake_bone", "name": "Кость дрейка", "chance": 15, "icon": "🦴"},
			{"item": "ice_essence", "name": "Ледяная эссенция", "chance": 10, "icon": "💠"}
		],
		"rumor": "Дрейк хранит древний ледяной артефакт."
	}
}

func _ready():
	build_ui()
	load_player_data()
	load_boss_availability()
	update_bosses_list()
	
	close_btn.pressed.connect(_on_close)
	
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update_timers)
	add_child(update_timer)
	update_timer.start()
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

func build_ui():
	anchor_left = 0.05
	anchor_top = 0.02
	anchor_right = 0.95
	anchor_bottom = 0.98
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.05, 0.98)
	panel_style.border_color = Color(1, 0.84, 0, 0.6)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", panel_style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.anchor_left = 0.02
	main_vbox.anchor_top = 0.02
	main_vbox.anchor_right = 0.98
	main_vbox.anchor_bottom = 0.98
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)
	
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "🏰 ПОДЗЕМЕЛЬЯ 🏰"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 12)
	scroll.add_child(content_container)

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
		purchased_rumors = player_data.get("purchased_rumors", [])
	else:
		player_data = {"name": "Игрок", "level": 1, "gold": 1000}
		purchased_rumors = []

func load_boss_availability():
	if player_data.has("boss_availability"):
		boss_availability = player_data["boss_availability"]
	else:
		var current_time = Time.get_unix_time_from_system()
		for boss_id in bosses_db:
			var boss = bosses_db[boss_id]
			var wait_time = randi() % 601 + 600
			boss_availability[boss_id] = {
				"available": true,
				"expires_at": current_time + boss["available_duration"],
				"next_spawn": current_time + wait_time
			}
		save_boss_availability()

func save_boss_availability():
	player_data["boss_availability"] = boss_availability
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()

func get_time_string(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return str(hours) + "ч " + str(minutes) + "м " + str(secs) + "с"
	elif minutes > 0:
		return str(minutes) + "м " + str(secs) + "с"
	else:
		return str(secs) + "с"

func update_bosses_list():
	for child in content_container.get_children():
		child.queue_free()
	
	for boss_id in bosses_db:
		var boss = bosses_db[boss_id]
		var card = create_boss_card(boss_id, boss)
		content_container.add_child(card)

func create_boss_card(boss_id: String, boss: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 220
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var avail = boss_availability[boss_id]
	var is_available = avail["available"]
	var current_time = Time.get_unix_time_from_system()
	var border_color = Color(0.3, 0.8, 0.3) if is_available else Color(0.5, 0.5, 0.5)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.1, 0.08, 0.9)
	card_style.border_color = border_color
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.02
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.98
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = boss["icon"]
	icon_label.add_theme_font_size_override("font_size", 36)
	title_hbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = boss["name"]
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 18)
	title_hbox.add_child(name_label)
	
	var level_label = Label.new()
	level_label.text = "Ур. " + str(boss["level"])
	level_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	level_label.add_theme_font_size_override("font_size", 14)
	title_hbox.add_child(level_label)
	
	var status_hbox = HBoxContainer.new()
	status_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(status_hbox)
	
	if is_available:
		var status_label = Label.new()
		status_label.text = "🟢 ДОСТУПЕН"
		status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		status_label.add_theme_font_size_override("font_size", 12)
		status_hbox.add_child(status_label)
		
		var remaining = int(avail["expires_at"] - current_time)
		var timer_label = Label.new()
		timer_label.text = "⏰ " + get_time_string(remaining)
		timer_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
		timer_label.add_theme_font_size_override("font_size", 12)
		status_hbox.add_child(timer_label)
		card.set_meta("timer_label", timer_label)
		card.set_meta("boss_id", boss_id)
	else:
		var status_label = Label.new()
		status_label.text = "🔴 НЕДОСТУПЕН"
		status_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		status_label.add_theme_font_size_override("font_size", 12)
		status_hbox.add_child(status_label)
		
		var remaining = int(avail["next_spawn"] - current_time)
		var timer_label = Label.new()
		timer_label.text = "⏳ " + get_time_string(remaining)
		timer_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		timer_label.add_theme_font_size_override("font_size", 12)
		status_hbox.add_child(timer_label)
		card.set_meta("timer_label", timer_label)
		card.set_meta("boss_id", boss_id)
	
	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 20)
	vbox.add_child(info_grid)
	
	var hp_label = Label.new()
	hp_label.text = "❤️ " + str(boss["hp"])
	hp_label.add_theme_font_size_override("font_size", 12)
	info_grid.add_child(hp_label)
	
	var attack_label = Label.new()
	attack_label.text = "🗡️ " + str(boss["attack_min"]) + "-" + str(boss["attack_max"])
	attack_label.add_theme_font_size_override("font_size", 12)
	info_grid.add_child(attack_label)
	
	var defense_label = Label.new()
	defense_label.text = "🛡️ " + str(boss["defense"])
	defense_label.add_theme_font_size_override("font_size", 12)
	info_grid.add_child(defense_label)
	
	var location_label = Label.new()
	location_label.text = "📍 " + boss["location_name"]
	location_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1))
	location_label.add_theme_font_size_override("font_size", 12)
	info_grid.add_child(location_label)
	
	var desc_label = Label.new()
	desc_label.text = boss["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	
	var reward_hbox = HBoxContainer.new()
	reward_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(reward_hbox)
	
	var exp_label = Label.new()
	exp_label.text = "⭐ " + str(boss["rewards"]["exp"])
	exp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	exp_label.add_theme_font_size_override("font_size", 12)
	reward_hbox.add_child(exp_label)
	
	var gold_label = Label.new()
	gold_label.text = "💰 " + str(boss["rewards"]["gold"])
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	gold_label.add_theme_font_size_override("font_size", 12)
	reward_hbox.add_child(gold_label)
	
	var points_label = Label.new()
	points_label.text = "🏅 " + str(boss["rewards"]["points"])
	points_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	points_label.add_theme_font_size_override("font_size", 12)
	reward_hbox.add_child(points_label)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)
	
	var detail_btn = Button.new()
	detail_btn.text = "ПОДРОБНЕЕ"
	detail_btn.custom_minimum_size = Vector2(100, 32)
	detail_btn.pressed.connect(_show_boss_detail.bind(boss_id))
	btn_hbox.add_child(detail_btn)
	
	var fight_btn = Button.new()
	fight_btn.text = "СРАЖАТЬСЯ"
	fight_btn.custom_minimum_size = Vector2(100, 32)
	
	if is_available:
		fight_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		fight_btn.pressed.connect(_fight_boss.bind(boss_id))
	else:
		fight_btn.disabled = true
		fight_btn.modulate = Color(0.5, 0.5, 0.5)
	
	btn_hbox.add_child(fight_btn)
	
	return card

func _update_timers():
	var current_time = Time.get_unix_time_from_system()
	var need_update = false
	
	for child in content_container.get_children():
		var timer_label = child.get_meta("timer_label", null)
		var boss_id = child.get_meta("boss_id", null)
		
		if timer_label and boss_id and boss_availability.has(boss_id):
			var avail = boss_availability[boss_id]
			if avail["available"]:
				var remaining = int(avail["expires_at"] - current_time)
				if remaining <= 0:
					need_update = true
				else:
					timer_label.text = "⏰ " + get_time_string(remaining)
			else:
				var remaining = int(avail["next_spawn"] - current_time)
				if remaining <= 0:
					need_update = true
				else:
					timer_label.text = "⏳ " + get_time_string(remaining)
	
	if need_update:
		_update_bosses_state()
		update_bosses_list()

func _update_bosses_state():
	var current_time = Time.get_unix_time_from_system()
	var changed = false
	
	for boss_id in bosses_db:
		var boss = bosses_db[boss_id]
		var avail = boss_availability[boss_id]
		
		if avail["available"]:
			if current_time >= avail["expires_at"]:
				avail["available"] = false
				var wait_time = randi() % 601 + 600
				avail["next_spawn"] = current_time + wait_time
				changed = true
		else:
			if current_time >= avail["next_spawn"]:
				avail["available"] = true
				avail["expires_at"] = current_time + boss["available_duration"]
				changed = true
	
	if changed:
		save_boss_availability()

func _convert_boss_drops_to_format(boss_drops: Array) -> Array:
	var result = []
	for drop in boss_drops:
		result.append({
			"item_id": drop["item"],
			"name": drop["name"],
			"chance": drop["chance"],
			"min_qty": 1,
			"max_qty": 1,
			"icon": drop.get("icon", "📦")
		})
	return result

func _fight_boss(boss_id: String):
	var boss = bosses_db[boss_id]
	var avail = boss_availability[boss_id]
	var player_level = player_data.get("level", 1)
	
	if not avail["available"]:
		_show_message("⚠️ Босс сейчас недоступен!")
		return
	
	if player_level < boss["level"]:
		_show_message("⚠️ Ваш уровень (" + str(player_level) + ") ниже уровня босса (" + str(boss["level"]) + ")!")
		return
	
	var boss_data = {
		"name": boss["name"],
		"hp": boss["hp"],
		"max_hp": boss["hp"],
		"attack": (boss["attack_min"] + boss["attack_max"]) / 2,
		"defense": boss["defense"],
		"level": boss["level"],
		"icon": boss["icon"],
		"mob_id": boss_id,
		"ai_pattern": "aggressive",
		"drops": _convert_boss_drops_to_format(boss["drops"]),
		"gold_min": boss["rewards"]["gold"],
		"gold_max": boss["rewards"]["gold"] + 50,
		"exp_min": boss["rewards"]["exp"],
		"exp_max": boss["rewards"]["exp"] + 100
	}
	
	_on_close()
	
	var battle = load("res://modules/battle_system.gd").new()
	add_child(battle)
	battle.start_battle(boss_data, battle.BattleType.PVE, {
		"source": "boss_dungeon",
		"boss_id": boss_id,
		"on_victory": _on_boss_defeated,
		"context": {"boss_id": boss_id}
	})

func _on_boss_defeated(context: Dictionary):
	var boss_id = context.get("boss_id", "")
	if boss_id == "":
		return
	
	var avail = boss_availability[boss_id]
	avail["available"] = false
	var wait_time = randi() % 601 + 600
	avail["next_spawn"] = Time.get_unix_time_from_system() + wait_time
	save_boss_availability()
	
	update_bosses_list()

func _show_boss_detail(boss_id: String):
	var boss = bosses_db[boss_id]
	var avail = boss_availability[boss_id]
	var current_time = Time.get_unix_time_from_system()
	
	var detail_window = Panel.new()
	detail_window.anchor_left = 0.08
	detail_window.anchor_top = 0.03
	detail_window.anchor_right = 0.92
	detail_window.anchor_bottom = 0.97
	add_child(detail_window)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.03, 0.98)
	style.border_color = Color(0.6, 0.4, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	detail_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.02
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.98
	detail_window.add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = boss["icon"]
	icon_label.add_theme_font_size_override("font_size", 48)
	title_hbox.add_child(icon_label)
	
	var title_label = Label.new()
	title_label.text = boss["name"]
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title_label.add_theme_font_size_override("font_size", 26)
	title_hbox.add_child(title_label)
	
	var close_btn_detail = Button.new()
	close_btn_detail.text = "×"
	close_btn_detail.custom_minimum_size = Vector2(40, 40)
	close_btn_detail.pressed.connect(detail_window.queue_free)
	title_hbox.add_child(close_btn_detail)
	
	var lore_block = VBoxContainer.new()
	lore_block.add_theme_constant_override("separation", 5)
	vbox.add_child(lore_block)
	
	var lore_title = Label.new()
	lore_title.text = "📜 ЛЕГЕНДА"
	lore_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	lore_title.add_theme_font_size_override("font_size", 18)
	lore_block.add_child(lore_title)
	
	var lore_text = Label.new()
	lore_text.text = _get_boss_lore(boss_id)
	lore_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_text.add_theme_font_size_override("font_size", 13)
	lore_text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lore_block.add_child(lore_text)
	
	var stats_block = VBoxContainer.new()
	stats_block.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_block)
	
	var stats_title = Label.new()
	stats_title.text = "⚔️ ХАРАКТЕРИСТИКИ"
	stats_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_block.add_child(stats_title)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 30)
	stats_block.add_child(stats_grid)
	
	var add_stat = func(label_text: String, value: String, col = null):
		var name_lbl = Label.new()
		name_lbl.text = label_text
		name_lbl.add_theme_font_size_override("font_size", 13)
		stats_grid.add_child(name_lbl)
		var val_lbl = Label.new()
		val_lbl.text = value
		val_lbl.add_theme_font_size_override("font_size", 13)
		if col != null:
			val_lbl.add_theme_color_override("font_color", col)
		stats_grid.add_child(val_lbl)
	
	add_stat.call("🎚️ Уровень:", str(boss["level"]))
	add_stat.call("❤️ HP:", str(boss["hp"]), Color(1, 0.5, 0.5))
	add_stat.call("🗡️ Атака:", str(boss["attack_min"]) + "-" + str(boss["attack_max"]), Color(1, 0.7, 0.3))
	add_stat.call("🛡️ Защита:", str(boss["defense"]), Color(0.5, 0.8, 1))
	add_stat.call("📍 Локация:", boss["location_name"], Color(0.6, 0.8, 1))
	
	var enemies_block = VBoxContainer.new()
	enemies_block.add_theme_constant_override("separation", 8)
	vbox.add_child(enemies_block)
	
	var enemies_title = Label.new()
	enemies_title.text = "👥 ПРИСЛУЖНИКИ"
	enemies_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	enemies_title.add_theme_font_size_override("font_size", 18)
	enemies_block.add_child(enemies_title)
	
	for enemy in boss["enemies"]:
		var enemy_line = HBoxContainer.new()
		enemy_line.add_theme_constant_override("separation", 10)
		enemies_block.add_child(enemy_line)
		
		var enemy_icon = Label.new()
		enemy_icon.text = enemy["icon"]
		enemy_icon.add_theme_font_size_override("font_size", 24)
		enemy_line.add_child(enemy_icon)
		
		var enemy_info = VBoxContainer.new()
		enemy_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		enemy_line.add_child(enemy_info)
		
		var enemy_name = Label.new()
		enemy_name.text = enemy["name"] + " (Ур. " + str(enemy["level"]) + ")"
		enemy_name.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
		enemy_name.add_theme_font_size_override("font_size", 13)
		enemy_info.add_child(enemy_name)
		
		var enemy_stats = Label.new()
		enemy_stats.text = "🗡️ " + enemy["damage"] + " | 🎁 " + enemy["drops"]
		enemy_stats.add_theme_font_size_override("font_size", 11)
		enemy_stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		enemy_info.add_child(enemy_stats)
	
	var reward_block = VBoxContainer.new()
	reward_block.add_theme_constant_override("separation", 8)
	vbox.add_child(reward_block)
	
	var reward_title = Label.new()
	reward_title.text = "🎁 НАГРАДА"
	reward_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	reward_title.add_theme_font_size_override("font_size", 18)
	reward_block.add_child(reward_title)
	
	var reward_list = VBoxContainer.new()
	reward_list.add_theme_constant_override("separation", 3)
	reward_block.add_child(reward_list)
	
	reward_list.add_child(_make_reward_line("⭐ Опыт:", str(boss["rewards"]["exp"])))
	reward_list.add_child(_make_reward_line("💰 Золото:", str(boss["rewards"]["gold"]), Color(1, 0.84, 0)))
	reward_list.add_child(_make_reward_line("🏅 Очки:", str(boss["rewards"]["points"]), Color(1, 0.7, 0.3)))
	
	var drops_block = VBoxContainer.new()
	drops_block.add_theme_constant_override("separation", 5)
	vbox.add_child(drops_block)
	
	var drops_title = Label.new()
	drops_title.text = "🎲 ШАНС ДРОПА"
	drops_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	drops_title.add_theme_font_size_override("font_size", 18)
	drops_block.add_child(drops_title)
	
	for drop in boss["drops"]:
		var drop_label = Label.new()
		drop_label.text = "   " + drop["icon"] + " " + drop["name"] + " — " + str(drop["chance"]) + "%"
		drop_label.add_theme_font_size_override("font_size", 12)
		drops_block.add_child(drop_label)
	
	var status_block = VBoxContainer.new()
	status_block.add_theme_constant_override("separation", 5)
	vbox.add_child(status_block)
	
	var status_title = Label.new()
	status_title.text = "🕐 СТАТУС"
	status_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	status_title.add_theme_font_size_override("font_size", 18)
	status_block.add_child(status_title)
	
	if avail["available"]:
		var remaining = int(avail["expires_at"] - current_time)
		var status_text = Label.new()
		status_text.text = "🟢 Доступен (осталось " + get_time_string(remaining) + ")"
		status_text.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		status_text.add_theme_font_size_override("font_size", 13)
		status_block.add_child(status_text)
	else:
		var remaining = int(avail["next_spawn"] - current_time)
		var status_text = Label.new()
		status_text.text = "🔴 Недоступен (через " + get_time_string(remaining) + ")"
		status_text.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		status_text.add_theme_font_size_override("font_size", 13)
		status_block.add_child(status_text)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var close_popup_btn = Button.new()
	close_popup_btn.text = "ЗАКРЫТЬ"
	close_popup_btn.custom_minimum_size = Vector2(140, 45)
	close_popup_btn.pressed.connect(detail_window.queue_free)
	btn_hbox.add_child(close_popup_btn)

func _make_reward_line(label: String, value: String, color: Color = Color(0.8, 0.8, 0.8)) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var label_part = Label.new()
	label_part.text = label
	label_part.add_theme_font_size_override("font_size", 13)
	hbox.add_child(label_part)
	
	var value_part = Label.new()
	value_part.text = value
	value_part.add_theme_color_override("font_color", color)
	value_part.add_theme_font_size_override("font_size", 13)
	hbox.add_child(value_part)
	
	return hbox

func _get_boss_lore(boss_id: String) -> String:
	var lore = {
		"crypt_king": "Давным-давно, когда королевством правил жестокий король, народ страдал от его тирании. После смерти его душа не нашла покоя. Говорят, что каждую ночь он восстаёт из мёртвых, чтобы продолжить своё правление над царством теней.",
		"tower_guardian": "Великий маг создал этого стража, чтобы охранять свою башню после смерти. Страж наделён частицей души мага и обладает невероятной силой.",
		"verdant_wyrm": "Древний змей, который спал в лесу ещё до того, как люди построили свои первые города. Он охраняет священное древо жизни, которое дарует бессмертие.",
		"magma_behemoth": "В незапамятные времена, когда мир был сотворён богами, в недрах вулкана родился этот гигант. Он — кузнец, выковавший оружие для самих богов.",
		"shadow_wraith": "Когда-то это существо было великим воином. Но во время битвы с демонами он был смертельно ранен и заключил сделку с тьмой.",
		"frost_drake": "Ледяной дракон — результат древнего ритуала, проведённого культом северных магов. Дракон не чувствует боли и не боится смерти."
	}
	return lore.get(boss_id, "История этого босса окутана тайной.")

func _show_message(text: String):
	# Компактное уведомление сверху экрана вместо огромного диалогового окна
	var toast = Panel.new()
	toast.z_index = 200
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.anchor_left = 0.3
	toast.anchor_right = 0.7
	toast.anchor_top = 0.05
	toast.anchor_bottom = 0.13
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	style.border_color = Color(1, 0.84, 0, 0.8)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	toast.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = 1
	lbl.vertical_alignment = 1
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast.add_child(lbl)
	
	add_child(toast)
	
	var tw = create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	purchased_rumors = player_data.get("purchased_rumors", [])
	if player_data.has("boss_availability"):
		boss_availability = player_data["boss_availability"]
	else:
		load_boss_availability()
	update_bosses_list()

func _on_close():
	if update_timer:
		update_timer.stop()
	queue_free()
