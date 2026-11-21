# res://modules/storage.gd
extends Panel

var player_data = {}
var storage_items = []
var storage_grid = null
var selected_slot = -1
var detail_popup = null
var close_btn
var guild_ref = null

func set_guild_reference(guild):
	guild_ref = guild

func _ready():
	build_ui()
	load_data()
	load_storage()
	update_storage_grid()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)
		if NetworkManager.has_signal("data_received"):
			NetworkManager.data_received.connect(_on_network_data)

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
	title.text = "📦 ЛИЧНОЕ ХРАНИЛИЩЕ"
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
	info_label.text = "Ваше личное хранилище (36 слотов)"
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
	
	storage_grid = GridContainer.new()
	storage_grid.columns = 6
	storage_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	storage_grid.add_theme_constant_override("h_separation", 10)
	storage_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(storage_grid)
	
	var bottom_panel = HBoxContainer.new()
	bottom_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(bottom_panel)
	
	var put_btn = Button.new()
	put_btn.text = "ПОЛОЖИТЬ ПРЕДМЕТ"
	put_btn.custom_minimum_size = Vector2(180, 40)
	put_btn.pressed.connect(_open_inventory_for_put)
	bottom_panel.add_child(put_btn)

func load_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {
			"name": "Игрок",
			"gold": 1000,
			"inventory": []
		}

func load_storage():
	if NetworkManager and NetworkManager.current_mode == "server":
		NetworkManager.send_get_guild_storage()
		return
	
	if player_data.has("personal_storage") and typeof(player_data["personal_storage"]) == TYPE_ARRAY:
		storage_items = player_data["personal_storage"]
		while storage_items.size() < 36:
			storage_items.append(null)
		while storage_items.size() > 36:
			storage_items.pop_back()
		return
	
	storage_items = []
	for i in range(36):
		storage_items.append(null)

func save_storage():
	if NetworkManager and NetworkManager.current_mode == "server":
		return
	
	player_data["personal_storage"] = storage_items
	
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.emit(player_data)

func update_storage_grid():
	if not storage_grid:
		return
	
	for child in storage_grid.get_children():
		child.queue_free()
	
	for i in range(36):
		var cell = create_storage_cell(i)
		storage_grid.add_child(cell)

func create_storage_cell(index: int) -> Button:
	var cell = Button.new()
	cell.custom_minimum_size = Vector2(80, 90)
	
	var item = storage_items[index] if index < storage_items.size() else null
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_child(vbox)
	
	if item != null and typeof(item) == TYPE_DICTIONARY:
		var icon_label = Label.new()
		icon_label.text = item.get("icon", "📦")
		icon_label.horizontal_alignment = 1
		icon_label.add_theme_font_size_override("font_size", 32)
		vbox.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.text = item.get("name", "???")
		name_label.horizontal_alignment = 1
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
		vbox.add_child(name_label)
		
		var quantity_label = Label.new()
		quantity_label.text = "x" + str(item.get("quantity", 1))
		quantity_label.horizontal_alignment = 1
		quantity_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(quantity_label)
	else:
		var empty_label = Label.new()
		empty_label.text = "пусто"
		empty_label.horizontal_alignment = 1
		empty_label.vertical_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(empty_label)
	
	cell.pressed.connect(_on_cell_pressed.bind(index))
	
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	frame_style.border_color = Color(1, 0.84, 0, 0.3)
	frame_style.border_width_left = 1
	frame_style.border_width_right = 1
	frame_style.border_width_top = 1
	frame_style.border_width_bottom = 1
	cell.add_theme_stylebox_override("normal", frame_style)
	
	return cell

func _on_cell_pressed(index: int):
	selected_slot = index
	var item = storage_items[selected_slot] if selected_slot < storage_items.size() else null
	if item != null and typeof(item) == TYPE_DICTIONARY:
		show_item_detail(item)

func show_item_detail(item: Dictionary):
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.25
	detail_popup.anchor_top = 0.25
	detail_popup.anchor_right = 0.75
	detail_popup.anchor_bottom = 0.75
	add_child(detail_popup)
	
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
	detail_popup.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.05
	margin.anchor_top = 0.05
	margin.anchor_right = 0.95
	margin.anchor_bottom = 0.95
	detail_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "📦 " + item.get("name", "???")
	title.horizontal_alignment = 1
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = item.get("description", "Нет описания")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc)
	
	var quantity = Label.new()
	quantity.text = "Количество: x" + str(item.get("quantity", 1))
	quantity.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(quantity)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var take_btn = Button.new()
	take_btn.text = "ЗАБРАТЬ"
	take_btn.custom_minimum_size = Vector2(120, 40)
	take_btn.pressed.connect(_take_from_storage)
	btn_hbox.add_child(take_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(120, 40)
	cancel_btn.pressed.connect(_close_detail)
	btn_hbox.add_child(cancel_btn)

func _take_from_storage():
	if selected_slot < 0 or selected_slot >= storage_items.size():
		_close_detail()
		return
	
	var item = storage_items[selected_slot]
	if item == null or typeof(item) != TYPE_DICTIONARY:
		_close_detail()
		return
	
	if NetworkManager and NetworkManager.current_mode == "server":
		NetworkManager.send_take_guild_storage(selected_slot)
		_close_detail()
		return
	
	if not player_data.has("inventory"):
		player_data["inventory"] = []
	
	var found = false
	for i in range(player_data["inventory"].size()):
		if player_data["inventory"][i].get("id", "") == item.get("id", ""):
			player_data["inventory"][i]["quantity"] += item.get("quantity", 1)
			found = true
			break
	
	if not found:
		player_data["inventory"].append({
			"id": item.get("id", ""),
			"quantity": item.get("quantity", 1),
			"name": item.get("name", "???"),
			"icon": item.get("icon", "📦"),
			"description": item.get("description", "Нет описания")
		})
	
	storage_items[selected_slot] = null
	save_storage()
	
	_close_detail()
	update_storage_grid()
	_show_message("Вы забрали " + item.get("name", "предмет") + " x" + str(item.get("quantity", 1)))

func _open_inventory_for_put():
	var select_window = Panel.new()
	select_window.anchor_left = 0.2
	select_window.anchor_top = 0.15
	select_window.anchor_right = 0.8
	select_window.anchor_bottom = 0.85
	add_child(select_window)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.98)
	style.border_color = Color(1, 0.84, 0, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	select_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.02
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.98
	select_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "ВЫБЕРИТЕ ПРЕДМЕТ ИЗ ИНВЕНТАРЯ"
	title.horizontal_alignment = 1
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var items_list = VBoxContainer.new()
	items_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_list)
	
	var inventory = player_data.get("inventory", [])
	
	if inventory.size() == 0:
		var empty = Label.new()
		empty.text = "Инвентарь пуст"
		empty.horizontal_alignment = 1
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		items_list.add_child(empty)
	else:
		for i in range(inventory.size()):
			var item = inventory[i]
			var item_card = _create_select_item_card(item, select_window)
			items_list.add_child(item_card)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(150, 35)
	cancel_btn.pressed.connect(select_window.queue_free)
	vbox.add_child(cancel_btn)

func _create_select_item_card(item: Dictionary, parent_window: Panel) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 60
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_color = Color(1, 0.84, 0, 0.3)
	style.border_width_left = 1
	style.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", style)
	
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
	icon.text = item.get("icon", "📦")
	icon.add_theme_font_size_override("font_size", 28)
	icon.custom_minimum_size = Vector2(50, 50)
	hbox.add_child(icon)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name = Label.new()
	name.text = item.get("name", "???")
	name.add_theme_color_override("font_color", Color(1, 0.84, 0))
	info_vbox.add_child(name)
	
	var quantity = Label.new()
	quantity.text = "Количество: x" + str(item.get("quantity", 1))
	quantity.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(quantity)
	
	var put_btn = Button.new()
	put_btn.text = "ПОЛОЖИТЬ"
	put_btn.custom_minimum_size = Vector2(100, 35)
	put_btn.pressed.connect(_put_to_storage.bind(item, parent_window))
	hbox.add_child(put_btn)
	
	return card

func _put_to_storage(item: Dictionary, parent_window: Panel):
	if NetworkManager and NetworkManager.current_mode == "server":
		NetworkManager.send_put_guild_storage(item.get("id", ""), item.get("quantity", 1))
		if parent_window and is_instance_valid(parent_window):
			parent_window.queue_free()
		_show_message("Предмет отправлен в хранилище...")
		return
	
	var free_slot = -1
	for i in range(storage_items.size()):
		if storage_items[i] == null:
			free_slot = i
			break
	
	if free_slot == -1:
		_show_message("Хранилище заполнено!")
		return
	
	storage_items[free_slot] = {
		"id": item.get("id", ""),
		"name": item.get("name", "???"),
		"icon": item.get("icon", "📦"),
		"description": item.get("description", "Нет описания"),
		"quantity": item.get("quantity", 1)
	}
	
	for i in range(player_data["inventory"].size()):
		if player_data["inventory"][i].get("id", "") == item.get("id", ""):
			player_data["inventory"][i]["quantity"] -= item.get("quantity", 1)
			if player_data["inventory"][i]["quantity"] <= 0:
				player_data["inventory"].remove_at(i)
			break
	
	save_storage()
	update_storage_grid()
	
	if parent_window and is_instance_valid(parent_window):
		parent_window.queue_free()
	
	_show_message("Вы положили " + item.get("name", "предмет") + " x" + str(item.get("quantity", 1)))

func _close_detail():
	if detail_popup and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	selected_slot = -1

func _show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Хранилище"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _on_network_data(data: String):
	var parts = data.split("|")
	match parts[0]:
		"GUILD_STORAGE":
			var json = JSON.new()
			if json.parse(parts[1]) == OK:
				storage_items = json.data
				update_storage_grid()
		"GUILD_STORAGE_PUT_OK":
			load_storage()
			_show_message("Предмет положен в хранилище!")
		"GUILD_STORAGE_PUT_FAIL":
			_show_message("Не удалось положить предмет!")
		"GUILD_STORAGE_TAKE_OK":
			load_storage()
			_show_message("Предмет забран из хранилища!")
		"GUILD_STORAGE_TAKE_FAIL":
			_show_message("Не удалось забрать предмет!")

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	load_storage()
	update_storage_grid()

func _on_close():
	queue_free()
