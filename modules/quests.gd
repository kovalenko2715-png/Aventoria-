# res://modules/quests.gd
extends Panel

var guild_ref = null
var close_btn
var tabs_container
var content_container
var current_tab = "daily"

var all_quests = []
var daily_quests = []
var weekly_quests = []
var active_quests = {}

var player_data = {}
var card_style
var detail_popup = null
var selected_quest = null

var quest_timer = null

var mobs_db = {
	"rat": {"name": "Крыса", "location": "cave", "location_name": "Пещера", "rank": "F", "level_req": 1, "item": "rat_tail", "item_name": "Крысиный хвост", "icon": "🐀"},
	"skel": {"name": "Скелет", "location": "crypt", "location_name": "Склеп", "rank": "E", "level_req": 5, "item": "bone", "item_name": "Кость", "icon": "💀"},
	"wolf": {"name": "Волк", "location": "dark_forest", "location_name": "Тёмный лес", "rank": "F", "level_req": 1, "item": "wolf_fur", "item_name": "Волчья шкура", "icon": "🐺"},
	"orc": {"name": "Орк", "location": "green_meadow", "location_name": "Зелёные луга", "rank": "D", "level_req": 15, "item": "orc_tusk", "item_name": "Клык орка", "icon": "👹"},
	"ghost": {"name": "Призрак", "location": "old_mansion", "location_name": "Заброшенный особняк", "rank": "C", "level_req": 20, "item": "ghost_essence", "item_name": "Призрачная эссенция", "icon": "👻"},
	"golem": {"name": "Голем", "location": "ruins", "location_name": "Древние руины", "rank": "B", "level_req": 30, "item": "golem_core", "item_name": "Ядро голема", "icon": "🗿"},
	"dragon": {"name": "Дракон", "location": "tower", "location_name": "Башня мага", "rank": "A", "level_req": 40, "item": "dragon_scale", "item_name": "Чешуя дракона", "icon": "🐉"},
	"demon": {"name": "Демон", "location": "castle", "location_name": "Замок", "rank": "S", "level_req": 50, "item": "demon_heart", "item_name": "Сердце демона", "icon": "😈"}
}

var kill_counts = [1, 2, 3, 5, 8, 10, 15, 20]
var collect_counts = [1, 2, 3, 5, 8, 10, 15, 20]

func set_guild_reference(guild):
	guild_ref = guild

func _ready():
	build_ui()
	load_data()
	generate_all_quests()
	load_active_quests()
	generate_daily_quests()
	generate_weekly_quests()
	update_ui()
	
	close_btn.pressed.connect(_on_close)
	
	quest_timer = Timer.new()
	quest_timer.wait_time = 1.0
	quest_timer.timeout.connect(_update_all_timers)
	add_child(quest_timer)
	quest_timer.start()
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

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
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)
	
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "📋 ДОСКА ЗАДАНИЙ"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 22)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(35, 35)
	top_panel.add_child(close_btn)
	
	tabs_container = HBoxContainer.new()
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_container.add_theme_constant_override("separation", 10)
	main_vbox.add_child(tabs_container)
	
	var daily_btn = Button.new()
	daily_btn.text = "ЕЖЕДНЕВНЫЕ"
	daily_btn.custom_minimum_size = Vector2(120, 35)
	daily_btn.pressed.connect(_on_tab_pressed.bind("daily"))
	tabs_container.add_child(daily_btn)
	
	var weekly_btn = Button.new()
	weekly_btn.text = "ЕЖЕНЕДЕЛЬНЫЕ"
	weekly_btn.custom_minimum_size = Vector2(120, 35)
	weekly_btn.pressed.connect(_on_tab_pressed.bind("weekly"))
	tabs_container.add_child(weekly_btn)
	
	var all_btn = Button.new()
	all_btn.text = "ВСЕ ЗАДАНИЯ"
	all_btn.custom_minimum_size = Vector2(120, 35)
	all_btn.pressed.connect(_on_tab_pressed.bind("all"))
	tabs_container.add_child(all_btn)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1, 0.84, 0, 0.3)
	main_vbox.add_child(sep)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 6)
	scroll.add_child(content_container)

func _on_tab_pressed(tab: String):
	current_tab = tab
	update_ui()

func generate_all_quests():
	all_quests = []
	var quest_id = 1
	
	for mob_id in mobs_db:
		var mob = mobs_db[mob_id]
		
		for count in kill_counts:
			all_quests.append({
				"id": "q_" + str(quest_id),
				"name": mob["name"] + " (" + str(count) + ")",
				"type": "kill",
				"rank": mob["rank"],
				"level_required": mob["level_req"],
				"location": mob["location_name"],
				"target_id": mob_id,
				"target_name": mob["name"],
				"target_count": count,
				"current_count": 0,
				"reward_exp": count * 10,
				"reward_gold": count * 20,
				"reward_points": max(1, int(count / 5)),
				"icon": mob["icon"],
				"completed": false,
				"accepted": false,
				"expires_at": 0
			})
			quest_id += 1
		
		for count in collect_counts:
			all_quests.append({
				"id": "q_" + str(quest_id),
				"name": mob["item_name"] + " (" + str(count) + ")",
				"type": "collect",
				"rank": mob["rank"],
				"level_required": mob["level_req"],
				"location": mob["location_name"],
				"target_id": mob["item"],
				"target_name": mob["item_name"],
				"target_count": count,
				"current_count": 0,
				"reward_exp": count * 8,
				"reward_gold": count * 15,
				"reward_points": max(1, int(count / 5)),
				"icon": "📦",
				"completed": false,
				"accepted": false,
				"expires_at": 0
			})
			quest_id += 1

func generate_daily_quests():
	daily_quests = []
	var available = []
	for q in all_quests:
		if q["rank"] in ["F", "E", "D"]:
			var new_q = q.duplicate()
			var random_minutes = randi() % 41 + 20
			new_q["expires_at"] = Time.get_unix_time_from_system() + (random_minutes * 60)
			available.append(new_q)
	available.shuffle()
	for i in range(min(8, available.size())):
		daily_quests.append(available[i])

func generate_weekly_quests():
	weekly_quests = []
	var available = []
	for q in all_quests:
		if q["rank"] in ["C", "B", "A", "S"]:
			var new_q = q.duplicate()
			var random_days = randi() % 7 + 1
			new_q["expires_at"] = Time.get_unix_time_from_system() + (random_days * 86400)
			available.append(new_q)
	available.shuffle()
	for i in range(min(4, available.size())):
		weekly_quests.append(available[i])

func load_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {"name": "Игрок", "level": 1}

func load_active_quests():
	if player_data.has("active_quests"):
		var saved = player_data["active_quests"]
		active_quests.clear()
		for q in saved:
			active_quests[q["id"]] = q
	
	for quest in all_quests:
		if quest["id"] in active_quests:
			quest["current_count"] = active_quests[quest["id"]]["current_count"]
			quest["accepted"] = true
			if quest["current_count"] >= quest["target_count"]:
				quest["completed"] = true

func save_active_quests():
	player_data["active_quests"] = []
	for quest_id in active_quests:
		player_data["active_quests"].append(active_quests[quest_id])
	
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()

func get_rank_color(rank: String) -> Color:
	match rank:
		"F": return Color(0.6, 0.6, 0.6)
		"E": return Color(0.3, 0.7, 0.3)
		"D": return Color(0.3, 0.5, 1)
		"C": return Color(0.5, 0.3, 1)
		"B": return Color(1, 0.5, 0)
		"A": return Color(1, 0.3, 0.3)
		"S": return Color(1, 0.8, 0)
		_: return Color(1, 1, 1)

func get_player_level() -> int:
	return player_data.get("level", 1)

func _update_all_timers():
	for child in content_container.get_children():
		var timer_label = child.get_meta("timer_label", null)
		var expires_at = child.get_meta("expires_at", 0)
		
		if timer_label and expires_at > 0:
			var remaining = expires_at - Time.get_unix_time_from_system()
			if remaining <= 0:
				timer_label.text = "⏰ Задание скоро обновится"
				timer_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			else:
				var remaining_int = int(remaining)
				var minutes = remaining_int / 60
				var seconds = remaining_int % 60
				timer_label.text = "⏰ До обновления: " + str(minutes) + " мин " + str(seconds) + " сек"
				timer_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

func update_ui():
	for child in content_container.get_children():
		child.queue_free()
	
	var quests_to_show = []
	
	match current_tab:
		"daily":
			quests_to_show = daily_quests
		"weekly":
			quests_to_show = weekly_quests
		"all":
			quests_to_show = all_quests
	
	for quest in quests_to_show:
		var card = create_quest_card(quest)
		content_container.add_child(card)

func create_quest_card(quest: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 75
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
	
	var icon_label = Label.new()
	icon_label.text = quest.get("icon", "📋")
	icon_label.custom_minimum_size = Vector2(45, 45)
	icon_label.add_theme_font_size_override("font_size", 30)
	icon_label.horizontal_alignment = 1
	hbox.add_child(icon_label)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)
	
	var title_hbox = HBoxContainer.new()
	info_vbox.add_child(title_hbox)
	
	var name_label = Label.new()
	name_label.text = quest["name"]
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 14)
	title_hbox.add_child(name_label)
	
	var rank_label = Label.new()
	rank_label.text = "[" + quest["rank"] + "]"
	rank_label.add_theme_color_override("font_color", get_rank_color(quest["rank"]))
	rank_label.add_theme_font_size_override("font_size", 11)
	title_hbox.add_child(rank_label)
	
	var type_icon = "🗡️" if quest["type"] == "kill" else "📦"
	var desc_label = Label.new()
	desc_label.text = type_icon + " " + str(quest["target_count"]) + "x " + quest["target_name"] + " (" + quest["location"] + ")"
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(desc_label)
	
	var reward_hbox = HBoxContainer.new()
	reward_hbox.add_theme_constant_override("separation", 15)
	info_vbox.add_child(reward_hbox)
	
	var exp_label = Label.new()
	exp_label.text = "⭐" + str(quest["reward_exp"])
	exp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	exp_label.add_theme_font_size_override("font_size", 11)
	reward_hbox.add_child(exp_label)
	
	var gold_label = Label.new()
	gold_label.text = "💰" + str(quest["reward_gold"])
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	gold_label.add_theme_font_size_override("font_size", 11)
	reward_hbox.add_child(gold_label)
	
	var points_label = Label.new()
	points_label.text = "🏅" + str(quest["reward_points"])
	points_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	points_label.add_theme_font_size_override("font_size", 11)
	reward_hbox.add_child(points_label)
	
	if quest.get("expires_at", 0) > 0:
		var remaining = quest["expires_at"] - Time.get_unix_time_from_system()
		var timer_label = Label.new()
		timer_label.add_theme_font_size_override("font_size", 12)
		
		if remaining > 0:
			var remaining_int = int(remaining)
			var minutes = remaining_int / 60
			var seconds = remaining_int % 60
			timer_label.text = "⏰ До обновления: " + str(minutes) + " мин " + str(seconds) + " сек"
			timer_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		else:
			timer_label.text = "⏰ Задание скоро обновится"
			timer_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		info_vbox.add_child(timer_label)
		card.set_meta("timer_label", timer_label)
		card.set_meta("expires_at", quest["expires_at"])
	
	var player_level = get_player_level()
	var is_available = player_level >= quest["level_required"]
	var is_accepted = quest.get("accepted", false)
	var is_completed = quest.get("completed", false)
	
	var action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(70, 32)
	
	if is_completed:
		action_btn.text = "✓"
		action_btn.disabled = true
	elif is_accepted:
		var percent = float(quest["current_count"]) / float(quest["target_count"]) * 100
		action_btn.text = str(int(percent)) + "%"
		action_btn.disabled = true
	elif not is_available:
		action_btn.text = str(quest["level_required"])
		action_btn.disabled = true
	else:
		action_btn.text = "📖"
		action_btn.pressed.connect(_show_quest_detail.bind(quest))
	
	hbox.add_child(action_btn)
	
	return card

func _show_quest_detail(quest: Dictionary):
	selected_quest = quest
	
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.15
	detail_popup.anchor_top = 0.1
	detail_popup.anchor_right = 0.85
	detail_popup.anchor_bottom = 0.6
	add_child(detail_popup)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.98)
	style.border_color = get_rank_color(quest["rank"])
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	detail_popup.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.03
	margin.anchor_top = 0.03
	margin.anchor_right = 0.97
	margin.anchor_bottom = 0.97
	detail_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title_row = HBoxContainer.new()
	vbox.add_child(title_row)
	
	var icon = Label.new()
	icon.text = quest.get("icon", "📋")
	icon.add_theme_font_size_override("font_size", 32)
	title_row.add_child(icon)
	
	var title = Label.new()
	title.text = quest["name"]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 18)
	title_row.add_child(title)
	
	var close_detail = Button.new()
	close_detail.text = "×"
	close_detail.custom_minimum_size = Vector2(30, 30)
	close_detail.pressed.connect(_close_detail)
	title_row.add_child(close_detail)
	
	var info_row = HBoxContainer.new()
	vbox.add_child(info_row)
	
	var rank_text = Label.new()
	rank_text.text = "Ранг: " + quest["rank"] + " | Ур.: " + str(quest["level_required"])
	rank_text.add_theme_color_override("font_color", get_rank_color(quest["rank"]))
	rank_text.add_theme_font_size_override("font_size", 12)
	info_row.add_child(rank_text)
	
	var location_text = Label.new()
	location_text.text = "📍 " + quest["location"]
	location_text.add_theme_color_override("font_color", Color(0.6, 0.8, 1))
	location_text.add_theme_font_size_override("font_size", 12)
	info_row.add_child(location_text)
	
	var sep_line = HSeparator.new()
	sep_line.modulate = Color(1, 0.84, 0, 0.3)
	vbox.add_child(sep_line)
	
	var type_word = "Убить" if quest["type"] == "kill" else "Собрать"
	var quest_text = Label.new()
	quest_text.text = type_word + " " + str(quest["target_count"]) + " " + quest["target_name"] + " в локации " + quest["location"]
	quest_text.add_theme_font_size_override("font_size", 14)
	quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(quest_text)
	
	var reward_title = Label.new()
	reward_title.text = "Награда:"
	reward_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	reward_title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(reward_title)
	
	var rewards = Label.new()
	rewards.text = "⭐ " + str(quest["reward_exp"]) + " опыта\n💰 " + str(quest["reward_gold"]) + " золота\n🏅 " + str(quest["reward_points"]) + " очков заданий"
	rewards.add_theme_font_size_override("font_size", 12)
	vbox.add_child(rewards)
	
	if quest.get("expires_at", 0) > 0:
		var timer_info = Label.new()
		var remaining = quest["expires_at"] - Time.get_unix_time_from_system()
		if remaining > 0:
			var remaining_int = int(remaining)
			var hours = remaining_int / 3600
			var minutes = (remaining_int % 3600) / 60
			timer_info.text = "⏰ Задание исчезнет через: " + str(hours) + " ч " + str(minutes) + " мин"
		else:
			timer_info.text = "⏰ Задание скоро исчезнет"
		timer_info.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		timer_info.add_theme_font_size_override("font_size", 12)
		vbox.add_child(timer_info)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var accept_btn = Button.new()
	accept_btn.text = "ПРИНЯТЬ"
	accept_btn.custom_minimum_size = Vector2(120, 35)
	accept_btn.pressed.connect(_accept_quest)
	btn_hbox.add_child(accept_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(120, 35)
	cancel_btn.pressed.connect(_close_detail)
	btn_hbox.add_child(cancel_btn)

func _accept_quest():
	if selected_quest == null:
		return
	
	if get_player_level() < selected_quest["level_required"]:
		_show_message("Требуется уровень " + str(selected_quest["level_required"]))
		return
	
	selected_quest["accepted"] = true
	active_quests[selected_quest["id"]] = selected_quest
	save_active_quests()
	
	_close_detail()
	update_ui()
	_show_message("Задание принято!")

func _close_detail():
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	selected_quest = null

func _show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Доска заданий"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func update_quest_progress(monster_id: String, count: int = 1):
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		if quest["type"] == "kill" and quest["target_id"] == monster_id and not quest["completed"]:
			quest["current_count"] += count
			if quest["current_count"] >= quest["target_count"]:
				quest["completed"] = true
				_complete_quest(quest)
			
			for q in all_quests:
				if q["id"] == quest_id:
					q["current_count"] = quest["current_count"]
					q["completed"] = quest["completed"]
					break
			
			save_active_quests()
			update_ui()
			break

func update_collect_progress(item_id: String, count: int = 1):
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		if quest["type"] == "collect" and quest["target_id"] == item_id and not quest["completed"]:
			quest["current_count"] += count
			if quest["current_count"] >= quest["target_count"]:
				quest["completed"] = true
				_complete_quest(quest)
			
			for q in all_quests:
				if q["id"] == quest_id:
					q["current_count"] = quest["current_count"]
					q["completed"] = quest["completed"]
					break
			
			save_active_quests()
			update_ui()
			break

func _complete_quest(quest: Dictionary):
	player_data["gold"] = player_data.get("gold", 0) + quest["reward_gold"]
	player_data["exp"] = player_data.get("exp", 0) + quest["reward_exp"]
	
	if guild_ref:
		guild_ref.add_quest_points(quest["reward_points"])
	
	active_quests.erase(quest["id"])
	save_active_quests()
	
	_show_message("Выполнено! +" + str(quest["reward_gold"]) + "💰, +" + str(quest["reward_exp"]) + "⭐, +" + str(quest["reward_points"]) + "🏅")

func update_quest_cancel(quest_id: String):
	for q in all_quests:
		if q["id"] == quest_id:
			q["accepted"] = false
			q["current_count"] = 0
			q["completed"] = false
			break
	
	for q in daily_quests:
		if q["id"] == quest_id:
			q["accepted"] = false
			q["current_count"] = 0
			q["completed"] = false
			break
	
	for q in weekly_quests:
		if q["id"] == quest_id:
			q["accepted"] = false
			q["current_count"] = 0
			q["completed"] = false
			break
	
	update_ui()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	load_active_quests()
	update_ui()

func _on_close():
	if quest_timer:
		quest_timer.stop()
	queue_free()
