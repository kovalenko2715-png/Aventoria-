# res://modules/market.gd
extends Panel

# ===== БАЗА ДАННЫХ ТОВАРОВ =====
var shop_items = {
	"iron_sword": {
		"name": "Железный меч",
		"type": "weapon",
		"level": 2,
		"description": "Обычный железный меч.",
		"durability": 100,
		"price_gold": 100,
		"price_rune": 0,
		"rarity": "обычный",
		"requirements": {"strength": 5, "agility": 3},
		"bonuses": {"attack": 10, "crit_chance": 2}
	},
	"steel_sword": {
		"name": "Стальной меч",
		"type": "weapon",
		"level": 4,
		"description": "Качественный стальной меч.",
		"durability": 120,
		"price_gold": 250,
		"price_rune": 0,
		"rarity": "редкий",
		"requirements": {"strength": 8, "agility": 5},
		"bonuses": {"attack": 15, "crit_chance": 3}
	},
	"elite_sword": {
		"name": "Элитный меч",
		"type": "weapon",
		"level": 10,
		"description": "Меч древних героев.",
		"durability": 200,
		"price_gold": 0,
		"price_rune": 100,
		"rarity": "легендарный",
		"requirements": {"strength": 25, "agility": 20},
		"bonuses": {"attack": 50, "crit_chance": 10}
	},
	"health_potion": {
		"name": "Зелье здоровья",
		"type": "consumable",
		"level": 1,
		"description": "Восстанавливает 50 HP.",
		"durability": -1,
		"price_gold": 10,
		"price_rune": 0,
		"rarity": "обычный",
		"requirements": {},
		"bonuses": {"hp_restore": 50}
	},
	"leather_armor": {
		"name": "Кожаная броня",
		"type": "armor",
		"level": 1,
		"description": "Лёгкая броня из кожи.",
		"durability": 80,
		"price_gold": 80,
		"price_rune": 0,
		"rarity": "обычный",
		"requirements": {"endurance": 3},
		"bonuses": {"defense": 8, "evasion": 2}
	}
}

# ===== ПРИВЕТСТВИЯ =====
var greetings = [
	"Добро пожаловать, путник!",
	"Что ищешь сегодня?",
	"Заходи, не стесняйся!",
	"Свежие товары только привезли!"
]

# ===== ПЕРЕМЕННЫЕ =====
var player_data = {}
var current_mode = "menu"  # "menu", "shop", "rune_shop", "sell"
var current_shop_type = "normal"  # "normal" или "rune"
var selected_item_id = null

# ===== ИНТЕРФЕЙС =====
var close_btn
var greeting_label
var gold_label
var rune_label
var menu_panel
var shop_panel
var sell_panel
var back_btn
var detail_popup = null

# Кнопки меню
var shop_btn
var rune_shop_btn
var sell_btn

# Элементы магазина
var items_container
var sell_container
var category_buttons = {}
var filter_panel
var current_category = "weapon"
var current_subtype = "all"

func _ready():
	build_ui()
	load_player_data()
	show_menu()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager != null:
		if NetworkManager.has_signal("data_received"):
			NetworkManager.data_received.connect(_on_network_data)
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

func build_ui():
	# Размер и положение окна
	anchor_left = 0.1
	anchor_top = 0.05
	anchor_right = 0.9
	anchor_bottom = 0.95
	
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
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.02
	vbox.anchor_top = 0.02
	vbox.anchor_right = 0.98
	vbox.anchor_bottom = 0.98
	add_child(vbox)
	
	# Верхняя панель
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "ЛАВКА"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	# Приветствие
	greeting_label = Label.new()
	greeting_label.text = greetings[randi() % greetings.size()]
	greeting_label.horizontal_alignment = 1
	greeting_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	greeting_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(greeting_label)
	
	# Кнопка "Назад" (изначально скрыта)
	back_btn = Button.new()
	back_btn.text = "← Назад"
	back_btn.visible = false
	back_btn.pressed.connect(show_menu)
	vbox.add_child(back_btn)
	
	# Информация о валюте
	var currency_row = HBoxContainer.new()
	currency_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(currency_row)
	
	gold_label = Label.new()
	gold_label.text = "💰 Золото: 0"
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	gold_label.add_theme_font_size_override("font_size", 16)
	currency_row.add_child(gold_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 30
	currency_row.add_child(spacer)
	
	rune_label = Label.new()
	rune_label.text = "🔮 Забытые руны: 0"
	rune_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	rune_label.add_theme_font_size_override("font_size", 16)
	currency_row.add_child(rune_label)
	
	# Панель меню (3 кнопки)
	menu_panel = VBoxContainer.new()
	menu_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(menu_panel)
	
	shop_btn = Button.new()
	shop_btn.text = "МАГАЗИН (золото)"
	shop_btn.custom_minimum_size = Vector2(200, 50)
	shop_btn.pressed.connect(_on_shop_pressed)
	menu_panel.add_child(shop_btn)
	
	rune_shop_btn = Button.new()
	rune_shop_btn.text = "РУННЫЙ МАГАЗИН"
	rune_shop_btn.custom_minimum_size = Vector2(200, 50)
	rune_shop_btn.pressed.connect(_on_rune_shop_pressed)
	menu_panel.add_child(rune_shop_btn)
	
	sell_btn = Button.new()
	sell_btn.text = "ПРОДАТЬ"
	sell_btn.custom_minimum_size = Vector2(200, 50)
	sell_btn.pressed.connect(_on_sell_pressed)
	menu_panel.add_child(sell_btn)
	
	# Панель магазина (изначально скрыта)
	shop_panel = VBoxContainer.new()
	shop_panel.visible = false
	shop_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(shop_panel)
	
	# Категории для магазина
	var category_row = HBoxContainer.new()
	category_row.alignment = BoxContainer.ALIGNMENT_CENTER
	category_row.custom_minimum_size.y = 40
	shop_panel.add_child(category_row)
	
	var categories = ["ОРУЖИЕ", "БРОНЯ", "БИЖУТЕРИЯ", "ПРОЧЕЕ"]
	var category_keys = ["weapon", "armor", "jewelry", "other"]
	
	for i in range(categories.size()):
		var btn = Button.new()
		btn.text = categories[i]
		btn.custom_minimum_size.x = 120
		btn.pressed.connect(_on_category_pressed.bind(category_keys[i]))
		category_row.add_child(btn)
		category_buttons[category_keys[i]] = btn
	
	# Контейнер для товаров
	var items_scroll = ScrollContainer.new()
	items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	shop_panel.add_child(items_scroll)
	
	items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_scroll.add_child(items_container)
	
	# Панель продажи (изначально скрыта)
	sell_panel = VBoxContainer.new()
	sell_panel.visible = false
	sell_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sell_panel)
	
	# Сетка инвентаря 6 колонок
	var sell_scroll = ScrollContainer.new()
	sell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sell_panel.add_child(sell_scroll)
	
	sell_container = GridContainer.new()  # Используем GridContainer вместо VBoxContainer
	sell_container.columns = 6
	sell_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_scroll.add_child(sell_container)

func load_player_data():
	if NetworkManager != null and NetworkManager.player_data != null:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {
			"gold": 1000,
			"rune": 50,
			"inventory": [
				{"id": "health_potion", "quantity": 3},
				{"id": "iron_sword", "quantity": 1}
			],
			"stats": {
				"strength": 10,
				"agility": 8,
				"intuition": 5,
				"endurance": 12,
				"intellect": 6,
				"wisdom": 4,
				"spirit": 3
			}
		}
	update_currency()

func update_currency():
	gold_label.text = "💰 Золото: " + str(player_data.get("gold", 0))
	rune_label.text = "🔮 Забытые руны: " + str(player_data.get("rune", 0))

func show_menu():
	current_mode = "menu"
	menu_panel.visible = true
	shop_panel.visible = false
	sell_panel.visible = false
	back_btn.visible = false
	update_currency()

func _on_shop_pressed():
	current_mode = "shop"
	current_shop_type = "normal"
	menu_panel.visible = false
	shop_panel.visible = true
	back_btn.visible = true
	update_currency()
	update_shop_items()

func _on_rune_shop_pressed():
	current_mode = "shop"
	current_shop_type = "rune"
	menu_panel.visible = false
	shop_panel.visible = true
	back_btn.visible = true
	update_currency()
	update_shop_items()

func _on_sell_pressed():
	current_mode = "sell"
	menu_panel.visible = false
	sell_panel.visible = true
	back_btn.visible = true
	update_currency()
	update_sell_items()

func update_shop_items():
	# Очищаем контейнер
	for child in items_container.get_children():
		child.queue_free()
	
	var items_to_show = []
	var price_field = "price_gold" if current_shop_type == "normal" else "price_rune"
	
	for item_id in shop_items:
		var item = shop_items[item_id]
		
		# Фильтр по цене
		if current_shop_type == "normal" and item["price_gold"] <= 0:
			continue
		if current_shop_type == "rune" and item["price_rune"] <= 0:
			continue
		
		# Фильтр по категории
		if current_category == "weapon" and item["type"] != "weapon":
			continue
		if current_category == "armor" and item["type"] != "armor":
			continue
		if current_category == "jewelry" and item["type"] != "jewelry":
			continue
		if current_category == "other" and item["type"] not in ["consumable", "material"]:
			continue
		
		items_to_show.append({"id": item_id, "data": item})
	
	# Создаём строки товаров
	for item_data in items_to_show:
		var item_row = create_shop_item_row(item_data["id"], item_data["data"], price_field)
		items_container.add_child(item_row)

func update_sell_items():
	# Очищаем контейнер
	for child in sell_container.get_children():
		child.queue_free()
	
	var inventory = player_data.get("inventory", [])
	
	# Сначала показываем предметы из инвентаря
	for i in range(inventory.size()):
		var item_data = inventory[i]
		var item_id = item_data["id"]
		var quantity = item_data["quantity"]
		var item_info = shop_items.get(item_id)
		
		if item_info == null:
			continue
		
		var item_cell = create_sell_item_cell(i, item_id, item_info, quantity)
		sell_container.add_child(item_cell)
	
	# Добавляем пустые ячейки до 48 (6x8)
	var total_slots = 48
	for i in range(inventory.size(), total_slots):
		var empty_cell = create_empty_cell()
		sell_container.add_child(empty_cell)

func create_empty_cell() -> Button:
	var cell = Button.new()
	cell.custom_minimum_size = Vector2(70, 80)
	cell.disabled = true
	cell.modulate = Color(0.3, 0.3, 0.3, 0.5)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_child(vbox)
	
	var icon = Label.new()
	icon.text = "□"
	icon.horizontal_alignment = 1
	icon.vertical_alignment = 1
	icon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	icon.add_theme_font_size_override("font_size", 24)
	vbox.add_child(icon)
	
	var label = Label.new()
	label.text = "пусто"
	label.horizontal_alignment = 1
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(label)
	
	return cell

func create_shop_item_row(item_id: String, item: Dictionary, price_field: String) -> Panel:
	var row = Panel.new()
	row.custom_minimum_size.y = 60
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	style.border_color = get_rarity_color(item.get("rarity", "обычный"))
	style.border_width_left = 2
	style.border_width_bottom = 1
	row.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.anchor_left = 0.01
	hbox.anchor_right = 0.99
	row.add_child(hbox)
	
	# Иконка
	var icon = Label.new()
	icon.text = "■"
	icon.custom_minimum_size = Vector2(30, 30)
	icon.add_theme_color_override("font_color", get_rarity_color(item.get("rarity", "обычный")))
	icon.add_theme_font_size_override("font_size", 20)
	hbox.add_child(icon)
	
	# Название и уровень
	var name_label = Label.new()
	name_label.text = item["name"] + " (Ур." + str(item["level"]) + ")"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	# Цена
	var price_label = Label.new()
	price_label.text = str(item[price_field]) + ("💰" if price_field == "price_gold" else "🔮")
	price_label.add_theme_color_override("font_color", Color(1, 0.84, 0) if price_field == "price_gold" else Color(0.5, 0.8, 1))
	price_label.custom_minimum_size.x = 60
	hbox.add_child(price_label)
	
	# Обработчик клика
	row.gui_input.connect(_on_shop_item_click.bind(item_id))
	
	return row

func create_sell_item_cell(index: int, item_id: String, item: Dictionary, quantity: int) -> Button:
	var cell = Button.new()
	cell.custom_minimum_size = Vector2(70, 80)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_child(vbox)
	
	# Иконка
	var icon = Label.new()
	icon.text = "■"
	icon.horizontal_alignment = 1
	icon.vertical_alignment = 1
	icon.add_theme_color_override("font_color", get_rarity_color(item.get("rarity", "обычный")))
	icon.add_theme_font_size_override("font_size", 24)
	vbox.add_child(icon)
	
	# Название и количество
	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.horizontal_alignment = 1
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)
	
	var quantity_label = Label.new()
	quantity_label.text = "x" + str(quantity)
	quantity_label.horizontal_alignment = 1
	quantity_label.add_theme_font_size_override("font_size", 10)
	quantity_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(quantity_label)
	
	# Цена продажи (половина цены покупки)
	var sell_price = item.get("price_gold", 0) / 2
	cell.pressed.connect(_on_sell_item_pressed.bind(index, item_id, sell_price))
	
	return cell

func _on_shop_item_click(event: InputEvent, item_id: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_item_detail(item_id, "shop")

func _on_sell_item_pressed(index: int, item_id: String, price: int):
	show_sell_confirm(index, item_id, price)

func show_item_detail(item_id: String, source: String):
	if detail_popup != null:
		detail_popup.queue_free()
	
	var item = shop_items.get(item_id)
	if item == null:
		return
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.2
	detail_popup.anchor_top = 0.2
	detail_popup.anchor_right = 0.8
	detail_popup.anchor_bottom = 0.8
	add_child(detail_popup)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.98)
	style.border_color = get_rarity_color(item.get("rarity", "обычный"))
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
	vbox.anchor_left = 0.02
	vbox.anchor_top = 0.02
	vbox.anchor_right = 0.98
	vbox.anchor_bottom = 0.98
	detail_popup.add_child(vbox)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(_close_detail_popup)
	vbox.add_child(close_btn)
	
	# Название
	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.add_theme_color_override("font_color", get_rarity_color(item.get("rarity", "обычный")))
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)
	
	# Уровень
	var level_label = Label.new()
	level_label.text = "Уровень: " + str(item["level"])
	vbox.add_child(level_label)
	
	# Требования
	var player_stats = player_data.get("stats", {})
	var reqs = item.get("requirements", {})
	
	if reqs.size() > 0:
		var req_title = Label.new()
		req_title.text = "Требования:"
		req_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		vbox.add_child(req_title)
		
		for stat in reqs:
			var need = reqs[stat]
			var have = player_stats.get(stat, 0)
			var stat_name = get_stat_name(stat)
			
			var req_label = Label.new()
			req_label.text = stat_name + ": " + str(have) + " / " + str(need)
			req_label.add_theme_color_override("font_color", Color(0, 1, 0) if have >= need else Color(1, 0, 0))
			vbox.add_child(req_label)
	
	# Бонусы
	var bonuses = item.get("bonuses", {})
	if bonuses.size() > 0:
		var bonus_title = Label.new()
		bonus_title.text = "Характеристики:"
		bonus_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
		vbox.add_child(bonus_title)
		
		for bonus in bonuses:
			var value = bonuses[bonus]
			var bonus_name = get_bonus_name(bonus)
			
			var bonus_label = Label.new()
			bonus_label.text = bonus_name + ": +" + str(value)
			bonus_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			vbox.add_child(bonus_label)
	
	# Прочность
	if item.get("durability", -1) > 0:
		var dur_label = Label.new()
		dur_label.text = "Прочность: " + str(item["durability"]) + "/" + str(item["durability"])
		vbox.add_child(dur_label)
	
	# Описание
	var desc_label = Label.new()
	desc_label.text = item.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Цена и кнопка покупки (только для магазина)
	if source == "shop":
		var price_field = "price_gold" if current_shop_type == "normal" else "price_rune"
		var price_icon = "💰" if current_shop_type == "normal" else "🔮"
		var price = item[price_field]
		
		var price_label = Label.new()
		price_label.text = "Цена: " + str(price) + " " + price_icon
		price_label.add_theme_color_override("font_color", Color(1, 0.84, 0) if current_shop_type == "normal" else Color(0.5, 0.8, 1))
		vbox.add_child(price_label)
		
		var buy_btn = Button.new()
		buy_btn.text = "КУПИТЬ"
		buy_btn.pressed.connect(_on_buy_item.bind(item_id, price))
		vbox.add_child(buy_btn)

func show_sell_confirm(index: int, item_id: String, price: int):
	if detail_popup != null:
		detail_popup.queue_free()
	
	detail_popup = Panel.new()
	detail_popup.anchor_left = 0.3
	detail_popup.anchor_top = 0.3
	detail_popup.anchor_right = 0.7
	detail_popup.anchor_bottom = 0.7
	add_child(detail_popup)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.98)
	style.border_color = Color(1, 0.84, 0, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	detail_popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.1
	vbox.anchor_top = 0.1
	vbox.anchor_right = 0.9
	vbox.anchor_bottom = 0.9
	detail_popup.add_child(vbox)
	
	var label = Label.new()
	label.text = "Продать за " + str(price) + "💰?"
	label.horizontal_alignment = 1
	vbox.add_child(label)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)
	
	var yes_btn = Button.new()
	yes_btn.text = "ДА"
	yes_btn.pressed.connect(_on_sell_confirm.bind(index, price))
	btn_hbox.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "НЕТ"
	no_btn.pressed.connect(_close_detail_popup)
	btn_hbox.add_child(no_btn)

func _on_buy_item(item_id: String, price: int):
	var currency = "gold" if current_shop_type == "normal" else "rune"
	
	if player_data.get(currency, 0) < price:
		_close_detail_popup()
		return
	
	player_data[currency] = player_data.get(currency, 0) - price
	
	if not player_data.has("inventory"):
		player_data["inventory"] = []
	
	var found = false
	for i in range(player_data["inventory"].size()):
		if player_data["inventory"][i]["id"] == item_id:
			player_data["inventory"][i]["quantity"] += 1
			found = true
			break
	
	if not found:
		player_data["inventory"].append({"id": item_id, "quantity": 1})
	
	update_currency()
	send_update()
	_close_detail_popup()
	
	# Обновляем инвентарь если мы в режиме продажи
	if current_mode == "sell":
		update_sell_items()

func _on_sell_confirm(index: int, price: int):
	var inventory = player_data.get("inventory", [])
	
	if index < 0 or index >= inventory.size():
		_close_detail_popup()
		return
	
	# Уменьшаем количество или удаляем предмет
	if inventory[index]["quantity"] > 1:
		inventory[index]["quantity"] -= 1
	else:
		inventory.remove_at(index)
	
	# Добавляем золото
	player_data["gold"] = player_data.get("gold", 0) + price
	
	update_currency()
	update_sell_items()
	send_update()
	_close_detail_popup()

func _on_category_pressed(category: String):
	current_category = category
	for cat in category_buttons:
		category_buttons[cat].modulate = Color(1, 1, 1, 1.0 if cat == category else 0.5)
	update_shop_items()

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"обычный": return Color(0.8, 0.8, 0.8)
		"редкий": return Color(0.3, 0.6, 1)
		"легендарный": return Color(1, 0.8, 0)
		_: return Color(0.8, 0.8, 0.8)

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
		"health": return "Здоровье"
		"mana": return "Мана"
		"crit_chance": return "Шанс крита"
		"hp_restore": return "Восст. HP"
		_: return bonus.capitalize()

func _close_detail_popup():
	if detail_popup != null:
		detail_popup.queue_free()
		detail_popup = null

func send_update():
	if NetworkManager != null:
		NetworkManager.player_data = player_data.duplicate()
		NetworkManager.send("PLAYER_DATA_UPDATE|" + JSON.stringify(player_data))
		
		# ВАЖНО: испускаем сигнал для обновления главного экрана
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.emit(player_data)

func _on_network_data(data: String):
	var parts = data.split("|")
	if parts[0] == "PLAYER_DATA_UPDATE_OK":
		pass
	elif parts[0] == "PLAYER_DATA_UPDATE_FAIL":
		load_player_data()
		update_currency()
		if current_mode == "sell":
			update_sell_items()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	update_currency()
	if current_mode == "sell":
		update_sell_items()

func _on_close():
	queue_free()
