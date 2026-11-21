# res://modules/arena.gd
extends Panel

# =============================================================================
# АРЕНА - PvP комнаты и тренировка
# =============================================================================

var close_btn
var content_container
var create_room_btn
var player_data = {}
var rooms = {}
var current_room_id = null
var current_pin_input = null

var card_style
var create_window = null
var pin_window = null
var training_window = null
var room_window = null

# Цвета статусов
const COLOR_WAITING = Color(0.3, 0.8, 0.3)
const COLOR_FIGHTING = Color(0.8, 0.5, 0.2)
const COLOR_FINISHED = Color(0.5, 0.5, 0.5)
const COLOR_PRIVATE = Color(0.8, 0.6, 0.2)

func _ready():
	build_ui()
	load_player_data()
	load_rooms()
	update_rooms_list()
	
	close_btn.pressed.connect(_on_close)
	create_room_btn.pressed.connect(_open_create_window)
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)
		if NetworkManager.has_signal("data_received"):
			NetworkManager.data_received.connect(_on_network_data)

func build_ui():
	anchor_left = 0.08
	anchor_top = 0.05
	anchor_right = 0.92
	anchor_bottom = 0.95
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.98)
	style.border_color = Color(1, 0.84, 0, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)
	
	card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.1, 0.08, 0.9)
	card_style.border_color = Color(1, 0.84, 0, 0.3)
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card_style.corner_radius_top_left = 5
	card_style.corner_radius_top_right = 5
	card_style.corner_radius_bottom_left = 5
	card_style.corner_radius_bottom_right = 5
	
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
	title.text = "⚔️ АРЕНА ⚔️"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	create_room_btn = Button.new()
	create_room_btn.text = "➕ СОЗДАТЬ КОМНАТУ"
	create_room_btn.custom_minimum_size = Vector2(200, 40)
	create_room_btn.add_theme_color_override("font_color", Color(1, 0.84, 0))
	main_vbox.add_child(create_room_btn)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1, 0.84, 0, 0.3)
	main_vbox.add_child(sep)
	
	var rooms_label = Label.new()
	rooms_label.text = "АКТИВНЫЕ КОМНАТЫ"
	rooms_label.horizontal_alignment = 1
	rooms_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	rooms_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(rooms_label)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 8)
	scroll.add_child(content_container)

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {"name": "Игрок", "level": 1, "gold": 1000}

func load_rooms():
	if player_data.has("arena_rooms"):
		rooms = player_data["arena_rooms"]
	else:
		rooms = {}

func save_rooms():
	player_data["arena_rooms"] = rooms
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()

func update_rooms_list():
	for child in content_container.get_children():
		child.queue_free()
	
	var training_card = create_training_card()
	content_container.add_child(training_card)
	
	if rooms.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Нет активных комнат.\nСоздайте свою!"
		empty_label.horizontal_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 14)
		content_container.add_child(empty_label)
		return
	
	for room_id in rooms:
		var room = rooms[room_id]
		var card = create_room_card(room)
		content_container.add_child(card)

func create_training_card() -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 80
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.05
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.95
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var icon = Label.new()
	icon.text = "🎯"
	icon.custom_minimum_size = Vector2(50, 50)
	icon.add_theme_font_size_override("font_size", 36)
	icon.horizontal_alignment = 1
	hbox.add_child(icon)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var title = Label.new()
	title.text = "ТРЕНИРОВКА"
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "Бой с манекеном. Проверьте свои силы!"
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(desc)
	
	var train_btn = Button.new()
	train_btn.text = "ТРЕНИРОВКА"
	train_btn.custom_minimum_size = Vector2(120, 35)
	train_btn.pressed.connect(_open_training)
	hbox.add_child(train_btn)
	
	return card

func create_room_card(room: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 100
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.05
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.95
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var status_icon = "🟢" if room["status"] == "waiting" else "🟡" if room["status"] == "fighting" else "🔴"
	var status_color = COLOR_WAITING if room["status"] == "waiting" else COLOR_FIGHTING if room["status"] == "fighting" else COLOR_FINISHED
	
	var icon = Label.new()
	icon.text = "🔒" if room["privacy"] == "private" else "🏠"
	icon.custom_minimum_size = Vector2(50, 50)
	icon.add_theme_font_size_override("font_size", 32)
	icon.horizontal_alignment = 1
	hbox.add_child(icon)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var title_hbox = HBoxContainer.new()
	info_vbox.add_child(title_hbox)
	
	var name_label = Label.new()
	name_label.text = status_icon + " " + room["name"]
	name_label.add_theme_color_override("font_color", status_color)
	name_label.add_theme_font_size_override("font_size", 15)
	title_hbox.add_child(name_label)
	
	var type_label = Label.new()
	type_label.text = " [" + room["type"] + "]"
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	type_label.add_theme_font_size_override("font_size", 12)
	title_hbox.add_child(type_label)
	
	var creator_label = Label.new()
	creator_label.text = "👤 Создатель: " + room["creator"]
	creator_label.add_theme_font_size_override("font_size", 12)
	creator_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(creator_label)
	
	var players_label = Label.new()
	players_label.text = "👥 " + str(room["players"].size()) + "/" + str(room["max_players"]) + " игроков"
	players_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(players_label)
	
	if room["privacy"] == "private":
		var private_label = Label.new()
		private_label.text = "🔒 Приватная комната (требуется PIN-код)"
		private_label.add_theme_color_override("font_color", COLOR_PRIVATE)
		private_label.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(private_label)
	
	var action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(100, 35)
	
	if room["status"] == "waiting":
		if room["players"].size() < room["max_players"]:
			action_btn.text = "ВОЙТИ"
			action_btn.pressed.connect(_join_room.bind(room["id"]))
		else:
			action_btn.text = "ПОЛНА"
			action_btn.disabled = true
	elif room["status"] == "fighting":
		action_btn.text = "В БОЮ"
		action_btn.disabled = true
	else:
		action_btn.text = "ЗАВЕРШЕНА"
		action_btn.disabled = true
	
	hbox.add_child(action_btn)
	
	return card

func _open_create_window():
	if create_window and is_instance_valid(create_window):
		create_window.visible = true
		create_window.move_to_front()
		return
	
	create_window = Panel.new()
	create_window.anchor_left = 0.25
	create_window.anchor_top = 0.2
	create_window.anchor_right = 0.75
	create_window.anchor_bottom = 0.8
	add_child(create_window)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.98)
	style.border_color = Color(1, 0.84, 0, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	create_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.05
	margin.anchor_top = 0.05
	margin.anchor_right = 0.95
	margin.anchor_bottom = 0.95
	create_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "СОЗДАНИЕ КОМНАТЫ"
	title.horizontal_alignment = 1
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var name_label = Label.new()
	name_label.text = "Название комнаты:"
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)
	
	var name_input = LineEdit.new()
	name_input.placeholder_text = "Введите название..."
	name_input.custom_minimum_size.y = 35
	vbox.add_child(name_input)
	
	var type_label = Label.new()
	type_label.text = "Тип боя:"
	type_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(type_label)
	
	var type_container = HBoxContainer.new()
	type_container.add_theme_constant_override("separation", 20)
	vbox.add_child(type_container)
	
	var type_1x1 = CheckBox.new()
	type_1x1.text = "1x1"
	type_1x1.button_pressed = true
	type_container.add_child(type_1x1)
	
	var type_2x2 = CheckBox.new()
	type_2x2.text = "2x2"
	type_container.add_child(type_2x2)
	
	var type_3x3 = CheckBox.new()
	type_3x3.text = "3x3"
	type_container.add_child(type_3x3)
	
	var privacy_label = Label.new()
	privacy_label.text = "Тип комнаты:"
	privacy_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(privacy_label)
	
	var privacy_container = HBoxContainer.new()
	privacy_container.add_theme_constant_override("separation", 20)
	vbox.add_child(privacy_container)
	
	var public_radio = CheckBox.new()
	public_radio.text = "Публичная"
	public_radio.button_pressed = true
	privacy_container.add_child(public_radio)
	
	var private_radio = CheckBox.new()
	private_radio.text = "Приватная"
	privacy_container.add_child(private_radio)
	
	var pin_container = VBoxContainer.new()
	pin_container.visible = false
	vbox.add_child(pin_container)
	
	var pin_label = Label.new()
	pin_label.text = "PIN-код (4 цифры):"
	pin_label.add_theme_font_size_override("font_size", 12)
	pin_container.add_child(pin_label)
	
	var pin_input = LineEdit.new()
	pin_input.placeholder_text = "****"
	pin_input.max_length = 4
	pin_input.secret = true
	pin_input.custom_minimum_size.y = 35
	pin_container.add_child(pin_input)
	
	private_radio.toggled.connect(func(val): pin_container.visible = val)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var create_btn = Button.new()
	create_btn.text = "СОЗДАТЬ"
	create_btn.custom_minimum_size = Vector2(120, 40)
	create_btn.pressed.connect(_create_room.bind(name_input, type_1x1, type_2x2, type_3x3, public_radio, private_radio, pin_input, create_window))
	btn_hbox.add_child(create_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.pressed.connect(create_window.queue_free)
	btn_hbox.add_child(cancel_btn)

func _create_room(name_input, type_1x1, type_2x2, type_3x3, public_radio, private_radio, pin_input, window):
	var room_name = name_input.text.strip_edges()
	if room_name == "":
		_show_message("Введите название комнаты!")
		return
	
	var battle_type = "1x1"
	if type_2x2.button_pressed:
		battle_type = "2x2"
	elif type_3x3.button_pressed:
		battle_type = "3x3"
	
	var max_players = 2 if battle_type == "1x1" else 4 if battle_type == "2x2" else 6
	
	var is_private = private_radio.button_pressed
	var pin_code = pin_input.text.strip_edges() if is_private else ""
	
	if is_private and (pin_code == "" or pin_code.length() != 4 or not pin_code.is_valid_int()):
		_show_message("Введите корректный PIN-код (4 цифры)!")
		return
	
	var player_name = player_data.get("name", "Игрок")
	var room_id = "room_" + str(Time.get_unix_time_from_system())
	
	rooms[room_id] = {
		"id": room_id,
		"name": room_name,
		"creator": player_name,
		"type": battle_type,
		"privacy": "private" if is_private else "public",
		"pin": pin_code,
		"players": [player_name],
		"max_players": max_players,
		"status": "waiting",
		"created_at": Time.get_unix_time_from_system()
	}
	
	save_rooms()
	update_rooms_list()
	window.queue_free()
	_show_message("Комната \"" + room_name + "\" создана!")

func _join_room(room_id: String):
	var room = rooms.get(room_id)
	if not room:
		_show_message("Комната не найдена!")
		return
	
	var player_name = player_data.get("name", "Игрок")
	
	if player_name in room["players"]:
		_show_message("Вы уже в этой комнате!")
		return
	
	if room["players"].size() >= room["max_players"]:
		_show_message("Комната полна!")
		return
	
	if room["privacy"] == "private":
		_open_pin_window(room_id, room)
	else:
		room["players"].append(player_name)
		
		if room["players"].size() >= room["max_players"]:
			_start_pvp_battle(room_id)
		else:
			save_rooms()
			update_rooms_list()
			_show_message("Вы вошли в комнату \"" + room["name"] + "\"! Ожидаем других игроков...")

func _open_pin_window(room_id: String, room: Dictionary):
	if pin_window and is_instance_valid(pin_window):
		pin_window.queue_free()
	
	pin_window = Panel.new()
	pin_window.anchor_left = 0.3
	pin_window.anchor_top = 0.35
	pin_window.anchor_right = 0.7
	pin_window.anchor_bottom = 0.65
	add_child(pin_window)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.98)
	style.border_color = Color(1, 0.84, 0, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	pin_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.05
	margin.anchor_top = 0.05
	margin.anchor_right = 0.95
	margin.anchor_bottom = 0.95
	pin_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "ВХОД В КОМНАТУ: \"" + room["name"] + "\""
	title.horizontal_alignment = 1
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var lock_icon = Label.new()
	lock_icon.text = "🔒"
	lock_icon.horizontal_alignment = 1
	lock_icon.add_theme_font_size_override("font_size", 32)
	vbox.add_child(lock_icon)
	
	var pin_label = Label.new()
	pin_label.text = "Введите PIN-код:"
	pin_label.horizontal_alignment = 1
	pin_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(pin_label)
	
	var pin_input = LineEdit.new()
	pin_input.placeholder_text = "****"
	pin_input.max_length = 4
	pin_input.secret = true
	pin_input.custom_minimum_size = Vector2(200, 40)
	pin_input.horizontal_alignment = 1
	vbox.add_child(pin_input)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var enter_btn = Button.new()
	enter_btn.text = "ВОЙТИ"
	enter_btn.custom_minimum_size = Vector2(100, 35)
	enter_btn.pressed.connect(_check_pin.bind(room_id, room, pin_input, pin_window))
	btn_hbox.add_child(enter_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(100, 35)
	cancel_btn.pressed.connect(pin_window.queue_free)
	btn_hbox.add_child(cancel_btn)

func _check_pin(room_id: String, room: Dictionary, pin_input: LineEdit, window):
	var entered_pin = pin_input.text.strip_edges()
	
	if entered_pin == room.get("pin", ""):
		var player_name = player_data.get("name", "Игрок")
		room["players"].append(player_name)
		
		if room["players"].size() >= room["max_players"]:
			window.queue_free()
			_start_pvp_battle(room_id)
		else:
			save_rooms()
			update_rooms_list()
			window.queue_free()
			_show_message("Вы вошли в комнату \"" + room["name"] + "\"! Ожидаем других игроков...")
	else:
		_show_message("Неверный PIN-код!")

func _start_pvp_battle(room_id: String):
	var room = rooms.get(room_id)
	if not room:
		_show_message("Комната не найдена!")
		return
	
	if room["players"].size() < 2:
		_show_message("Недостаточно игроков для начала боя!")
		return
	
	var player_name = player_data.get("name", "Игрок")
	var opponent_name = ""
	for p in room["players"]:
		if p != player_name:
			opponent_name = p
			break
	
	var opponent_data = {
		"name": opponent_name,
		"max_hp": 200,
		"current_hp": 200,
		"attack": 80,
		"defense": 40,
		"strength": 10,
		"agility": 8,
		"level": player_data.get("level", 1),
		"ai_pattern": "player"
	}
	
	room["status"] = "fighting"
	save_rooms()
	_on_close()
	
	var battle = load("res://modules/battle_system.gd").new()
	add_child(battle)
	battle.start_battle(opponent_data, battle.BattleType.PVP, {
		"source": "arena_pvp",
		"room_id": room_id,
		"opponent": opponent_name,
		"on_victory": _on_pvp_battle_finished,
		"on_defeat": _on_pvp_battle_finished,
		"context": {"room_id": room_id, "opponent": opponent_name}
	})

func _on_pvp_battle_finished(context: Dictionary):
	var room_id = context.get("room_id", "")
	var opponent = context.get("opponent", "")
	var victory = context.get("victory", false)
	
	if victory:
		_show_message("🏆 Победа над " + opponent + "!")
	else:
		_show_message("💀 Поражение от " + opponent + "...")
	
	var room = rooms.get(room_id)
	if room:
		room["status"] = "finished"
		save_rooms()

func _open_training():
	_on_close()
	
	var dummy_data = {
		"name": "Тренировочный манекен",
		"hp": 999999,
		"max_hp": 999999,
		"attack": 0,
		"defense": 0,
		"strength": 0,
		"agility": 0,
		"level": 1,
		"icon": "🎯",
		"mob_id": "dummy",
		"ai_pattern": "passive",
		"drops": [],
		"gold_min": 0,
		"gold_max": 0,
		"exp_min": 0,
		"exp_max": 0
	}
	
	var battle = load("res://modules/battle_system.gd").new()
	add_child(battle)
	battle.start_battle(dummy_data, battle.BattleType.PVE, {
		"source": "arena_training",
		"on_victory": _on_training_finished
	})

func _on_training_finished(context: Dictionary):
	_show_message("Вы хорошо потренировались!")

func _show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Арена"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _on_network_data(data: String):
	var parts = data.split("|")
	match parts[0]:
		"ARENA_ROOM_CREATED":
			load_rooms()
			update_rooms_list()
		"ARENA_ROOM_JOINED":
			load_rooms()
			update_rooms_list()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	load_rooms()
	update_rooms_list()

func _on_close():
	if create_window:
		create_window.queue_free()
	if pin_window:
		pin_window.queue_free()
	if training_window:
		training_window.queue_free()
	queue_free()
