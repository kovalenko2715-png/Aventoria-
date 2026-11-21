# res://modules/guild.gd
extends Panel

var close_btn
var content_panel
var npc_avatar
var npc_title
var greeting_label
var quest_points_label

var quests_window = null
var arena_window = null
var hall_window = null
var storage_window = null

var player_data = {}
var guild_quest_points = 0

func _ready():
	build_ui()
	load_player_data()
	update_ui()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)
		if NetworkManager.has_signal("data_received"):
			NetworkManager.data_received.connect(_on_network_data)

func build_ui():
	anchor_left = 0.05
	anchor_top = 0.02
	anchor_right = 0.95
	anchor_bottom = 0.98
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.05, 0.97)
	panel_style.border_color = Color(1, 0.84, 0, 0.5)
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
	title.text = "🏰 ГИЛЬДИЯ АВАНТЮРИСТОВ 🏰"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 22)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var nav_panel = HBoxContainer.new()
	nav_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_panel.add_theme_constant_override("separation", 15)
	main_vbox.add_child(nav_panel)
	
	var nav_buttons = [
		{"id": "quests", "name": "📋 ДОСКА ЗАДАНИЙ", "color": Color(1, 0.84, 0)},
		{"id": "arena", "name": "⚔️ АРЕНА", "color": Color(1, 0.5, 0.5)},
		{"id": "hall", "name": "🏆 ЗАЛ СЛАВЫ", "color": Color(0.5, 0.8, 1)},
		{"id": "storage", "name": "📦 ХРАНИЛИЩЕ", "color": Color(0.5, 1, 0.5)}
	]
	
	for btn_data in nav_buttons:
		var btn = Button.new()
		btn.text = btn_data["name"]
		btn.custom_minimum_size = Vector2(160, 45)
		btn.add_theme_color_override("font_color", btn_data["color"])
		btn.pressed.connect(_open_module.bind(btn_data["id"]))
		nav_panel.add_child(btn)
	
	content_panel = Panel.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_panel)
	
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.12, 0.1, 0.08, 0.9)
	content_style.border_color = Color(1, 0.84, 0, 0.2)
	content_style.border_width_left = 1
	content_style.border_width_right = 1
	content_style.border_width_top = 1
	content_style.border_width_bottom = 1
	content_style.corner_radius_top_left = 8
	content_style.corner_radius_top_right = 8
	content_style.corner_radius_bottom_left = 8
	content_style.corner_radius_bottom_right = 8
	content_panel.add_theme_stylebox_override("panel", content_style)
	
	var content_margin = MarginContainer.new()
	content_margin.anchor_left = 0.02
	content_margin.anchor_top = 0.02
	content_margin.anchor_right = 0.98
	content_margin.anchor_bottom = 0.98
	content_panel.add_child(content_margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 12)
	content_margin.add_child(content_vbox)
	
	var npc_hbox = HBoxContainer.new()
	npc_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(npc_hbox)
	
	var npc_avatar_container = VBoxContainer.new()
	npc_avatar_container.custom_minimum_size = Vector2(80, 0)
	npc_avatar_container.alignment = BoxContainer.ALIGNMENT_CENTER
	npc_hbox.add_child(npc_avatar_container)
	
	npc_avatar = Label.new()
	npc_avatar.text = "👑"
	npc_avatar.add_theme_font_size_override("font_size", 48)
	npc_avatar_container.add_child(npc_avatar)
	
	var npc_text_vbox = VBoxContainer.new()
	npc_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	npc_hbox.add_child(npc_text_vbox)
	
	npc_title = Label.new()
	npc_title.text = "Мастер Альдрик"
	npc_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	npc_title.add_theme_font_size_override("font_size", 18)
	npc_text_vbox.add_child(npc_title)
	
	greeting_label = Label.new()
	greeting_label.text = "Добро пожаловать в Гильдию Авантюристов!"
	greeting_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	greeting_label.add_theme_font_size_override("font_size", 14)
	greeting_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	npc_text_vbox.add_child(greeting_label)
	
	var center_info = Label.new()
	center_info.text = "🏛️\n\nЗдесь ты можешь:\n\n📋 Брать задания на Доске\n⚔️ Сражаться на Арене\n🏆 Попасть в Зал Славы\n📦 Пользоваться Хранилищем"
	center_info.horizontal_alignment = 1
	center_info.vertical_alignment = 1
	center_info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	center_info.add_theme_font_size_override("font_size", 14)
	content_vbox.add_child(center_info)
	
	var bottom_panel = HBoxContainer.new()
	bottom_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(bottom_panel)
	
	quest_points_label = Label.new()
	quest_points_label.text = "🏅 Очки заданий: 0"
	quest_points_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quest_points_label.add_theme_font_size_override("font_size", 14)
	bottom_panel.add_child(quest_points_label)

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
		guild_quest_points = player_data.get("guild_quest_points", 0)
	else:
		player_data = {"name": "Игрок", "gold": 1000, "level": 1}
		guild_quest_points = 0

func save_quest_points():
	player_data["guild_quest_points"] = guild_quest_points
	
	if NetworkManager:
		if NetworkManager.current_mode == "local":
			NetworkManager.player_data = player_data
			NetworkManager.save_local_data()
		else:
			NetworkManager.send_add_guild_points(guild_quest_points)
		
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.emit(player_data)

func update_ui():
	quest_points_label.text = "🏅 Очки заданий: " + str(guild_quest_points)
	
	var player_name = "путник"
	if player_data.has("name") and typeof(player_data["name"]) == TYPE_STRING:
		player_name = player_data["name"]
	
	var time_hour = Time.get_time_dict_from_system().hour
	var greeting = "Добро пожаловать"
	if time_hour < 12:
		greeting = "Доброе утро"
	elif time_hour < 18:
		greeting = "Добрый день"
	else:
		greeting = "Добрый вечер"
	
	greeting_label.text = greeting + ", " + player_name + "! Чем могу помочь?"

func _open_module(module: String):
	match module:
		"quests":
			_open_quests()
		"arena":
			_open_arena()
		"hall":
			_open_hall()
		"storage":
			_open_storage()

func _open_quests():
	if quests_window and is_instance_valid(quests_window):
		quests_window.visible = true
		quests_window.move_to_front()
		return
	
	quests_window = load("res://modules/quests.gd").new()
	quests_window.set_guild_reference(self)
	add_child(quests_window)
	quests_window.tree_exited.connect(_on_quests_closed)

func _on_quests_closed():
	quests_window = null

func _open_arena():
	if arena_window and is_instance_valid(arena_window):
		arena_window.visible = true
		arena_window.move_to_front()
		return
	
	arena_window = load("res://modules/arena.gd").new()
	add_child(arena_window)
	arena_window.tree_exited.connect(_on_arena_closed)

func _on_arena_closed():
	arena_window = null

func _open_hall():
	if hall_window and is_instance_valid(hall_window):
		hall_window.visible = true
		hall_window.move_to_front()
		return
	
	hall_window = load("res://modules/hall.gd").new()
	add_child(hall_window)
	hall_window.tree_exited.connect(_on_hall_closed)

func _on_hall_closed():
	hall_window = null

func _open_storage():
	if storage_window and is_instance_valid(storage_window):
		storage_window.visible = true
		storage_window.move_to_front()
		return
	
	storage_window = load("res://modules/storage.gd").new()
	storage_window.set_guild_reference(self)
	add_child(storage_window)
	storage_window.tree_exited.connect(_on_storage_closed)

func _on_storage_closed():
	storage_window = null

func add_quest_points(amount: int):
	guild_quest_points += amount
	save_quest_points()
	update_ui()

func _on_network_data(data: String):
	var parts = data.split("|")
	match parts[0]:
		"GUILD_POINTS":
			guild_quest_points = int(parts[1])
			update_ui()
		"GUILD_QUEST_COMPLETE_OK":
			add_quest_points(int(parts[1]))

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	guild_quest_points = player_data.get("guild_quest_points", 0)
	update_ui()

func _on_close():
	queue_free()
