# res://modules/hall.gd
extends Panel

# =============================================================================
# ЗАЛ СЛАВЫ - ТОПЫ ИГРОКОВ
# =============================================================================

var close_btn
var tabs_container
var content_container
var current_tab = "level"

var player_data = {}
var top_players = {
	"level": [],
	"pvp": [],
	"monsters": [],
	"gold": []
}

var card_style

# Имена ботов для локального режима
var bot_names = [
	"Альтаир", "Брут", "Велес", "Гром", "Добрыня",
	"Елисей", "Ждан", "Златослав", "Искра", "Казимир",
	"Лютобор", "Мирослав", "Никита", "Олег", "Перун",
	"Радомир", "Святогор", "Твердислав", "Умар", "Фрол",
	"Храбр", "Цветан", "Часлав", "Шурик", "Юрий",
	"Яромир", "Богдан", "Владимир", "Глеб", "Денис"
]

func _ready():
	build_ui()
	load_player_data()
	load_top_players()
	update_ui()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)
		if NetworkManager.has_signal("data_received"):
			NetworkManager.data_received.connect(_on_network_data)
	
	refresh_top_players()

func build_ui():
	anchor_left = 0.1
	anchor_top = 0.05
	anchor_right = 0.9
	anchor_bottom = 0.95
	
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
	title.text = "🏆 ЗАЛ СЛАВЫ 🏆"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 28)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(45, 45)
	top_panel.add_child(close_btn)
	
	tabs_container = HBoxContainer.new()
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_container.add_theme_constant_override("separation", 20)
	main_vbox.add_child(tabs_container)
	
	var level_btn = Button.new()
	level_btn.text = "🏆 УРОВЕНЬ"
	level_btn.custom_minimum_size = Vector2(140, 45)
	level_btn.add_theme_font_size_override("font_size", 16)
	level_btn.pressed.connect(_on_tab_pressed.bind("level"))
	tabs_container.add_child(level_btn)
	
	var pvp_btn = Button.new()
	pvp_btn.text = "⚔️ PVP"
	pvp_btn.custom_minimum_size = Vector2(140, 45)
	pvp_btn.add_theme_font_size_override("font_size", 16)
	pvp_btn.pressed.connect(_on_tab_pressed.bind("pvp"))
	tabs_container.add_child(pvp_btn)
	
	var monsters_btn = Button.new()
	monsters_btn.text = "👾 МОНСТРЫ"
	monsters_btn.custom_minimum_size = Vector2(140, 45)
	monsters_btn.add_theme_font_size_override("font_size", 16)
	monsters_btn.pressed.connect(_on_tab_pressed.bind("monsters"))
	tabs_container.add_child(monsters_btn)
	
	var gold_btn = Button.new()
	gold_btn.text = "💰 ЗОЛОТО"
	gold_btn.custom_minimum_size = Vector2(140, 45)
	gold_btn.add_theme_font_size_override("font_size", 16)
	gold_btn.pressed.connect(_on_tab_pressed.bind("gold"))
	tabs_container.add_child(gold_btn)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1, 0.84, 0, 0.3)
	main_vbox.add_child(sep)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 8)
	scroll.add_child(content_container)
	
	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 ОБНОВИТЬ"
	refresh_btn.custom_minimum_size = Vector2(220, 40)
	refresh_btn.add_theme_font_size_override("font_size", 14)
	refresh_btn.pressed.connect(refresh_top_players)
	main_vbox.add_child(refresh_btn)

func _on_tab_pressed(tab: String):
	current_tab = tab
	update_ui()

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {"name": "Игрок", "level": 1, "gold": 1000}

func load_top_players():
	if player_data.has("hall_of_fame"):
		top_players = player_data["hall_of_fame"]
	else:
		top_players = {
			"level": [],
			"pvp": [],
			"monsters": [],
			"gold": []
		}

func save_top_players():
	player_data["hall_of_fame"] = top_players
	if NetworkManager and NetworkManager.current_mode == "local":
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()

func refresh_top_players():
	if NetworkManager and NetworkManager.current_mode == "server":
		NetworkManager.send("GET_HALL_OF_FAME")
		_show_message("Загрузка данных...")
	else:
		generate_bot_top()
		update_ui()
		_show_message("Данные обновлены!")

func generate_bot_top():
	var players_list = []
	
	var player_name = player_data.get("name", "Игрок")
	var player_level = player_data.get("level", 1)
	var player_pvp = player_data.get("stats_pvp", {}).get("pvp_wins", 0)
	var player_monsters = player_data.get("stats_pvp", {}).get("monsters", 0)
	var player_gold = player_data.get("gold", 0)
	
	players_list.append({
		"name": player_name,
		"level": player_level,
		"pvp_wins": player_pvp,
		"monsters": player_monsters,
		"gold": player_gold,
		"is_bot": false
	})
	
	for name in bot_names:
		var level = randi() % 50 + 1
		var pvp_wins = randi() % 100
		var monsters = randi() % 500
		var gold = randi() % 10000
		
		players_list.append({
			"name": name,
			"level": level,
			"pvp_wins": pvp_wins,
			"monsters": monsters,
			"gold": gold,
			"is_bot": true
		})
	
	var level_sorted = players_list.duplicate()
	level_sorted.sort_custom(func(a, b): return a["level"] > b["level"])
	top_players["level"] = level_sorted
	
	var pvp_sorted = players_list.duplicate()
	pvp_sorted.sort_custom(func(a, b): return a["pvp_wins"] > b["pvp_wins"])
	top_players["pvp"] = pvp_sorted
	
	var monsters_sorted = players_list.duplicate()
	monsters_sorted.sort_custom(func(a, b): return a["monsters"] > b["monsters"])
	top_players["monsters"] = monsters_sorted
	
	var gold_sorted = players_list.duplicate()
	gold_sorted.sort_custom(func(a, b): return a["gold"] > b["gold"])
	top_players["gold"] = gold_sorted
	
	save_top_players()

func get_rank_prefix(index: int) -> String:
	match index:
		0: return "🥇 "
		1: return "🥈 "
		2: return "🥉 "
		_: return ""

func format_number(num: int) -> String:
	if num >= 1000000:
		return str(num / 1000000) + "M"
	elif num >= 1000:
		return str(num / 1000) + "K"
	return str(num)

func update_ui():
	for child in content_container.get_children():
		child.queue_free()
	
	var list_to_show = []
	var value_name = ""
	
	match current_tab:
		"level":
			list_to_show = top_players["level"]
			value_name = "очков"
		"pvp":
			list_to_show = top_players["pvp"]
			value_name = "побед"
		"monsters":
			list_to_show = top_players["monsters"]
			value_name = "монстров"
		"gold":
			list_to_show = top_players["gold"]
			value_name = "золота"
	
	if list_to_show.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Нет данных для отображения.\nНажмите 'ОБНОВИТЬ'"
		empty_label.horizontal_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 18)
		content_container.add_child(empty_label)
		return
	
	var card = Panel.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.03
	margin.anchor_top = 0.03
	margin.anchor_right = 0.97
	margin.anchor_bottom = 0.97
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	for i in range(list_to_show.size()):
		var player = list_to_show[i]
		var rank_prefix = get_rank_prefix(i)
		
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)
		
		var num_label = Label.new()
		num_label.text = rank_prefix + str(i + 1) + "."
		num_label.add_theme_color_override("font_color", Color(1, 0.84, 0) if i < 3 else Color(0.8, 0.8, 0.8))
		num_label.add_theme_font_size_override("font_size", 18 if i < 3 else 15)
		hbox.add_child(num_label)
		
		var name_label = Label.new()
		var display_name = player["name"]
		if player.get("is_bot", false):
			display_name = "🤖 " + display_name
		elif display_name == player_data.get("name", ""):
			display_name = "⭐ " + display_name + " (Вы)"
		
		name_label.text = display_name
		name_label.add_theme_color_override("font_color", Color(1, 0.84, 0) if i < 3 else Color(0.9, 0.9, 0.9))
		name_label.add_theme_font_size_override("font_size", 18 if i < 3 else 15)
		hbox.add_child(name_label)
		
		# Очки
		var value = 0
		match current_tab:
			"level":
				value = player["level"]
			"pvp":
				value = player["pvp_wins"]
			"monsters":
				value = player["monsters"]
			"gold":
				value = player["gold"]
		
		var value_str = ""
		if current_tab == "gold":
			value_str = format_number(value) + "💰"
		else:
			value_str = str(value)
		
		var value_label = Label.new()
		value_label.text = " — " + value_str + " " + value_name
		value_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5) if i < 3 else Color(0.7, 0.7, 0.7))
		value_label.add_theme_font_size_override("font_size", 18 if i < 3 else 15)
		hbox.add_child(value_label)
		
		# Уровень (только для вкладки "УРОВЕНЬ" показываем дополнительно)
		if current_tab == "level":
			var level_label = Label.new()
			level_label.text = " [Уровень " + str(player["level"]) + "]"
			level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
			level_label.add_theme_font_size_override("font_size", 15)
			hbox.add_child(level_label)
		
		# Разделитель после 3-го места
		if i == 2 and list_to_show.size() > 3:
			var sep_line = HSeparator.new()
			sep_line.modulate = Color(1, 0.84, 0, 0.3)
			sep_line.custom_minimum_size.y = 10
			vbox.add_child(sep_line)
	
	content_container.add_child(card)

func _on_network_data(data: String):
	var parts = data.split("|")
	match parts[0]:
		"HALL_OF_FAME":
			var category = parts[1]
			var json_str = parts[2]
			var json = JSON.new()
			if json.parse(json_str) == OK:
				top_players[category] = json.data
				if current_tab == category:
					update_ui()
				_show_message("Данные обновлены!")

func _show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Зал славы"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	if NetworkManager and NetworkManager.current_mode == "local":
		generate_bot_top()
	update_ui()

func _on_close():
	queue_free()
