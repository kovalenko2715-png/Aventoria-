# res://modules/auction.gd
extends Panel

# ===== БАЗА ДАННЫХ ПРЕДМЕТОВ =====
var items_db = {
	"health_potion": {
		"name": "Зелье здоровья",
		"type": "consumable",
		"level": 1,
		"description": "Восстанавливает 50 HP.",
		"lore": "Обычное зелье, которое можно найти в любой лавке. Сварено по стандартному рецепту алхимиков.",
		"durability": -1,
		"price": 10,
		"price_rune": 0,
		"requirements": {},
		"bonuses": {"hp_restore": 50}
	},
	"iron_sword": {
		"name": "Железный меч",
		"type": "equipment",
		"slot": "weapon",
		"level": 2,
		"description": "Обычный железный меч.",
		"lore": "Выкован местным кузнецом. Ничего особенного, но для новичка сойдёт. Говорят, такие мечи делают из руды, добытой в ближайших шахтах.",
		"durability": 100,
		"price": 150,
		"price_rune": 0,
		"requirements": {"strength": 5, "agility": 3},
		"bonuses": {"attack": 12, "crit_chance": 2}
	},
	"steel_sword": {
		"name": "Стальной меч",
		"type": "equipment",
		"slot": "weapon",
		"level": 5,
		"description": "Качественный стальной меч.",
		"lore": "Выкован лучшим кузнецом города. Сталь закалена особым способом, что придаёт мечу небывалую прочность. Такие мечи часто берут с собой в опасные походы.",
		"durability": 120,
		"price": 300,
		"price_rune": 0,
		"requirements": {"strength": 10, "agility": 7},
		"bonuses": {"attack": 20, "crit_chance": 4}
	},
	"leather_armor": {
		"name": "Кожаная броня",
		"type": "equipment",
		"slot": "armor",
		"level": 1,
		"description": "Лёгкая броня из кожи.",
		"lore": "Сшита из шкур диких животных. Обеспечивает неплохую защиту, не сковывая движений. Любимый выбор разбойников и следопытов.",
		"durability": 80,
		"price": 80,
		"price_rune": 0,
		"requirements": {"endurance": 3},
		"bonuses": {"defense": 8, "evasion": 2}
	}
}

# ===== ДАННЫЕ АУКЦИОНА =====
var auction_lots = {}
var my_lots = []
var player_data = {}

# ===== ПЕРЕМЕННЫЕ =====
var current_category = "all"
var search_query = ""
var sort_by = "price"
var sort_order = "asc"

# ===== ИНТЕРФЕЙС =====
var close_btn
var main_scroll
var lots_container
var gold_label
var rune_label
var category_buttons = {}
var sort_btn
var add_lot_btn
var detail_popup = null
var sell_popup = null
var inventory_popup = null

var selected_lot_id = ""
var selected_lot_data = {}

func _ready():
	build_ui()
	load_player_data()
	load_auction_data()
	update_auction_lots()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager != null:
		if NetworkManager.has_signal("data_received"):
			NetworkManager.data_received.connect(_on_network_data)
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

func build_ui():
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(1, 0.84, 0, 0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)
	
	var main_margin = MarginContainer.new()
	main_margin.anchor_left = 0.01
	main_margin.anchor_top = 0.01
	main_margin.anchor_right = 0.99
	main_margin.anchor_bottom = 0.99
	add_child(main_margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	main_margin.add_child(main_vbox)
	
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "АУКЦИОН"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 28)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var balance_row = HBoxContainer.new()
	balance_row.alignment = BoxContainer.ALIGNMENT_END
	main_vbox.add_child(balance_row)
	
	gold_label = Label.new()
	gold_label.text = "💰 0"
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	gold_label.add_theme_font_size_override("font_size", 16)
	balance_row.add_child(gold_label)
	
	var balance_spacer1 = Control.new()
	balance_spacer1.custom_minimum_size.x = 20
	balance_row.add_child(balance_spacer1)
	
	rune_label = Label.new()
	rune_label.text = "🔮 0"
	rune_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	rune_label.add_theme_font_size_override("font_size", 16)
	balance_row.add_child(rune_label)
	
	var balance_spacer2 = Control.new()
	balance_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance_row.add_child(balance_spacer2)
	
	var category_row = HBoxContainer.new()
	category_row.alignment = BoxContainer.ALIGNMENT_CENTER
	category_row.custom_minimum_size.y = 45
	main_vbox.add_child(category_row)
	
	var categories = ["ВСЕ", "ОРУЖИЕ", "БРОНЯ", "ПРОЧЕЕ", "МОИ ЛОТЫ"]
	var category_keys = ["all", "weapon", "armor", "other", "my"]
	
	for i in range(categories.size()):
		var btn = Button.new()
		btn.text = categories[i]
		btn.custom_minimum_size.x = 120
		btn.pressed.connect(_on_category_pressed.bind(category_keys[i]))
		category_row.add_child(btn)
		category_buttons[category_keys[i]] = btn
	
	var search_row = HBoxContainer.new()
	search_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(search_row)
	
	var search_label = Label.new()
	search_label.text = "Поиск:"
	search_label.add_theme_font_size_override("font_size", 14)
	search_row.add_child(search_label)
	
	var search_input = LineEdit.new()
	search_input.name = "SearchInput"
	search_input.placeholder_text = "Название предмета..."
	search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_input.custom_minimum_size.y = 30
	search_input.text_changed.connect(_on_search_changed)
	search_row.add_child(search_input)
	
	var sort_label = Label.new()
	sort_label.text = "Сортировать:"
	sort_label.add_theme_font_size_override("font_size", 14)
	search_row.add_child(sort_label)
	
	sort_btn = Button.new()
	sort_btn.text = "Цена ↑"
	sort_btn.custom_minimum_size = Vector2(90, 30)
	sort_btn.pressed.connect(_on_sort_pressed)
	search_row.add_child(sort_btn)
	
	var lots_title = Label.new()
	lots_title.text = "ТОВАРЫ"
	lots_title.horizontal_alignment = 1
	lots_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	lots_title.add_theme_font_size_override("font_size", 18)
	main_vbox.add_child(lots_title)
	
	var lots_section = VBoxContainer.new()
	lots_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lots_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lots_section.custom_minimum_size.y = 500
	main_vbox.add_child(lots_section)
	
	var lots_vbox = VBoxContainer.new()
	lots_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lots_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lots_vbox.add_theme_constant_override("separation", 10)
	lots_section.add_child(lots_vbox)
	
	add_lot_btn = Button.new()
	add_lot_btn.text = "📦 РАЗМЕСТИТЬ ПРЕДМЕТ НА АУКЦИОНЕ"
	add_lot_btn.custom_minimum_size.y = 45
	add_lot_btn.pressed.connect(_show_inventory_for_sale)
	add_lot_btn.visible = false
	lots_vbox.add_child(add_lot_btn)
	
	var lots_scroll = ScrollContainer.new()
	lots_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lots_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lots_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	lots_vbox.add_child(lots_scroll)
	
	lots_container = VBoxContainer.new()
	lots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lots_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lots_container.add_theme_constant_override("separation", 8)
	lots_scroll.add_child(lots_container)

func load_player_data():
	if NetworkManager != null and NetworkManager.player_data != null:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {
			"name": "Игрок123",
			"gold": 1000,
			"rune": 50,
			"inventory": [
				{"id": "health_potion", "quantity": 5},
				{"id": "iron_sword", "quantity": 1},
				{"id": "steel_sword", "quantity": 1},
				{"id": "leather_armor", "quantity": 2}
			],
			"stats": {
				"strength": 8,
				"agility": 6,
				"intuition": 4,
				"endurance": 7,
				"intellect": 5,
				"wisdom": 3,
				"spirit": 2
			}
		}
	
	update_currency()

func update_currency():
	gold_label.text = "💰 " + str(player_data.get("gold", 0))
	rune_label.text = "🔮 " + str(player_data.get("rune", 0))

func load_auction_data():
	auction_lots = {
		"lot1": {
			"item_id": "iron_sword",
			"seller": "Воин456",
			"price": 150,
			"price_rune": 0,
			"quantity": 1,
			"time_left": 86400,
			"listed_date": "2026-03-18 14:30"
		},
		"lot2": {
			"item_id": "steel_sword",
			"seller": "Маг789",
			"price": 280,
			"price_rune": 0,
			"quantity": 1,
			"time_left": 43200,
			"listed_date": "2026-03-17 09:15"
		},
		"lot3": {
			"item_id": "health_potion",
			"seller": "Лучник321",
			"price": 8,
			"price_rune": 0,
			"quantity": 10,
			"time_left": 21600,
			"listed_date": "2026-03-18 10:45"
		},
		"lot4": {
			"item_id": "leather_armor",
			"seller": "Танк111",
			"price": 70,
			"price_rune": 0,
			"quantity": 1,
			"time_left": 7200,
			"listed_date": "2026-03-16 18:20"
		}
	}
	
	my_lots = []

# ===== ИСПРАВЛЕННАЯ ФУНКЦИЯ ОПРЕДЕЛЕНИЯ КАТЕГОРИИ =====
func get_item_category(item_id: String) -> String:
	var item_info = items_db.get(item_id, {})
	var type = item_info.get("type", "")
	var slot = item_info.get("slot", "")
	
	# Определяем категорию
	if type == "weapon":
		return "weapon"
	elif type == "equipment":
		# Для экипировки определяем по слоту
		if slot == "weapon":
			return "weapon"
		elif slot == "armor":
			return "armor"
		else:
			return "other"
	elif type == "consumable":
		return "other"
	else:
		return "other"

func update_auction_lots():
	for child in lots_container.get_children():
		child.queue_free()
	
	var filtered_lots = []
	
	if current_category == "my":
		add_lot_btn.visible = true
		
		if my_lots.size() == 0:
			var empty_label = Label.new()
			empty_label.text = "У вас нет активных лотов"
			empty_label.horizontal_alignment = 1
			empty_label.vertical_alignment = 1
			empty_label.custom_minimum_size.y = 100
			empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			empty_label.add_theme_font_size_override("font_size", 16)
			lots_container.add_child(empty_label)
		else:
			for lot_data in my_lots:
				var item_info = items_db.get(lot_data["item_id"], {})
				var lot_widget = create_my_lot_widget(lot_data, item_info)
				lots_container.add_child(lot_widget)
	else:
		add_lot_btn.visible = false
		
		var all_lots = []
		
		# Добавляем лоты с аукциона
		for lot_id in auction_lots:
			var lot = auction_lots[lot_id]
			var item_info = items_db.get(lot["item_id"], {})
			all_lots.append({"id": lot_id, "data": lot, "item_info": item_info, "is_my": false})
		
		# Добавляем свои лоты
		for lot_data in my_lots:
			var item_info = items_db.get(lot_data["item_id"], {})
			all_lots.append({"id": "my_" + str(my_lots.find(lot_data)), "data": lot_data, "item_info": item_info, "is_my": true})
		
		# ФИЛЬТРАЦИЯ ПО КАТЕГОРИИ
		for lot_data in all_lots:
			var lot = lot_data["data"]
			var item_info = lot_data["item_info"]
			
			# Получаем категорию предмета
			var item_category = get_item_category(lot["item_id"])
			
			# Фильтруем по выбранной категории
			if current_category != "all":
				if current_category == "weapon" and item_category != "weapon":
					continue
				if current_category == "armor" and item_category != "armor":
					continue
				if current_category == "other" and (item_category != "other" and item_category != "consumable"):
					continue
			
			# Фильтр по поиску
			if search_query != "":
				if search_query.to_lower() not in item_info.get("name", "").to_lower():
					continue
			
			filtered_lots.append(lot_data)
		
		# Сортировка
		if sort_by == "price":
			if sort_order == "asc":
				filtered_lots.sort_custom(func(a, b): return a["data"]["price"] < b["data"]["price"])
			else:
				filtered_lots.sort_custom(func(a, b): return a["data"]["price"] > b["data"]["price"])
		else:
			if sort_order == "asc":
				filtered_lots.sort_custom(func(a, b): return a["item_info"].get("level", 1) < b["item_info"].get("level", 1))
			else:
				filtered_lots.sort_custom(func(a, b): return a["item_info"].get("level", 1) > b["item_info"].get("level", 1))
		
		# Создаем элементы
		if filtered_lots.size() == 0:
			var empty_label = Label.new()
			empty_label.text = "Нет товаров в этой категории"
			empty_label.horizontal_alignment = 1
			empty_label.vertical_alignment = 1
			empty_label.custom_minimum_size.y = 100
			empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			empty_label.add_theme_font_size_override("font_size", 16)
			lots_container.add_child(empty_label)
		else:
			for lot_data in filtered_lots:
				if lot_data["is_my"]:
					var lot_widget = create_my_lot_widget_in_all(lot_data["data"], lot_data["item_info"])
					lots_container.add_child(lot_widget)
				else:
					var lot_widget = create_lot_widget(lot_data["id"], lot_data["data"], lot_data["item_info"])
					lots_container.add_child(lot_widget)

func create_lot_widget(lot_id: String, lot: Dictionary, item_info: Dictionary) -> Panel:
	var widget = Panel.new()
	widget.custom_minimum_size.y = 100
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_color = Color(1, 0.84, 0, 0.5)
	style.border_width_left = 2
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	widget.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.02
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.98
	widget.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = item_info.get("name", "???") + " [Ур." + str(item_info.get("level", 1)) + "]"
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)
	
	var seller_date_hbox = HBoxContainer.new()
	info_vbox.add_child(seller_date_hbox)
	
	var seller_icon = Label.new()
	seller_icon.text = "👤"
	seller_icon.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(seller_icon)
	
	var seller_label = Label.new()
	seller_label.text = lot["seller"]
	seller_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	seller_label.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(seller_label)
	
	var date_spacer = Control.new()
	date_spacer.custom_minimum_size.x = 15
	seller_date_hbox.add_child(date_spacer)
	
	var date_icon = Label.new()
	date_icon.text = "📅"
	date_icon.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(date_icon)
	
	var date_label = Label.new()
	date_label.text = lot.get("listed_date", "??")
	date_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	date_label.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(date_label)
	
	var quantity_hbox = HBoxContainer.new()
	info_vbox.add_child(quantity_hbox)
	
	var quantity_icon = Label.new()
	quantity_icon.text = "📦"
	quantity_icon.add_theme_font_size_override("font_size", 12)
	quantity_hbox.add_child(quantity_icon)
	
	var quantity_label = Label.new()
	quantity_label.text = "x" + str(lot["quantity"])
	quantity_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quantity_label.add_theme_font_size_override("font_size", 14)
	quantity_hbox.add_child(quantity_label)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size.x = 140
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(right_vbox)
	
	var price_hbox = HBoxContainer.new()
	price_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_child(price_hbox)
	
	var use_rune = lot.get("price_rune", 0) > 0
	var price_value = lot["price_rune"] if use_rune else lot["price"]
	
	var price_text = ""
	if use_rune:
		price_text = "🔮 " + str(price_value)
	else:
		price_text = "💰 " + str(price_value)
	
	var price_label = Label.new()
	price_label.text = price_text
	if use_rune:
		price_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	else:
		price_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	price_label.add_theme_font_size_override("font_size", 16)
	price_hbox.add_child(price_label)
	
	var view_btn = Button.new()
	view_btn.text = "СМОТРЕТЬ"
	view_btn.custom_minimum_size = Vector2(110, 35)
	view_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view_btn.pressed.connect(_show_lot_detail.bind(lot_id, lot))
	right_vbox.add_child(view_btn)
	
	return widget

func create_my_lot_widget(lot: Dictionary, item_info: Dictionary) -> Panel:
	var widget = Panel.new()
	widget.custom_minimum_size.y = 110
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.15, 0.9)
	style.border_color = Color(0.5, 1, 0.5, 0.6)
	style.border_width_left = 2
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	widget.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.02
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.98
	widget.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)
	
	var top_hbox = HBoxContainer.new()
	vbox.add_child(top_hbox)
	
	var name_label = Label.new()
	name_label.text = item_info.get("name", "???") + " [Ур." + str(item_info.get("level", 1)) + "]"
	name_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(name_label)
	
	var price_hbox = HBoxContainer.new()
	top_hbox.add_child(price_hbox)
	
	var use_rune = lot.get("price_rune", 0) > 0
	var price_value = lot["price_rune"] if use_rune else lot["price"]
	
	var price_text = ""
	if use_rune:
		price_text = "🔮 " + str(price_value)
	else:
		price_text = "💰 " + str(price_value)
	
	var price_label = Label.new()
	price_label.text = price_text
	if use_rune:
		price_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	else:
		price_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	price_label.add_theme_font_size_override("font_size", 16)
	price_hbox.add_child(price_label)
	
	var info_hbox = HBoxContainer.new()
	vbox.add_child(info_hbox)
	
	var date_icon = Label.new()
	date_icon.text = "📅"
	date_icon.add_theme_font_size_override("font_size", 12)
	info_hbox.add_child(date_icon)
	
	var date_label = Label.new()
	date_label.text = lot.get("listed_date", "???")
	date_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hbox.add_child(date_label)
	
	var quantity_icon = Label.new()
	quantity_icon.text = "📦"
	quantity_icon.add_theme_font_size_override("font_size", 12)
	info_hbox.add_child(quantity_icon)
	
	var quantity_label = Label.new()
	quantity_label.text = "x" + str(lot["quantity"])
	quantity_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quantity_label.add_theme_font_size_override("font_size", 12)
	info_hbox.add_child(quantity_label)
	
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_END
	bottom_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(bottom_hbox)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer)
	
	var details_btn = Button.new()
	details_btn.text = "ПОДРОБНЕЕ"
	details_btn.custom_minimum_size = Vector2(100, 30)
	details_btn.pressed.connect(_show_item_detail.bind(lot["item_id"], lot))
	bottom_hbox.add_child(details_btn)
	
	var remove_btn = Button.new()
	remove_btn.text = "СНЯТЬ"
	remove_btn.custom_minimum_size = Vector2(80, 30)
	remove_btn.pressed.connect(_on_remove_lot.bind(lot))
	bottom_hbox.add_child(remove_btn)
	
	return widget

func create_my_lot_widget_in_all(lot: Dictionary, item_info: Dictionary) -> Panel:
	var widget = Panel.new()
	widget.custom_minimum_size.y = 110
	widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.15, 0.9)
	style.border_color = Color(0.5, 1, 0.5, 0.6)
	style.border_width_left = 2
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	widget.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.02
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.98
	widget.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(hbox)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)
	
	var your_label = Label.new()
	your_label.text = "🏷️ ВАШ ЛОТ"
	your_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	your_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(your_label)
	
	var name_label = Label.new()
	name_label.text = item_info.get("name", "???") + " [Ур." + str(item_info.get("level", 1)) + "]"
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)
	
	var seller_date_hbox = HBoxContainer.new()
	info_vbox.add_child(seller_date_hbox)
	
	var seller_icon = Label.new()
	seller_icon.text = "👤"
	seller_icon.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(seller_icon)
	
	var seller_label = Label.new()
	seller_label.text = lot["seller"]
	seller_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	seller_label.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(seller_label)
	
	var date_spacer = Control.new()
	date_spacer.custom_minimum_size.x = 15
	seller_date_hbox.add_child(date_spacer)
	
	var date_icon = Label.new()
	date_icon.text = "📅"
	date_icon.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(date_icon)
	
	var date_label = Label.new()
	date_label.text = lot.get("listed_date", "??")
	date_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	date_label.add_theme_font_size_override("font_size", 12)
	seller_date_hbox.add_child(date_label)
	
	var quantity_hbox = HBoxContainer.new()
	info_vbox.add_child(quantity_hbox)
	
	var quantity_icon = Label.new()
	quantity_icon.text = "📦"
	quantity_icon.add_theme_font_size_override("font_size", 12)
	quantity_hbox.add_child(quantity_icon)
	
	var quantity_label = Label.new()
	quantity_label.text = "x" + str(lot["quantity"])
	quantity_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quantity_label.add_theme_font_size_override("font_size", 14)
	quantity_hbox.add_child(quantity_label)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size.x = 140
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(right_vbox)
	
	var price_hbox = HBoxContainer.new()
	price_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_child(price_hbox)
	
	var use_rune = lot.get("price_rune", 0) > 0
	var price_value = lot["price_rune"] if use_rune else lot["price"]
	
	var price_text = ""
	if use_rune:
		price_text = "🔮 " + str(price_value)
	else:
		price_text = "💰 " + str(price_value)
	
	var price_label = Label.new()
	price_label.text = price_text
	if use_rune:
		price_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	else:
		price_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	price_label.add_theme_font_size_override("font_size", 16)
	price_hbox.add_child(price_label)
	
	var view_btn = Button.new()
	view_btn.text = "СМОТРЕТЬ"
	view_btn.custom_minimum_size = Vector2(110, 35)
	view_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view_btn.pressed.connect(_show_lot_detail.bind("my_" + str(my_lots.find(lot)), lot))
	right_vbox.add_child(view_btn)
	
	return widget

func _show_inventory_for_sale():
	if inventory_popup != null and is_instance_valid(inventory_popup):
		inventory_popup.queue_free()
		inventory_popup = null
	
	inventory_popup = Panel.new()
	inventory_popup.anchor_left = 0.2
	inventory_popup.anchor_top = 0.1
	inventory_popup.anchor_right = 0.8
	inventory_popup.anchor_bottom = 0.9
	add_child(inventory_popup)
	
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
	inventory_popup.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.03
	margin.anchor_top = 0.03
	margin.anchor_right = 0.97
	margin.anchor_bottom = 0.97
	inventory_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "ВЫБЕРИТЕ ПРЕДМЕТ ДЛЯ ПРОДАЖИ"
	title.horizontal_alignment = 1
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var inventory = player_data.get("inventory", [])
	
	if inventory.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "В инвентаре нет предметов"
		empty_label.horizontal_alignment = 1
		empty_label.vertical_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(empty_label)
	else:
		var items_scroll = ScrollContainer.new()
		items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		vbox.add_child(items_scroll)
		
		var items_grid = GridContainer.new()
		items_grid.columns = 2
		items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		items_grid.add_theme_constant_override("h_separation", 20)
		items_grid.add_theme_constant_override("v_separation", 10)
		items_scroll.add_child(items_grid)
		
		for i in range(inventory.size()):
			var item = inventory[i]
			var item_info = items_db.get(item["id"], {})
			
			var item_card = Panel.new()
			item_card.custom_minimum_size = Vector2(200, 100)
			item_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			items_grid.add_child(item_card)
			
			var card_style = StyleBoxFlat.new()
			card_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
			card_style.border_color = Color(1, 0.84, 0, 0.3)
			card_style.border_width_left = 1
			card_style.border_width_right = 1
			card_style.border_width_top = 1
			card_style.border_width_bottom = 1
			card_style.corner_radius_top_left = 5
			card_style.corner_radius_top_right = 5
			card_style.corner_radius_bottom_left = 5
			card_style.corner_radius_bottom_right = 5
			item_card.add_theme_stylebox_override("panel", card_style)
			
			var card_margin = MarginContainer.new()
			card_margin.anchor_left = 0.05
			card_margin.anchor_top = 0.05
			card_margin.anchor_right = 0.95
			card_margin.anchor_bottom = 0.95
			item_card.add_child(card_margin)
			
			var card_vbox = VBoxContainer.new()
			card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card_margin.add_child(card_vbox)
			
			var name_label = Label.new()
			name_label.text = item_info.get("name", "???")
			name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
			name_label.add_theme_font_size_override("font_size", 14)
			card_vbox.add_child(name_label)
			
			var quantity_label = Label.new()
			quantity_label.text = "x" + str(item["quantity"])
			quantity_label.add_theme_font_size_override("font_size", 12)
			card_vbox.add_child(quantity_label)
			
			var level_label = Label.new()
			level_label.text = "Ур. " + str(item_info.get("level", 1))
			level_label.add_theme_font_size_override("font_size", 12)
			card_vbox.add_child(level_label)
			
			var select_btn = Button.new()
			select_btn.text = "ВЫБРАТЬ"
			select_btn.custom_minimum_size.y = 30
			var idx = i
			var itm = item
			var itm_info = item_info
			select_btn.pressed.connect(func(): _show_price_setup(idx, itm, itm_info))
			card_vbox.add_child(select_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size.y = 40
	cancel_btn.pressed.connect(_close_inventory_popup)
	vbox.add_child(cancel_btn)

func _show_price_setup(_item_index: int, item: Dictionary, item_info: Dictionary):
	if sell_popup != null and is_instance_valid(sell_popup):
		sell_popup.queue_free()
		sell_popup = null
	
	_close_inventory_popup()
	
	await get_tree().process_frame
	
	sell_popup = Panel.new()
	sell_popup.anchor_left = 0.3
	sell_popup.anchor_top = 0.3
	sell_popup.anchor_right = 0.7
	sell_popup.anchor_bottom = 0.7
	add_child(sell_popup)
	
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
	sell_popup.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.05
	margin.anchor_top = 0.05
	margin.anchor_right = 0.95
	margin.anchor_bottom = 0.95
	sell_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "ВЫСТАВИТЬ НА ПРОДАЖУ"
	title.horizontal_alignment = 1
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var item_name = Label.new()
	item_name.text = item_info.get("name", "???")
	item_name.add_theme_color_override("font_color", Color(1, 0.84, 0))
	item_name.add_theme_font_size_override("font_size", 18)
	vbox.add_child(item_name)
	
	var item_level = Label.new()
	item_level.text = "Уровень: " + str(item_info.get("level", 1))
	item_level.add_theme_font_size_override("font_size", 14)
	vbox.add_child(item_level)
	
	var item_quantity = Label.new()
	item_quantity.text = "Количество: x" + str(item["quantity"])
	item_quantity.add_theme_font_size_override("font_size", 14)
	vbox.add_child(item_quantity)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1, 0.84, 0, 0.3)
	vbox.add_child(sep)
	
	var price_label = Label.new()
	price_label.text = "Установите цену:"
	price_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(price_label)
	
	var price_input = LineEdit.new()
	price_input.placeholder_text = "Введите цену в золоте"
	price_input.custom_minimum_size.y = 35
	price_input.text = "100"
	vbox.add_child(price_input)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var sell_btn = Button.new()
	sell_btn.text = "ВЫСТАВИТЬ"
	sell_btn.custom_minimum_size = Vector2(150, 40)
	var itm = item
	var pr_input = price_input
	sell_btn.pressed.connect(func(): _confirm_sell_item(itm, pr_input))
	btn_hbox.add_child(sell_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(150, 40)
	cancel_btn.pressed.connect(_close_sell_popup)
	btn_hbox.add_child(cancel_btn)

func _confirm_sell_item(item: Dictionary, price_input: LineEdit):
	if price_input == null or not is_instance_valid(price_input):
		show_message("Ошибка ввода цены!")
		_close_sell_popup()
		return
	
	var price_text = price_input.text.strip_edges()
	if price_text == "":
		show_message("Введите цену!")
		return
	
	var price = int(price_text)
	if price <= 0:
		show_message("Цена должна быть больше 0!")
		return
	
	var inventory = player_data.get("inventory", [])
	
	var found_index = -1
	for i in range(inventory.size()):
		if inventory[i]["id"] == item["id"]:
			found_index = i
			break
	
	if found_index == -1:
		show_message("Предмет больше не доступен!")
		_close_sell_popup()
		return
	
	var current_item = inventory[found_index]
	
	if current_item["quantity"] <= 0:
		show_message("Предмет закончился!")
		_close_sell_popup()
		return
	
	inventory[found_index]["quantity"] -= 1
	if inventory[found_index]["quantity"] <= 0:
		inventory.remove_at(found_index)
	
	var lot_id = "lot_" + str(Time.get_unix_time_from_system()) + "_" + item["id"]
	var time_dict = Time.get_datetime_dict_from_system()
	var date_str = str(time_dict.year) + "-" + str(time_dict.month) + "-" + str(time_dict.day) + " " + str(time_dict.hour) + ":" + str(time_dict.minute)
	
	var new_lot = {
		"item_id": item["id"],
		"seller": player_data.get("name", "Игрок"),
		"price": price,
		"price_rune": 0,
		"quantity": 1,
		"time_left": 86400,
		"listed_date": date_str
	}
	
	my_lots.append(new_lot)
	auction_lots[lot_id] = new_lot
	
	update_auction_lots()
	send_update()
	
	show_message("Предмет выставлен на аукцион!")
	_close_sell_popup()

func _show_lot_detail(lot_id: String, lot: Dictionary):
	selected_lot_id = lot_id
	selected_lot_data = lot
	
	var item_info = items_db.get(lot["item_id"], {})
	if item_info.is_empty():
		return
	
	if detail_popup != null and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.1
	detail_popup.anchor_top = 0.05
	detail_popup.anchor_right = 0.9
	detail_popup.anchor_bottom = 0.95
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
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.03
	margin.anchor_top = 0.03
	margin.anchor_right = 0.97
	margin.anchor_bottom = 0.97
	detail_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var name_label = Label.new()
	name_label.text = item_info.get("name", "???")
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(name_label)
	
	var close_btn_popup = Button.new()
	close_btn_popup.text = "×"
	close_btn_popup.custom_minimum_size = Vector2(40, 40)
	close_btn_popup.pressed.connect(_close_detail_popup)
	title_hbox.add_child(close_btn_popup)
	
	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 30)
	info_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(info_grid)
	
	var level_label = Label.new()
	level_label.text = "Уровень:"
	level_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	level_label.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(level_label)
	
	var level_value = Label.new()
	level_value.text = str(item_info.get("level", 1))
	level_value.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(level_value)
	
	var type_label = Label.new()
	type_label.text = "Тип:"
	type_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	type_label.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(type_label)
	
	var type_value = Label.new()
	var type = item_info.get("type", "")
	if type == "weapon":
		type_value.text = "Оружие"
	elif type == "equipment":
		var slot = item_info.get("slot", "")
		if slot == "weapon":
			type_value.text = "Оружие"
		elif slot == "armor":
			type_value.text = "Броня"
		else:
			type_value.text = "Экипировка"
	elif type == "consumable":
		type_value.text = "Расходник"
	else:
		type_value.text = type.capitalize()
	type_value.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(type_value)
	
	var seller_label = Label.new()
	seller_label.text = "Продавец:"
	seller_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	seller_label.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(seller_label)
	
	var seller_value = Label.new()
	seller_value.text = lot.get("seller", "Неизвестно")
	seller_value.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(seller_value)
	
	var date_label = Label.new()
	date_label.text = "Выставлено:"
	date_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	date_label.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(date_label)
	
	var date_value = Label.new()
	date_value.text = lot.get("listed_date", "Неизвестно")
	date_value.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(date_value)
	
	var quantity_label = Label.new()
	quantity_label.text = "Количество:"
	quantity_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quantity_label.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(quantity_label)
	
	var quantity_value = Label.new()
	quantity_value.text = "x" + str(lot["quantity"])
	quantity_value.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(quantity_value)
	
	var price_label = Label.new()
	price_label.text = "Цена:"
	price_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	price_label.add_theme_font_size_override("font_size", 16)
	info_grid.add_child(price_label)
	
	var price_hbox = HBoxContainer.new()
	info_grid.add_child(price_hbox)
	
	var use_rune = lot.get("price_rune", 0) > 0
	var price_value = lot["price_rune"] if use_rune else lot["price"]
	
	var price_text = ""
	if use_rune:
		price_text = "🔮 " + str(price_value)
	else:
		price_text = "💰 " + str(price_value)
	
	var price_value_label = Label.new()
	price_value_label.text = price_text
	if use_rune:
		price_value_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	else:
		price_value_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	price_value_label.add_theme_font_size_override("font_size", 18)
	price_hbox.add_child(price_value_label)
	
	var player_stats = player_data.get("stats", {})
	var reqs = item_info.get("requirements", {})
	
	if reqs.size() > 0:
		var req_title = Label.new()
		req_title.text = "Требования:"
		req_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		req_title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(req_title)
		
		for stat in reqs:
			var need = reqs[stat]
			var have = player_stats.get(stat, 0)
			var stat_name = get_stat_name(stat)
			
			var stat_label = Label.new()
			stat_label.text = stat_name + ": " + str(have) + " / " + str(need)
			stat_label.add_theme_color_override("font_color", Color(0, 1, 0) if have >= need else Color(1, 0, 0))
			stat_label.add_theme_font_size_override("font_size", 16)
			vbox.add_child(stat_label)
	
	var bonuses = item_info.get("bonuses", {})
	if bonuses.size() > 0:
		var bonus_title = Label.new()
		bonus_title.text = "Бонусы:"
		bonus_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		bonus_title.add_theme_font_size_override("font_size", 16)
		vbox.add_child(bonus_title)
		
		for bonus in bonuses:
			var value = bonuses[bonus]
			var bonus_name = get_bonus_name(bonus)
			
			var b_label = Label.new()
			b_label.text = bonus_name + ": +" + str(value)
			b_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			b_label.add_theme_font_size_override("font_size", 16)
			vbox.add_child(b_label)
	
	var dur = item_info.get("durability", -1)
	if dur > 0:
		var dur_label = Label.new()
		dur_label.text = "Прочность: " + str(dur)
		dur_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		dur_label.add_theme_font_size_override("font_size", 16)
		vbox.add_child(dur_label)
	
	var desc_title = Label.new()
	desc_title.text = "Описание:"
	desc_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	desc_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(desc_title)
	
	var desc_text = Label.new()
	desc_text.text = item_info.get("description", "")
	desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_text.add_theme_font_size_override("font_size", 15)
	desc_text.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(desc_text)
	
	var lore_title = Label.new()
	lore_title.text = "История предмета:"
	lore_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	lore_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lore_title)
	
	var lore_text = Label.new()
	lore_text.text = item_info.get("lore", "Легенды умалчивают о происхождении этого предмета.")
	lore_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lore_text.add_theme_font_size_override("font_size", 15)
	lore_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(lore_text)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 30)
	btn_hbox.size_flags_vertical = Control.SIZE_SHRINK_END
	vbox.add_child(btn_hbox)
	
	var buy_hbox = HBoxContainer.new()
	buy_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_child(buy_hbox)
	
	var buy_btn = Button.new()
	buy_btn.text = "КУПИТЬ " + price_text
	buy_btn.custom_minimum_size = Vector2(200, 45)
	buy_hbox.add_child(buy_btn)
	
	buy_btn.pressed.connect(_on_buy_from_detail)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ОТМЕНА"
	cancel_btn.custom_minimum_size = Vector2(140, 45)
	cancel_btn.pressed.connect(_close_detail_popup)
	btn_hbox.add_child(cancel_btn)

func _show_item_detail(item_id: String, _lot: Dictionary):
	if detail_popup != null and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	
	var item_info = items_db.get(item_id, {})
	if item_info.is_empty():
		return
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.15
	detail_popup.anchor_top = 0.1
	detail_popup.anchor_right = 0.85
	detail_popup.anchor_bottom = 0.9
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
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.03
	margin.anchor_top = 0.03
	margin.anchor_right = 0.97
	margin.anchor_bottom = 0.97
	detail_popup.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var name_label = Label.new()
	name_label.text = item_info.get("name", "???")
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(name_label)
	
	var close_btn_popup = Button.new()
	close_btn_popup.text = "×"
	close_btn_popup.custom_minimum_size = Vector2(40, 40)
	close_btn_popup.pressed.connect(_close_detail_popup)
	title_hbox.add_child(close_btn_popup)
	
	var info_text = ""
	info_text += "Тип: " + str(item_info.get("type", "?")) + "\n"
	info_text += "Уровень: " + str(item_info.get("level", 1)) + "\n"
	info_text += "Описание: " + item_info.get("description", "Нет описания") + "\n\n"
	info_text += "История: " + item_info.get("lore", "Нет истории")
	
	var info_label = Label.new()
	info_label.text = info_text
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(info_label)
	
	var close_only_btn = Button.new()
	close_only_btn.text = "ЗАКРЫТЬ"
	close_only_btn.custom_minimum_size = Vector2(200, 45)
	close_only_btn.pressed.connect(_close_detail_popup)
	vbox.add_child(close_only_btn)

func _on_buy_from_detail():
	if selected_lot_id == "" or selected_lot_data.is_empty():
		_close_detail_popup()
		return
	
	_on_buy_lot(selected_lot_id, selected_lot_data)

func _on_buy_lot(lot_id: String, lot: Dictionary):
	var use_rune = lot.get("price_rune", 0) > 0
	var price = lot["price_rune"] if use_rune else lot["price"]
	var currency = "rune" if use_rune else "gold"
	var player_currency = player_data.get(currency, 0)
	
	if player_currency < price:
		if use_rune:
			show_message("Недостаточно рун!")
		else:
			show_message("Недостаточно золота!")
		_close_detail_popup()
		return
	
	player_data[currency] = player_currency - price
	
	var inventory = player_data.get("inventory", [])
	var found = false
	for i in range(inventory.size()):
		if inventory[i]["id"] == lot["item_id"]:
			inventory[i]["quantity"] += lot["quantity"]
			found = true
			break
	
	if not found:
		inventory.append({"id": lot["item_id"], "quantity": lot["quantity"]})
	
	player_data["inventory"] = inventory
	
	auction_lots.erase(lot_id)
	
	for i in range(my_lots.size()):
		if my_lots[i] == lot:
			my_lots.remove_at(i)
			break
	
	update_auction_lots()
	update_currency()
	send_update()
	
	show_message("Покупка совершена!")
	_close_detail_popup()

func _on_remove_lot(lot: Dictionary):
	for i in range(my_lots.size()):
		if my_lots[i] == lot:
			my_lots.remove_at(i)
			break
	
	var inventory = player_data.get("inventory", [])
	var found = false
	for i in range(inventory.size()):
		if inventory[i]["id"] == lot["item_id"]:
			inventory[i]["quantity"] += lot["quantity"]
			found = true
			break
	
	if not found:
		inventory.append({"id": lot["item_id"], "quantity": lot["quantity"]})
	
	player_data["inventory"] = inventory
	
	var lot_id_to_remove = ""
	for lot_id in auction_lots:
		if auction_lots[lot_id] == lot:
			lot_id_to_remove = lot_id
			break
	
	if lot_id_to_remove != "":
		auction_lots.erase(lot_id_to_remove)
	
	update_auction_lots()
	send_update()
	
	show_message("Лот снят с торгов")

func _on_category_pressed(category: String):
	current_category = category
	for cat in category_buttons:
		category_buttons[cat].modulate = Color(1, 1, 1, 1.0 if cat == category else 0.5)
	update_auction_lots()

func _on_search_changed(text: String):
	search_query = text
	update_auction_lots()

func _on_sort_pressed():
	if sort_order == "asc":
		sort_order = "desc"
		sort_btn.text = "Цена ↓"
	else:
		sort_order = "asc"
		sort_btn.text = "Цена ↑"
	update_auction_lots()

func _close_inventory_popup():
	if inventory_popup != null and is_instance_valid(inventory_popup):
		inventory_popup.queue_free()
		inventory_popup = null

func _close_sell_popup():
	if sell_popup != null and is_instance_valid(sell_popup):
		sell_popup.queue_free()
		sell_popup = null

func _close_detail_popup():
	if detail_popup != null and is_instance_valid(detail_popup):
		detail_popup.queue_free()
		detail_popup = null
	selected_lot_id = ""
	selected_lot_data = {}

func show_message(text: String):
	var message = AcceptDialog.new()
	message.dialog_text = text
	message.title = "Аукцион"
	add_child(message)
	message.popup_centered()
	
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(message):
		message.queue_free()

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

func send_update():
	if NetworkManager != null:
		if NetworkManager.player_data != null:
			NetworkManager.player_data["gold"] = player_data.get("gold", 0)
			NetworkManager.player_data["rune"] = player_data.get("rune", 0)
			NetworkManager.player_data["inventory"] = player_data.get("inventory", [])
			NetworkManager.send("PLAYER_DATA_UPDATE|" + JSON.stringify({
				"gold": player_data.get("gold", 0),
				"rune": player_data.get("rune", 0),
				"inventory": player_data.get("inventory", [])
			}))

func _on_network_data(data: String):
	var parts = data.split("|")
	if parts[0] == "PLAYER_DATA_UPDATE_OK":
		pass
	elif parts[0] == "PLAYER_DATA_UPDATE_FAIL":
		load_player_data()
		update_auction_lots()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	update_currency()
	update_auction_lots()

func _on_close():
	queue_free()
