# res://modules/my_quests.gd
extends Panel

var close_btn
var content_container
var player_data = {}
var active_quests = {}
var guild_ref = null

var card_style
var detail_popup = null
var selected_quest = null

func _ready():
	build_ui()
	load_data()
	load_active_quests()
	update_list()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

func build_ui():
	anchor_left = 0.1
	anchor_top = 0.05
	anchor_right = 0.9
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
	title.text = "📋 МОИ ЗАДАНИЯ"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var info_label = Label.new()
	info_label.text = "Активные задания (" + str(active_quests.size()) + ")"
	info_label.horizontal_alignment = 1
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(info_label)
	
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

func load_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {"name": "Игрок", "level": 1}

func load_active_quests():
	active_quests.clear()
	if player_data.has("active_quests"):
		for q in player_data["active_quests"]:
			active_quests[q["id"]] = q

func save_active_quests():
	player_data["active_quests"] = []
	for quest_id in active_quests:
		player_data["active_quests"].append(active_quests[quest_id])
	
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.emit(player_data)

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

func update_list():
	for child in content_container.get_children():
		child.queue_free()
	
	# Обновляем счётчик
	var info_label = get_node_or_null("../VBox/InfoLabel")
	if info_label:
		info_label.text = "Активные задания (" + str(active_quests.size()) + ")"
	
	if active_quests.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "У вас нет принятых заданий.\n\nЗайдите в Гильдию → Доска заданий"
		empty_label.horizontal_alignment = 1
		empty_label.vertical_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 14)
		content_container.add_child(empty_label)
		return
	
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		var card = create_quest_card(quest)
		content_container.add_child(card)

func create_quest_card(quest: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 95
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.05
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.95
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = quest.get("icon", "📋")
	icon_label.custom_minimum_size = Vector2(45, 45)
	icon_label.add_theme_font_size_override("font_size", 30)
	title_hbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = quest["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 15)
	title_hbox.add_child(name_label)
	
	var rank_label = Label.new()
	rank_label.text = "[" + quest["rank"] + "]"
	rank_label.add_theme_color_override("font_color", get_rank_color(quest["rank"]))
	rank_label.add_theme_font_size_override("font_size", 12)
	title_hbox.add_child(rank_label)
	
	var type_icon = "🗡️" if quest["type"] == "kill" else "📦"
	var desc_label = Label.new()
	desc_label.text = type_icon + " " + str(quest["target_count"]) + "x " + quest["target_name"] + " (" + quest["location"] + ")"
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	
	var progress = float(quest["current_count"]) / float(quest["target_count"])
	var percent = int(progress * 100)
	
	var progress_hbox = HBoxContainer.new()
	progress_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(progress_hbox)
	
	var progress_label = Label.new()
	progress_label.text = "Прогресс: " + str(quest["current_count"]) + "/" + str(quest["target_count"]) + " (" + str(percent) + "%)"
	progress_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_hbox.add_child(progress_label)
	
	var reward_hbox = HBoxContainer.new()
	reward_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(reward_hbox)
	
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
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)
	
	var detail_btn = Button.new()
	detail_btn.text = "ПОДРОБНЕЕ"
	detail_btn.custom_minimum_size = Vector2(110, 32)
	detail_btn.pressed.connect(_show_quest_detail.bind(quest))
	btn_hbox.add_child(detail_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНИТЬ"
	cancel_btn.custom_minimum_size = Vector2(110, 32)
	cancel_btn.modulate = Color(1, 0.5, 0.5)
	cancel_btn.pressed.connect(_cancel_quest.bind(quest["id"]))
	btn_hbox.add_child(cancel_btn)
	
	return card

func _show_quest_detail(quest: Dictionary):
	selected_quest = quest
	
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.15
	detail_popup.anchor_top = 0.1
	detail_popup.anchor_right = 0.85
	detail_popup.anchor_bottom = 0.65
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
	icon.add_theme_font_size_override("font_size", 36)
	title_row.add_child(icon)
	
	var title = Label.new()
	title.text = quest["name"]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 20)
	title_row.add_child(title)
	
	var close_detail = Button.new()
	close_detail.text = "×"
	close_detail.custom_minimum_size = Vector2(35, 35)
	close_detail.pressed.connect(_close_detail)
	title_row.add_child(close_detail)
	
	var info_row = HBoxContainer.new()
	vbox.add_child(info_row)
	
	var rank_text = Label.new()
	rank_text.text = "Ранг: " + quest["rank"] + " | Треб. уровень: " + str(quest["level_required"])
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
	quest_text.text = type_word + " " + str(quest["target_count"]) + " " + quest["target_name"]
	quest_text.add_theme_font_size_override("font_size", 14)
	vbox.add_child(quest_text)
	
	var progress_percent = float(quest["current_count"]) / float(quest["target_count"]) * 100
	var progress_text = Label.new()
	progress_text.text = "Прогресс: " + str(quest["current_count"]) + "/" + str(quest["target_count"]) + " (" + str(int(progress_percent)) + "%)"
	progress_text.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	progress_text.add_theme_font_size_override("font_size", 13)
	vbox.add_child(progress_text)
	
	var reward_title = Label.new()
	reward_title.text = "Награда:"
	reward_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	reward_title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(reward_title)
	
	var rewards = Label.new()
	rewards.text = "⭐ Опыт: " + str(quest["reward_exp"]) + "\n💰 Золото: " + str(quest["reward_gold"]) + "\n🏅 Очки заданий: " + str(quest["reward_points"])
	rewards.add_theme_font_size_override("font_size", 12)
	vbox.add_child(rewards)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНИТЬ ЗАДАНИЕ"
	cancel_btn.custom_minimum_size = Vector2(180, 45)
	cancel_btn.modulate = Color(1, 0.5, 0.5)
	cancel_btn.pressed.connect(_cancel_quest.bind(quest["id"]))
	btn_hbox.add_child(cancel_btn)
	
	var ok_btn = Button.new()
	ok_btn.text = "ЗАКРЫТЬ"
	ok_btn.custom_minimum_size = Vector2(120, 45)
	ok_btn.pressed.connect(_close_detail)
	btn_hbox.add_child(ok_btn)

func _cancel_quest(quest_id: String):
	if active_quests.has(quest_id):
		active_quests.erase(quest_id)
		save_active_quests()
		update_list()
		
		# Обновляем также в quests.gd (если открыта)
		var quests_module = get_node_or_null("/root/QuestsModule")
		if quests_module:
			quests_module.update_quest_cancel(quest_id)
		
		_show_message("Задание отменено!")
	
	_close_detail()

func _close_detail():
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	selected_quest = null

func _show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Мои задания"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	load_active_quests()
	update_list()

func _on_close():
	if detail_popup:
		detail_popup.queue_free()
	queue_free()
