# res://modules/mail.gd
extends Panel

# =============================================================================
# ПОЧТА - Входящие, исходящие, отправка писем (локальный + онлайн режим)
# =============================================================================

var close_btn
var tabs_container
var content_container
var write_window = null
var read_window = null

var player_data = {}
var incoming_mails = []
var outgoing_mails = []

var current_tab = "inbox"
var card_style

var sync_timer = null

# База предметов для вложений
var items_db = {
	"health_potion": {"name": "Зелье здоровья", "icon": "🧪"},
	"gold": {"name": "Золото", "icon": "💰"},
	"iron_sword": {"name": "Железный меч", "icon": "⚔️"},
	"leather_armor": {"name": "Кожаная броня", "icon": "🛡️"}
}

func _ready():
	build_ui()
	load_player_data()
	load_mails()
	update_mails_list()
	
	close_btn.pressed.connect(_on_close)
	
	# Запускаем таймер синхронизации для онлайн-режима
	if NetworkManager and NetworkManager.current_mode == "server":
		sync_timer = Timer.new()
		sync_timer.wait_time = 30.0
		sync_timer.timeout.connect(_sync_with_server)
		add_child(sync_timer)
		sync_timer.start()
		_sync_with_server()
	
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
	title.text = "📧 ПОЧТА 📧"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	tabs_container = HBoxContainer.new()
	tabs_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_container.add_theme_constant_override("separation", 20)
	main_vbox.add_child(tabs_container)
	
	var inbox_btn = Button.new()
	inbox_btn.text = "📥 ВХОДЯЩИЕ"
	inbox_btn.custom_minimum_size = Vector2(140, 40)
	inbox_btn.pressed.connect(_on_tab_pressed.bind("inbox"))
	tabs_container.add_child(inbox_btn)
	
	var outgoing_btn = Button.new()
	outgoing_btn.text = "📤 ИСХОДЯЩИЕ"
	outgoing_btn.custom_minimum_size = Vector2(140, 40)
	outgoing_btn.pressed.connect(_on_tab_pressed.bind("outgoing"))
	tabs_container.add_child(outgoing_btn)
	
	var write_btn = Button.new()
	write_btn.text = "✏️ НАПИСАТЬ"
	write_btn.custom_minimum_size = Vector2(140, 40)
	write_btn.pressed.connect(_open_write_window)
	tabs_container.add_child(write_btn)
	
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

func _on_tab_pressed(tab: String):
	current_tab = tab
	update_mails_list()

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {"name": "Игрок", "gold": 1000, "level": 1}

func load_mails():
	if player_data.has("incoming_mails"):
		incoming_mails = player_data["incoming_mails"]
	else:
		if NetworkManager and NetworkManager.current_mode == "server":
			incoming_mails = []
		else:
			# Тестовые письма только для локального режима
			incoming_mails = [
				{
					"id": "1",
					"from": "Система",
					"subject": "Добро пожаловать!",
					"message": "Рады видеть тебя в игре! Надеемся, тебе понравится наше приключение.",
					"attachment": null,
					"is_read": false,
					"sent_at": Time.get_unix_time_from_system() - 86400,
					"has_attachment": false
				},
				{
					"id": "2",
					"from": "Гильдия",
					"subject": "Награда за задание",
					"message": "Поздравляем! Вы выполнили задание 'Крысиная угроза'. В награду вы получаете 100 золота.",
					"attachment": {"type": "gold", "item_id": "gold", "name": "Золото", "quantity": 100, "icon": "💰"},
					"is_read": false,
					"sent_at": Time.get_unix_time_from_system() - 43200,
					"has_attachment": true
				}
			]
		player_data["incoming_mails"] = incoming_mails
	
	if player_data.has("outgoing_mails"):
		outgoing_mails = player_data["outgoing_mails"]
	else:
		outgoing_mails = []
		player_data["outgoing_mails"] = outgoing_mails

func save_mails():
	player_data["incoming_mails"] = incoming_mails
	player_data["outgoing_mails"] = outgoing_mails
	if NetworkManager and NetworkManager.current_mode == "local":
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()

func _sync_with_server():
	if NetworkManager and NetworkManager.current_mode == "server":
		NetworkManager.send("GET_MAILS")

func _on_network_data(data: String):
	var parts = data.split("|")
	match parts[0]:
		"MAILS_DATA":
			var json = JSON.new()
			if json.parse(parts[1]) == OK:
				var mail_data = json.data
				incoming_mails = mail_data.get("incoming", [])
				outgoing_mails = mail_data.get("outgoing", [])
				player_data["incoming_mails"] = incoming_mails
				player_data["outgoing_mails"] = outgoing_mails
				update_mails_list()
		"MAIL_SEND_OK":
			_show_message("Письмо отправлено!")
			_sync_with_server()
		"MAIL_SEND_FAIL":
			_show_message("Не удалось отправить письмо!")
		"MAIL_DELETE_OK":
			_sync_with_server()
		"MAIL_TAKE_ATTACHMENT_OK":
			_sync_with_server()
			_show_message("Вложение получено!")

func update_mails_list():
	for child in content_container.get_children():
		child.queue_free()
	
	var mails_to_show = incoming_mails if current_tab == "inbox" else outgoing_mails
	
	if mails_to_show.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "📭 Писем нет"
		empty_label.horizontal_alignment = 1
		empty_label.vertical_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 18)
		content_container.add_child(empty_label)
		return
	
	for mail in mails_to_show:
		var card = create_mail_card(mail)
		content_container.add_child(card)

func create_mail_card(mail: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 80
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", card_style)
	
	var is_read = mail.get("is_read", false)
	var has_attachment = mail.get("has_attachment", mail.get("attachment", null) != null)
	
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
	icon_label.text = "📧" if not has_attachment else "📎"
	icon_label.custom_minimum_size = Vector2(45, 45)
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.horizontal_alignment = 1
	hbox.add_child(icon_label)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)
	
	var title_hbox = HBoxContainer.new()
	info_vbox.add_child(title_hbox)
	
	var status_icon = Label.new()
	status_icon.text = "🟢" if not is_read else "⚪"
	status_icon.add_theme_font_size_override("font_size", 12)
	title_hbox.add_child(status_icon)
	
	var from_label = Label.new()
	from_label.text = mail["from"]
	from_label.add_theme_color_override("font_color", Color(1, 0.84, 0) if not is_read else Color(0.7, 0.7, 0.7))
	from_label.add_theme_font_size_override("font_size", 14)
	title_hbox.add_child(from_label)
	
	var subject_label = Label.new()
	subject_label.text = " — " + mail["subject"]
	subject_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	subject_label.add_theme_font_size_override("font_size", 12)
	title_hbox.add_child(subject_label)
	
	var date_label = Label.new()
	var sent_time = mail.get("sent_at", 0)
	if sent_time > 0:
		var date = Time.get_datetime_dict_from_unix_time(sent_time)
		date_label.text = "📅 " + str(date["day"]) + "." + str(date["month"]) + " " + str(date["hour"]) + ":" + str(date["minute"]).pad_zeros(2)
	else:
		date_label.text = "📅 Дата неизвестна"
	date_label.add_theme_font_size_override("font_size", 10)
	date_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(date_label)
	
	if has_attachment:
		var attach_label = Label.new()
		var attach = mail.get("attachment", {})
		var attach_name = attach.get("name", "Предмет")
		attach_label.text = "📎 Вложение: " + attach_name + " x" + str(attach.get("quantity", 1))
		attach_label.add_theme_font_size_override("font_size", 10)
		attach_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		info_vbox.add_child(attach_label)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(btn_vbox)
	
	var read_btn = Button.new()
	read_btn.text = "📖 ЧИТАТЬ"
	read_btn.custom_minimum_size = Vector2(90, 30)
	read_btn.pressed.connect(_read_mail.bind(mail))
	btn_vbox.add_child(read_btn)
	
	var delete_btn = Button.new()
	delete_btn.text = "🗑️ УДАЛИТЬ"
	delete_btn.custom_minimum_size = Vector2(90, 30)
	delete_btn.modulate = Color(1, 0.5, 0.5)
	delete_btn.pressed.connect(_delete_mail.bind(mail))
	btn_vbox.add_child(delete_btn)
	
	return card

func _read_mail(mail: Dictionary):
	if not mail.get("is_read", false):
		mail["is_read"] = true
		
		if NetworkManager and NetworkManager.current_mode == "server":
			NetworkManager.send("MARK_MAIL_READ|" + mail["id"])
		else:
			save_mails()
		
		update_mails_list()
	
	_open_read_window(mail)

func _open_read_window(mail: Dictionary):
	if read_window and is_instance_valid(read_window):
		read_window.queue_free()
	
	read_window = Panel.new()
	read_window.anchor_left = 0.12
	read_window.anchor_top = 0.08
	read_window.anchor_right = 0.88
	read_window.anchor_bottom = 0.92
	add_child(read_window)
	
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
	read_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.03
	margin.anchor_top = 0.03
	margin.anchor_right = 0.97
	margin.anchor_bottom = 0.97
	read_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = "📧"
	icon_label.add_theme_font_size_override("font_size", 32)
	title_hbox.add_child(icon_label)
	
	var title_label = Label.new()
	title_label.text = mail["subject"]
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title_label.add_theme_font_size_override("font_size", 22)
	title_hbox.add_child(title_label)
	
	var close_btn_popup = Button.new()
	close_btn_popup.text = "×"
	close_btn_popup.custom_minimum_size = Vector2(35, 35)
	close_btn_popup.pressed.connect(read_window.queue_free)
	title_hbox.add_child(close_btn_popup)
	
	var info_label = Label.new()
	var sent_time = mail.get("sent_at", 0)
	if sent_time > 0:
		var date = Time.get_datetime_dict_from_unix_time(sent_time)
		info_label.text = "От: " + mail["from"] + " | " + str(date["day"]) + "." + str(date["month"]) + "." + str(date["year"]) + " " + str(date["hour"]) + ":" + str(date["minute"]).pad_zeros(2)
	else:
		info_label.text = "От: " + mail["from"]
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(info_label)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1, 0.84, 0, 0.3)
	vbox.add_child(sep)
	
	var message_label = Label.new()
	message_label.text = mail["message"]
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(message_label)
	
	var attachment = mail.get("attachment", null)
	if attachment:
		var attach_frame = Panel.new()
		var attach_style = StyleBoxFlat.new()
		attach_style.bg_color = Color(0.12, 0.1, 0.08, 0.7)
		attach_style.border_color = Color(0.5, 0.9, 0.5, 0.3)
		attach_style.border_width_left = 1
		attach_style.border_width_right = 1
		attach_style.border_width_top = 1
		attach_style.border_width_bottom = 1
		attach_style.corner_radius_top_left = 5
		attach_style.corner_radius_top_right = 5
		attach_style.corner_radius_bottom_left = 5
		attach_style.corner_radius_bottom_right = 5
		attach_frame.add_theme_stylebox_override("panel", attach_style)
		vbox.add_child(attach_frame)
		
		var attach_margin = MarginContainer.new()
		attach_margin.anchor_left = 0.02
		attach_margin.anchor_top = 0.05
		attach_margin.anchor_right = 0.98
		attach_margin.anchor_bottom = 0.95
		attach_frame.add_child(attach_margin)
		
		var attach_hbox = HBoxContainer.new()
		attach_hbox.add_theme_constant_override("separation", 15)
		attach_margin.add_child(attach_hbox)
		
		var attach_icon = Label.new()
		attach_icon.text = attachment.get("icon", "📦")
		attach_icon.add_theme_font_size_override("font_size", 28)
		attach_hbox.add_child(attach_icon)
		
		var attach_info = VBoxContainer.new()
		attach_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		attach_hbox.add_child(attach_info)
		
		var attach_name = Label.new()
		attach_name.text = attachment.get("name", "Предмет")
		attach_name.add_theme_color_override("font_color", Color(1, 0.84, 0))
		attach_name.add_theme_font_size_override("font_size", 14)
		attach_info.add_child(attach_name)
		
		var attach_qty = Label.new()
		attach_qty.text = "Количество: x" + str(attachment.get("quantity", 1))
		attach_qty.add_theme_font_size_override("font_size", 12)
		attach_info.add_child(attach_qty)
		
		var take_btn = Button.new()
		take_btn.text = "ЗАБРАТЬ"
		take_btn.custom_minimum_size = Vector2(100, 35)
		take_btn.pressed.connect(_take_attachment.bind(mail, attachment, read_window))
		attach_hbox.add_child(take_btn)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var close_btn_popup2 = Button.new()
	close_btn_popup2.text = "ЗАКРЫТЬ"
	close_btn_popup2.custom_minimum_size = Vector2(120, 40)
	close_btn_popup2.pressed.connect(read_window.queue_free)
	btn_hbox.add_child(close_btn_popup2)

func _take_attachment(mail: Dictionary, attachment: Dictionary, window: Panel):
	var item_id = attachment.get("item_id", "")
	var quantity = attachment.get("quantity", 1)
	var item_name = attachment.get("name", "Предмет")
	
	if NetworkManager and NetworkManager.current_mode == "server":
		NetworkManager.send("TAKE_MAIL_ATTACHMENT|" + mail["id"])
		window.queue_free()
		return
	
	# Локальный режим
	if attachment.get("type") == "gold":
		player_data["gold"] = player_data.get("gold", 0) + quantity
		_show_message("Вы получили " + str(quantity) + " золота!")
	else:
		if not player_data.has("inventory"):
			player_data["inventory"] = []
		
		var found = false
		for i in range(player_data["inventory"].size()):
			if player_data["inventory"][i].get("id", "") == item_id:
				player_data["inventory"][i]["quantity"] += quantity
				found = true
				break
		
		if not found:
			player_data["inventory"].append({
				"id": item_id,
				"quantity": quantity,
				"name": item_name,
				"icon": attachment.get("icon", "📦")
			})
		_show_message("Вы получили " + item_name + " x" + str(quantity) + "!")
	
	mail["attachment"] = null
	mail["has_attachment"] = false
	save_mails()
	
	window.queue_free()
	update_mails_list()
	
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.emit(player_data)

func _delete_mail(mail: Dictionary):
	if NetworkManager and NetworkManager.current_mode == "server":
		NetworkManager.send("DELETE_MAIL|" + mail["id"] + "|" + current_tab)
		return
	
	if current_tab == "inbox":
		for i in range(incoming_mails.size()):
			if incoming_mails[i]["id"] == mail["id"]:
				incoming_mails.remove_at(i)
				break
	else:
		for i in range(outgoing_mails.size()):
			if outgoing_mails[i]["id"] == mail["id"]:
				outgoing_mails.remove_at(i)
				break
	
	save_mails()
	update_mails_list()
	_show_message("Письмо удалено!")

func _open_write_window():
	if write_window and is_instance_valid(write_window):
		write_window.visible = true
		write_window.move_to_front()
		return
	
	write_window = Panel.new()
	write_window.anchor_left = 0.1
	write_window.anchor_top = 0.05
	write_window.anchor_right = 0.9
	write_window.anchor_bottom = 0.95
	add_child(write_window)
	
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
	write_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.02
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.98
	write_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "✏️ НОВОЕ ПИСЬМО"
	title.horizontal_alignment = 1
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var to_label = Label.new()
	to_label.text = "Кому:"
	to_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(to_label)
	
	var to_input = LineEdit.new()
	to_input.placeholder_text = "Имя игрока"
	to_input.custom_minimum_size.y = 35
	vbox.add_child(to_input)
	
	var subject_label = Label.new()
	subject_label.text = "Тема:"
	subject_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subject_label)
	
	var subject_input = LineEdit.new()
	subject_input.placeholder_text = "Тема письма"
	subject_input.custom_minimum_size.y = 35
	vbox.add_child(subject_input)
	
	var message_label = Label.new()
	message_label.text = "Сообщение:"
	message_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(message_label)
	
	var message_input = TextEdit.new()
	message_input.placeholder_text = "Введите текст письма..."
	message_input.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(message_input)
	
	var attach_label = Label.new()
	attach_label.text = "Вложение (опционально):"
	attach_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(attach_label)
	
	var attach_hbox = HBoxContainer.new()
	attach_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(attach_hbox)
	
	var attach_item_select = OptionButton.new()
	attach_item_select.add_item("Без вложения")
	for item_id in items_db:
		attach_item_select.add_item(items_db[item_id]["name"])
	attach_item_select.custom_minimum_size = Vector2(180, 35)
	attach_hbox.add_child(attach_item_select)
	
	var attach_quantity = LineEdit.new()
	attach_quantity.placeholder_text = "Кол-во"
	attach_quantity.custom_minimum_size = Vector2(80, 35)
	attach_quantity.text = "1"
	attach_hbox.add_child(attach_quantity)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var send_btn = Button.new()
	send_btn.text = "📨 ОТПРАВИТЬ"
	send_btn.custom_minimum_size = Vector2(140, 45)
	send_btn.pressed.connect(_send_mail.bind(to_input, subject_input, message_input, attach_item_select, attach_quantity, write_window))
	btn_hbox.add_child(send_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "❌ ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(140, 45)
	cancel_btn.pressed.connect(write_window.queue_free)
	btn_hbox.add_child(cancel_btn)

func _send_mail(to_input, subject_input, message_input, attach_select, attach_qty, window):
	var recipient = to_input.text.strip_edges()
	var subject = subject_input.text.strip_edges()
	var message = message_input.text.strip_edges()
	
	if recipient == "":
		_show_message("Укажите получателя!")
		return
	
	if subject == "":
		_show_message("Укажите тему письма!")
		return
	
	if message == "":
		_show_message("Введите текст письма!")
		return
	
	var attachment = null
	var attach_index = attach_select.selected
	if attach_index > 0:
		var item_id = items_db.keys()[attach_index - 1]
		var quantity = int(attach_qty.text.strip_edges())
		if quantity <= 0:
			quantity = 1
		attachment = {
			"type": "item",
			"item_id": item_id,
			"name": items_db[item_id]["name"],
			"quantity": quantity,
			"icon": items_db[item_id]["icon"]
		}
	
	var new_mail = {
		"id": str(Time.get_unix_time_from_system()),
		"from": player_data.get("name", "Игрок"),
		"to": recipient,
		"subject": subject,
		"message": message,
		"attachment": attachment,
		"is_read": false,
		"has_attachment": attachment != null,
		"sent_at": Time.get_unix_time_from_system()
	}
	
	if NetworkManager and NetworkManager.current_mode == "server":
		var mail_json = JSON.stringify(new_mail)
		NetworkManager.send("SEND_MAIL|" + mail_json)
		window.queue_free()
		return
	
	# Локальный режим
	outgoing_mails.append(new_mail)
	
	var recipient_exists = false
	var file = FileAccess.open("user://players.dat", FileAccess.READ)
	if file:
		var players = file.get_var()
		file.close()
		if players.has(recipient):
			recipient_exists = true
	
	if not recipient_exists:
		_show_message("ВНИМАНИЕ! Игрок " + recipient + " не найден.\nПисьмо сохранено в Исходящих, но не будет доставлено.")
	
	save_mails()
	update_mails_list()
	window.queue_free()
	_show_message("Письмо отправлено!")

func _show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Почта"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	load_mails()
	update_mails_list()

func _on_close():
	if write_window and is_instance_valid(write_window):
		write_window.queue_free()
	if read_window and is_instance_valid(read_window):
		read_window.queue_free()
	if sync_timer:
		sync_timer.stop()
	queue_free()
