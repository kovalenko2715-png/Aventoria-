# res://modules/inventory.gd
extends Panel

# ===== БАЗА ДАННЫХ ПРЕДМЕТОВ =====
var items_db = {
	"health_potion": {
		"name": "Зелье здоровья",
		"type": "consumable",
		"level": 1,
		"description": "Восстанавливает 50 HP.",
		"durability": -1,
		"price": 10,
		"requirements": {},
		"bonuses": {"hp_restore": 50},
		"icon": "🧪"
	},
	"iron_sword": {
		"name": "Железный меч",
		"type": "equipment",
		"slot": "weapon",
		"level": 2,
		"description": "Обычный железный меч.",
		"durability": 100,
		"price": 150,
		"requirements": {"strength": 5, "agility": 3},
		"bonuses": {"attack": 12, "crit_chance": 2},
		"icon": "⚔️"
	},
	"steel_sword": {
		"name": "Стальной меч",
		"type": "equipment",
		"slot": "weapon",
		"level": 5,
		"description": "Качественный стальной меч.",
		"durability": 120,
		"price": 300,
		"requirements": {"strength": 10, "agility": 7},
		"bonuses": {"attack": 20, "crit_chance": 4},
		"icon": "⚔️"
	},
	"leather_armor": {
		"name": "Кожаная броня",
		"type": "equipment",
		"slot": "armor",
		"level": 1,
		"description": "Лёгкая броня из кожи.",
		"durability": 80,
		"price": 80,
		"requirements": {"endurance": 3},
		"bonuses": {"defense": 8, "evasion": 2},
		"icon": "🛡️"
	},
	"rat_tail": {
		"name": "Крысиный хвост",
		"type": "material",
		"level": 1,
		"description": "Хвост крысы. Можно продать или использовать в крафте.",
		"durability": -1,
		"price": 5,
		"requirements": {},
		"bonuses": {},
		"icon": "🐀"
	},
	"bone": {
		"name": "Кость",
		"type": "material",
		"level": 1,
		"description": "Кость скелета. Можно продать или использовать в крафте.",
		"durability": -1,
		"price": 8,
		"requirements": {},
		"bonuses": {},
		"icon": "🦴"
	},
	"wolf_fur": {
		"name": "Волчья шкура",
		"type": "material",
		"level": 1,
		"description": "Шкура волка. Можно продать или использовать в крафте.",
		"durability": -1,
		"price": 10,
		"requirements": {},
		"bonuses": {},
		"icon": "🐺"
	},
	"orc_tusk": {
		"name": "Клык орка",
		"type": "material",
		"level": 5,
		"description": "Клык орка. Ценный трофей.",
		"durability": -1,
		"price": 25,
		"requirements": {},
		"bonuses": {},
		"icon": "🦷"
	},
	"ghost_essence": {
		"name": "Призрачная эссенция",
		"type": "material",
		"level": 10,
		"description": "Эссенция призрака. Редкий материал.",
		"durability": -1,
		"price": 50,
		"requirements": {},
		"bonuses": {},
		"icon": "👻"
	},
	"golem_core": {
		"name": "Ядро голема",
		"type": "material",
		"level": 15,
		"description": "Ядро каменного голема. Очень ценный материал.",
		"durability": -1,
		"price": 100,
		"requirements": {},
		"bonuses": {},
		"icon": "🗿"
	},
	"dragon_scale": {
		"name": "Чешуя дракона",
		"type": "material",
		"level": 20,
		"description": "Чешуя дракона. Легендарный материал.",
		"durability": -1,
		"price": 200,
		"requirements": {},
		"bonuses": {},
		"icon": "🐉"
	},
	"demon_heart": {
		"name": "Сердце демона",
		"type": "material",
		"level": 25,
		"description": "Сердце демона. Тёмный артефакт.",
		"durability": -1,
		"price": 300,
		"requirements": {},
		"bonuses": {},
		"icon": "😈"
	}
}

# ===== ДАННЫЕ ИГРОКА =====
var player_data = {}
var inventory = []
var equipment = {}
var quick_slots = [null, null, null, null]

# ===== ИНТЕРФЕЙС =====
var close_btn
var portrait
var grid_container
var detail_popup = null
var main_scroll

# Слоты экипировки
var slot_wings
var slot_bracelet
var slot_mask
var slot_helmet
var slot_armor
var slot_gloves
var slot_weapon
var slot_pants
var slot_boots
var slot_cloak
var slot_necklace
var slot_earring1
var slot_earring2
var slot_shield
var slot_shirt
var slot_belt
var slot_ring1
var slot_ring2
var slot_bag
var slot_rune

var quick_slot_buttons = []

var gold_frame_style = null

func _ready():
	create_gold_frame_style()
	build_ui()
	await get_tree().process_frame
	await get_tree().process_frame
	
	load_player_data()
	update_equipment_slots()
	update_quick_slots()
	update_inventory_grid()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager != null:
		if NetworkManager.has_signal("data_received"):
			NetworkManager.data_received.connect(_on_network_data)
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

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
	anchor_left = 0.05
	anchor_top = 0.02
	anchor_right = 0.95
	anchor_bottom = 0.98
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	panel_style.border_color = Color(1, 0.84, 0, 0.3)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", panel_style)
	
	main_scroll = ScrollContainer.new()
	main_scroll.anchor_left = 0.02
	main_scroll.anchor_top = 0.02
	main_scroll.anchor_right = 0.98
	main_scroll.anchor_bottom = 0.98
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(main_scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_scroll.add_child(vbox)
	
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "ИНВЕНТАРЬ"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)
	
	var left_column = VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.custom_minimum_size.x = 380
	columns.add_child(left_column)
	
	var equip_section = VBoxContainer.new()
	equip_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_column.add_child(equip_section)
	
	var top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 5)
	equip_section.add_child(top_row)
	
	slot_wings = create_equip_slot("Крылья", "wings", Vector2(50,50))
	top_row.add_child(slot_wings)
	slot_bracelet = create_equip_slot("Браслет", "bracelet", Vector2(50,50))
	top_row.add_child(slot_bracelet)
	slot_mask = create_equip_slot("Маска", "mask", Vector2(50,50))
	top_row.add_child(slot_mask)
	
	var center_row = HBoxContainer.new()
	center_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center_row.add_theme_constant_override("separation", 5)
	equip_section.add_child(center_row)
	
	var left_slots = VBoxContainer.new()
	left_slots.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	left_slots.add_theme_constant_override("separation", 3)
	center_row.add_child(left_slots)
	
	slot_helmet = create_equip_slot("Шлем", "helmet", Vector2(50,50))
	left_slots.add_child(slot_helmet)
	slot_armor = create_equip_slot("Броня", "armor", Vector2(50,50))
	left_slots.add_child(slot_armor)
	slot_gloves = create_equip_slot("Перчатки", "gloves", Vector2(50,50))
	left_slots.add_child(slot_gloves)
	slot_weapon = create_equip_slot("Оружие", "weapon", Vector2(50,50))
	left_slots.add_child(slot_weapon)
	slot_pants = create_equip_slot("Штаны", "pants", Vector2(50,50))
	left_slots.add_child(slot_pants)
	slot_boots = create_equip_slot("Обувь", "boots", Vector2(50,50))
	left_slots.add_child(slot_boots)
	
	var portrait_container = VBoxContainer.new()
	portrait_container.alignment = BoxContainer.ALIGNMENT_CENTER
	center_row.add_child(portrait_container)
	
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(130, 170)
	portrait.modulate = Color(1, 1, 1, 1)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.add_theme_stylebox_override("normal", gold_frame_style)
	portrait_container.add_child(portrait)
	
	var right_slots = VBoxContainer.new()
	right_slots.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	right_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	right_slots.add_theme_constant_override("separation", 3)
	center_row.add_child(right_slots)
	
	slot_cloak = create_equip_slot("Плащ", "cloak", Vector2(50,50))
	right_slots.add_child(slot_cloak)
	slot_necklace = create_equip_slot("Ожерелье", "necklace", Vector2(50,50))
	right_slots.add_child(slot_necklace)
	
	var earring_row = HBoxContainer.new()
	earring_row.alignment = BoxContainer.ALIGNMENT_CENTER
	earring_row.add_theme_constant_override("separation", 2)
	right_slots.add_child(earring_row)
	slot_earring1 = create_equip_slot("Серьга", "earring1", Vector2(25,25))
	earring_row.add_child(slot_earring1)
	slot_earring2 = create_equip_slot("Серьга", "earring2", Vector2(25,25))
	earring_row.add_child(slot_earring2)
	
	slot_shield = create_equip_slot("Щит", "shield", Vector2(50,50))
	right_slots.add_child(slot_shield)
	slot_shirt = create_equip_slot("Рубаха", "shirt", Vector2(50,50))
	right_slots.add_child(slot_shirt)
	slot_belt = create_equip_slot("Пояс", "belt", Vector2(50,50))
	right_slots.add_child(slot_belt)
	
	var bottom_row = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 5)
	equip_section.add_child(bottom_row)
	
	slot_ring1 = create_equip_slot("Кольцо", "ring1", Vector2(50,50))
	bottom_row.add_child(slot_ring1)
	slot_ring2 = create_equip_slot("Кольцо", "ring2", Vector2(50,50))
	bottom_row.add_child(slot_ring2)
	slot_bag = create_equip_slot("Сумка", "bag", Vector2(50,50))
	bottom_row.add_child(slot_bag)
	slot_rune = create_equip_slot("Руна", "rune", Vector2(50,50))
	bottom_row.add_child(slot_rune)
	
	var quick_section = VBoxContainer.new()
	quick_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_column.add_child(quick_section)
	
	var quick_label = Label.new()
	quick_label.text = "СЛОТЫ РАСХОДНИКОВ"
	quick_label.horizontal_alignment = 1
	quick_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quick_label.add_theme_font_size_override("font_size", 16)
	quick_section.add_child(quick_label)
	
	var quick_row = HBoxContainer.new()
	quick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	quick_row.add_theme_constant_override("separation", 8)
	quick_section.add_child(quick_row)
	
	for i in range(4):
		var slot = create_equip_slot("Слот " + str(i+1), "quick" + str(i), Vector2(50,50))
		quick_row.add_child(slot)
		quick_slot_buttons.append(slot.get_child(0))
		slot.get_child(0).pressed.connect(_on_quick_slot_pressed.bind(i))
	
	var right_column = VBoxContainer.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.custom_minimum_size.x = 520
	columns.add_child(right_column)
	
	var inventory_label = Label.new()
	inventory_label.text = "ИНВЕНТАРЬ"
	inventory_label.horizontal_alignment = 1
	inventory_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	inventory_label.add_theme_font_size_override("font_size", 20)
	right_column.add_child(inventory_label)
	
	var inventory_scroll = ScrollContainer.new()
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_column.add_child(inventory_scroll)
	
	grid_container = GridContainer.new()
	grid_container.columns = 6
	grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_container.add_theme_constant_override("h_separation", 10)
	grid_container.add_theme_constant_override("v_separation", 10)
	inventory_scroll.add_child(grid_container)

func create_equip_slot(tooltip: String, slot_name: String, slot_size: Vector2) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	
	var btn = Button.new()
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = slot_size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.set_meta("slot_name", slot_name)
	
	btn.add_theme_stylebox_override("normal", gold_frame_style)
	btn.add_theme_stylebox_override("hover", gold_frame_style)
	btn.add_theme_stylebox_override("pressed", gold_frame_style)
	btn.add_theme_stylebox_override("disabled", gold_frame_style)
	
	btn.text = ""
	btn.add_theme_font_size_override("font_size", 20)
	box.add_child(btn)
	
	var label = Label.new()
	label.text = tooltip
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_font_size_override("font_size", 9)
	label.horizontal_alignment = 1
	box.add_child(label)
	
	btn.pressed.connect(_on_slot_pressed.bind(btn))
	return box

func load_player_data():
	if NetworkManager != null and NetworkManager.player_data != null:
		player_data = NetworkManager.player_data.duplicate(true)
		inventory = player_data.get("inventory", [])
		equipment = player_data.get("equipment", {})
		quick_slots = player_data.get("quick_slots", [null, null, null, null])
	else:
		inventory = [
			{"id": "health_potion", "quantity": 5, "name": "Зелье здоровья", "icon": "🧪", "description": "Восстанавливает 50 HP."},
			{"id": "iron_sword", "quantity": 1, "name": "Железный меч", "icon": "⚔️", "description": "Обычный железный меч."},
			{"id": "leather_armor", "quantity": 1, "name": "Кожаная броня", "icon": "🛡️", "description": "Лёгкая броня из кожи."}
		]
		player_data["level"] = 1
		player_data["stats"] = {
			"strength": 5,
			"agility": 5,
			"intuition": 5,
			"endurance": 5,
			"intellect": 5,
			"wisdom": 5,
			"spirit": 5
		}
		equipment = {}
		quick_slots = [null, null, null, null]

func get_item_icon(item_id):
	var item_info = items_db.get(item_id, {})
	return item_info.get("icon", "📦")

func get_item_name(item_id):
	var item_info = items_db.get(item_id, {})
	return item_info.get("name", "???")

func update_equipment_slots():
	if equipment == null:
		equipment = {}
	
	slot_helmet.get_child(0).text = get_item_icon(equipment.get("helmet"))
	slot_armor.get_child(0).text = get_item_icon(equipment.get("armor"))
	slot_gloves.get_child(0).text = get_item_icon(equipment.get("gloves"))
	slot_weapon.get_child(0).text = get_item_icon(equipment.get("weapon"))
	slot_pants.get_child(0).text = get_item_icon(equipment.get("pants"))
	slot_boots.get_child(0).text = get_item_icon(equipment.get("boots"))
	slot_cloak.get_child(0).text = get_item_icon(equipment.get("cloak"))
	slot_necklace.get_child(0).text = get_item_icon(equipment.get("necklace"))
	slot_earring1.get_child(0).text = get_item_icon(equipment.get("earring1"))
	slot_earring2.get_child(0).text = get_item_icon(equipment.get("earring2"))
	slot_shield.get_child(0).text = get_item_icon(equipment.get("shield"))
	slot_shirt.get_child(0).text = get_item_icon(equipment.get("shirt"))
	slot_belt.get_child(0).text = get_item_icon(equipment.get("belt"))
	slot_wings.get_child(0).text = get_item_icon(equipment.get("wings"))
	slot_bracelet.get_child(0).text = get_item_icon(equipment.get("bracelet"))
	slot_mask.get_child(0).text = get_item_icon(equipment.get("mask"))
	slot_ring1.get_child(0).text = get_item_icon(equipment.get("ring1"))
	slot_ring2.get_child(0).text = get_item_icon(equipment.get("ring2"))
	slot_bag.get_child(0).text = get_item_icon(equipment.get("bag"))
	slot_rune.get_child(0).text = get_item_icon(equipment.get("rune"))

func update_quick_slots():
	for i in range(4):
		var item_id = quick_slots[i]
		if item_id != null:
			quick_slot_buttons[i].text = get_item_icon(item_id)
		else:
			quick_slot_buttons[i].text = ""

func update_inventory_grid():
	if grid_container == null:
		print("❌ grid_container не инициализирован")
		return
	
	for child in grid_container.get_children():
		child.queue_free()
	
	var total_slots = 36
	
	for i in range(total_slots):
		if i < inventory.size():
			var item = inventory[i]
			var item_info = items_db.get(item["id"], {"name": item.get("name", "???"), "icon": item.get("icon", "📦")})
			var cell = create_item_cell(i, item, item_info)
			grid_container.add_child(cell)
		else:
			var empty_cell = create_empty_cell()
			grid_container.add_child(empty_cell)

func create_item_cell(index: int, item: Dictionary, item_info: Dictionary) -> Button:
	var cell = Button.new()
	cell.custom_minimum_size = Vector2(75, 85)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	
	cell.add_theme_stylebox_override("normal", gold_frame_style)
	cell.add_theme_stylebox_override("hover", gold_frame_style)
	cell.add_theme_stylebox_override("pressed", gold_frame_style)
	
	var container = Container.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_child(container)
	
	var name_label = Label.new()
	name_label.text = item_info.get("name", "???")
	name_label.position = Vector2(5, 2)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_font_size_override("font_size", 9)
	container.add_child(name_label)
	
	var icon_placeholder = Label.new()
	icon_placeholder.text = item_info.get("icon", "📦")
	icon_placeholder.position = Vector2(25, 25)
	icon_placeholder.add_theme_font_size_override("font_size", 24)
	container.add_child(icon_placeholder)
	
	var quantity_label = Label.new()
	quantity_label.text = "x" + str(item["quantity"])
	quantity_label.position = Vector2(50, 60)
	quantity_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quantity_label.add_theme_font_size_override("font_size", 8)
	container.add_child(quantity_label)
	
	cell.pressed.connect(_on_inventory_item_pressed.bind(index))
	return cell

func create_empty_cell() -> Button:
	var cell = Button.new()
	cell.custom_minimum_size = Vector2(75, 85)
	cell.disabled = true
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var empty_style = StyleBoxFlat.new()
	empty_style.bg_color = Color(0.15, 0.15, 0.15, 1)
	empty_style.border_color = Color(1, 0.84, 0, 0.3)
	empty_style.border_width_left = 2
	empty_style.border_width_right = 2
	empty_style.border_width_top = 2
	empty_style.border_width_bottom = 2
	empty_style.corner_radius_top_left = 5
	empty_style.corner_radius_top_right = 5
	empty_style.corner_radius_bottom_left = 5
	empty_style.corner_radius_bottom_right = 5
	cell.add_theme_stylebox_override("normal", empty_style)
	cell.add_theme_stylebox_override("disabled", empty_style)
	
	var container = Container.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_child(container)
	
	var question_mark = Label.new()
	question_mark.text = "?"
	question_mark.position = Vector2(5, 2)
	question_mark.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	question_mark.add_theme_font_size_override("font_size", 12)
	container.add_child(question_mark)
	
	var empty_label = Label.new()
	empty_label.text = "пусто"
	empty_label.position = Vector2(20, 35)
	empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	empty_label.add_theme_font_size_override("font_size", 9)
	container.add_child(empty_label)
	
	return cell

func _on_slot_pressed(btn: Button):
	var slot_name = btn.get_meta("slot_name", "")
	if slot_name == "":
		return
	
	if equipment.has(slot_name) and equipment[slot_name] != null:
		show_item_detail(equipment[slot_name], true)

func _on_inventory_item_pressed(index: int):
	if index < 0 or index >= inventory.size():
		return
	var item = inventory[index]
	show_item_detail(item["id"], false)

func _on_quick_slot_pressed(index: int):
	if index < 0 or index >= quick_slots.size():
		return
	var item_id = quick_slots[index]
	if item_id != null:
		show_item_detail(item_id, false)

func show_item_detail(item_id: String, is_equipped: bool):
	if detail_popup != null and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	
	var item_info = items_db.get(item_id, {})
	if item_info.is_empty():
		return
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.25
	detail_popup.anchor_top = 0.2
	detail_popup.anchor_right = 0.75
	detail_popup.anchor_bottom = 0.8
	add_child(detail_popup)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.98)
	style.border_color = Color(1, 0.84, 0, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	detail_popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.05
	vbox.anchor_top = 0.05
	vbox.anchor_right = 0.95
	vbox.anchor_bottom = 0.95
	vbox.add_theme_constant_override("separation", 5)
	detail_popup.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var icon = Label.new()
	icon.text = item_info.get("icon", "📦")
	icon.custom_minimum_size = Vector2(40, 40)
	icon.add_theme_color_override("font_color", Color(1, 0.84, 0))
	icon.add_theme_font_size_override("font_size", 30)
	title_hbox.add_child(icon)
	
	var name_label = Label.new()
	name_label.text = item_info.get("name", "")
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(name_label)
	
	var close_popup_btn = Button.new()
	close_popup_btn.text = "×"
	close_popup_btn.custom_minimum_size = Vector2(30, 30)
	close_popup_btn.pressed.connect(_close_detail_popup)
	title_hbox.add_child(close_popup_btn)
	
	var level_label = Label.new()
	level_label.text = "Уровень предмета: " + str(item_info.get("level", 1))
	vbox.add_child(level_label)
	
	var player_level = player_data.get("level", 1)
	var item_level = item_info.get("level", 1)
	
	var level_req_label = Label.new()
	level_req_label.text = "Ваш уровень: " + str(player_level) + " / " + str(item_level)
	level_req_label.add_theme_color_override("font_color", Color(0, 1, 0) if player_level >= item_level else Color(1, 0, 0))
	vbox.add_child(level_req_label)
	
	var player_stats = player_data.get("stats", {})
	var reqs = item_info.get("requirements", {})
	
	if reqs.size() > 0:
		var req_title = Label.new()
		req_title.text = "Требования:"
		req_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		vbox.add_child(req_title)
		
		for stat in reqs:
			var need = reqs[stat]
			var have = player_stats.get(stat, 0)
			var stat_name = get_stat_name(stat)
			
			var stat_label = Label.new()
			stat_label.text = stat_name + ": " + str(have) + " / " + str(need)
			stat_label.add_theme_color_override("font_color", Color(0, 1, 0) if have >= need else Color(1, 0, 0))
			vbox.add_child(stat_label)
	
	var bonuses = item_info.get("bonuses", {})
	if bonuses.size() > 0:
		var bonus_title = Label.new()
		bonus_title.text = "Бонусы:"
		bonus_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		vbox.add_child(bonus_title)
		
		for bonus in bonuses:
			var value = bonuses[bonus]
			var bonus_name = get_bonus_name(bonus)
			
			var b_label = Label.new()
			b_label.text = bonus_name + ": +" + str(value)
			b_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			vbox.add_child(b_label)
	
	var desc_label = Label.new()
	desc_label.text = item_info.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)
	
	if is_equipped:
		var unequip_btn = Button.new()
		unequip_btn.text = "СНЯТЬ"
		unequip_btn.custom_minimum_size = Vector2(100, 35)
		unequip_btn.pressed.connect(_on_unequip.bind(item_id))
		btn_hbox.add_child(unequip_btn)
	else:
		if item_info.get("type") == "equipment":
			var can_equip = can_equip_item(item_info)
			var equip_btn = Button.new()
			equip_btn.text = "НАДЕТЬ"
			equip_btn.custom_minimum_size = Vector2(100, 35)
			equip_btn.disabled = not can_equip
			equip_btn.pressed.connect(_on_equip.bind(item_id))
			btn_hbox.add_child(equip_btn)
		
		var drop_btn = Button.new()
		drop_btn.text = "ВЫБРОСИТЬ"
		drop_btn.custom_minimum_size = Vector2(100, 35)
		drop_btn.pressed.connect(_on_drop.bind(item_id))
		btn_hbox.add_child(drop_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(100, 35)
	cancel_btn.pressed.connect(_close_detail_popup)
	btn_hbox.add_child(cancel_btn)

func can_equip_item(item_info: Dictionary) -> bool:
	if item_info.get("type") != "equipment":
		return false
	
	var player_stats = player_data.get("stats", {})
	var reqs = item_info.get("requirements", {})
	var player_level = player_data.get("level", 1)
	var item_level = item_info.get("level", 1)
	
	if player_level < item_level:
		return false
	
	for stat in reqs:
		if player_stats.get(stat, 0) < reqs[stat]:
			return false
	
	return true

func get_stat_name(stat: String) -> String:
	match stat:
		"strength": return "Сила"
		"agility": return "Ловкость"
		"intuition": return "Интуиция"
		"endurance": return "Выносливость"
		"intellect": return "Интеллект"
		"wisdom": return "Мудрость"
		"spirit": return "Духовность"
		_: return stat.capitalize()

func get_bonus_name(bonus: String) -> String:
	match bonus:
		"attack": return "Атака"
		"defense": return "Защита"
		"hp_restore": return "Восстановление HP"
		"crit_chance": return "Шанс крита"
		_: return bonus.capitalize()

func _close_detail_popup():
	if detail_popup != null and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null

func _on_equip(item_id: String):
	var index = -1
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			index = i
			break
	
	if index == -1:
		_close_detail_popup()
		return
	
	var item_info = items_db.get(item_id, {})
	var slot = item_info.get("slot")
	if slot == null:
		_close_detail_popup()
		return
	
	if not can_equip_item(item_info):
		print("❌ Недостаточно уровня или характеристик для надевания")
		return
	
	if equipment.has(slot) and equipment[slot] != null:
		var old_id = equipment[slot]
		add_item_to_inventory(old_id, 1)
	
	equipment[slot] = item_id
	
	inventory[index]["quantity"] -= 1
	if inventory[index]["quantity"] <= 0:
		inventory.remove_at(index)
	
	update_equipment_slots()
	update_inventory_grid()
	send_update()
	_close_detail_popup()
	print("✅ Предмет надет: ", item_info.get("name"))

func _on_unequip(item_id: String):
	var slot = null
	for s in equipment:
		if equipment[s] == item_id:
			slot = s
			break
	
	if slot == null:
		_close_detail_popup()
		return
	
	equipment[slot] = null
	add_item_to_inventory(item_id, 1)
	
	update_equipment_slots()
	update_inventory_grid()
	send_update()
	_close_detail_popup()
	print("✅ Предмет снят")

func _on_drop(item_id: String):
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory.remove_at(i)
			break
	
	update_inventory_grid()
	send_update()
	_close_detail_popup()
	print("✅ Предмет выброшен")

func add_item_to_inventory(item_id: String, quantity: int):
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			inventory[i]["quantity"] += quantity
			return
	var item_info = items_db.get(item_id, {"name": get_item_name(item_id), "icon": get_item_icon(item_id)})
	inventory.append({"id": item_id, "quantity": quantity, "name": item_info.get("name", "???"), "icon": item_info.get("icon", "📦")})

func send_update():
	if NetworkManager != null:
		if NetworkManager.player_data != null:
			NetworkManager.player_data["inventory"] = inventory.duplicate()
			NetworkManager.player_data["equipment"] = equipment.duplicate()
			NetworkManager.player_data["quick_slots"] = quick_slots.duplicate()
			NetworkManager.send("INVENTORY_UPDATE|" + JSON.stringify({
				"inventory": inventory,
				"equipment": equipment,
				"quick_slots": quick_slots
			}))

func _on_network_data(data: String):
	var parts = data.split("|")
	if parts[0] == "INVENTORY_UPDATE_OK":
		pass
	elif parts[0] == "INVENTORY_UPDATE_FAIL":
		load_player_data()
		update_equipment_slots()
		update_quick_slots()
		update_inventory_grid()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	inventory = player_data.get("inventory", [])
	equipment = player_data.get("equipment", {})
	quick_slots = player_data.get("quick_slots", [null, null, null, null])
	update_equipment_slots()
	update_quick_slots()
	update_inventory_grid()

func _on_close():
	queue_free()
