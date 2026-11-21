# res://modules/tavern.gd (ПОЛНАЯ ВЕРСИЯ - ТОЛЬКО ЗОЛОТО)
extends Panel

# =============================================================================
# ТАВЕРНА "ПЬЯНЫЙ ДРАКОН"
# =============================================================================

# ----- БАЗА ДАННЫХ ЕДЫ (Бармен) -----
var food_db = {
	"hot_soup": {
		"name": "Горячая похлёбка",
		"description": "Наваристый суп с мясом и травами. Согревает и бодрит.",
		"price_gold": 10,
		"duration": 1800,
		"buff_type": "exp",
		"buff_value": 10,
		"icon": "🍲"
	},
	"shrimp": {
		"name": "Креветки с чесноком",
		"description": "Сочные креветки, запечённые с чесноком и маслом.",
		"price_gold": 15,
		"duration": 1800,
		"buff_type": "max_hp",
		"buff_value": 15,
		"icon": "🦐"
	},
	"dwarf_ale": {
		"name": "Эль дворфа",
		"description": "Крепкий напиток, сваренный по древнему рецепту.",
		"price_gold": 20,
		"duration": 1800,
		"buff_type": "strength",
		"buff_value": 5,
		"icon": "🍺"
	},
	"vigor_elixir": {
		"name": "Эликсир бодрости",
		"description": "Настой из горных трав придаёт невероятную лёгкость.",
		"price_gold": 25,
		"duration": 1800,
		"buff_type": "speed",
		"buff_value": 10,
		"icon": "🧪"
	},
	"mead": {
		"name": "Медовуха",
		"description": "Сладкий хмельной напиток на мёде и травах.",
		"price_gold": 30,
		"duration": 1800,
		"buff_type": "defense",
		"buff_value": 10,
		"icon": "🍯"
	},
	"gnome_feast": {
		"name": "Пирушка гномов",
		"description": "Гномье застолье с жареным мясом и золотистым элем.",
		"price_gold": 50,
		"duration": 3600,
		"buff_type": "gold",
		"buff_value": 20,
		"icon": "🍖"
	}
}

# ----- БАЗА ДАННЫХ ПЕСЕН (Бард) - ТОЛЬКО ЗОЛОТО -----
var songs_db = {
	"ballad_courage": {
		"name": "Баллада о храбрости",
		"description": "Песнь о древних героях, вселяющая отвагу.",
		"price_gold": 50,
		"duration": 3600,
		"buff_type": "attack",
		"buff_value": 15,
		"icon": "⚔️"
	},
	"elegy_protection": {
		"name": "Элегия защиты",
		"description": "Меланхоличная мелодия, дарующая несокрушимость.",
		"price_gold": 50,
		"duration": 3600,
		"buff_type": "defense",
		"buff_value": 20,
		"icon": "🛡️"
	},
	"lucky_song": {
		"name": "Песня удачи",
		"description": "Весёлая песенка про беззаботного вора.",
		"price_gold": 75,
		"duration": 3600,
		"buff_type": "crit_chance",
		"buff_value": 10,
		"icon": "🍀"
	},
	"ancient_hymn": {
		"name": "Древний гимн",
		"description": "Гимн на забытом языке, открывающий тайны мира.",
		"price_gold": 100,
		"duration": 3600,
		"buff_type": "exp",
		"buff_value": 15,
		"icon": "📜"
	},
	"wind_song": {
		"name": "Песня ветров",
		"description": "Лёгкая мелодия, похожая на шелест крыльев.",
		"price_gold": 75,
		"duration": 3600,
		"buff_type": "evasion",
		"buff_value": 10,
		"icon": "🌬️"
	},
	"restoration_hymn": {
		"name": "Гимн восстановления",
		"description": "Целебная музыка, залечивающая раны.",
		"price_gold": 125,
		"duration": 3600,
		"buff_type": "regen",
		"buff_value": 5,
		"icon": "💚"
	},
	"dragon_song": {
		"name": "Песнь дракона",
		"description": "Древняя песнь, дающая силу огнедышащего зверя.",
		"price_gold": 200,
		"duration": 3600,
		"buff_type": "berserk",
		"buff_value": 25,
		"icon": "🐉"
	}
}

# ----- СЛУХИ НЕЗНАКОМЦА (ТОЛЬКО ЗОЛОТО) -----
var stranger_rumors = {
	"r1": {"name": "Шёпот в катакомбах", "price": 50, "text": "Под городом есть забытые катакомбы, где обитает нечто древнее. Говорят, там можно найти артефакты павшего ордена.", "icon": "👤"},
	"r2": {"name": "Демонический ритуал", "price": 75, "text": "Барон заключает сделки с демонами по ночам. Из его замка доносятся крики и зелёное пламя.", "icon": "👤"},
	"r3": {"name": "Призрачный рыцарь", "price": 60, "text": "В полночь на старом кладбище появляется призрачный рыцарь. Он ищет своё потерянное копьё.", "icon": "👤"},
	"r4": {"name": "Ночная ведьма", "price": 80, "text": "Говорят, ведьма в лесу может предсказать судьбу за одну руну. Но цена её пророчеств — частичка души.", "icon": "👤"},
	"r5": {"name": "Проклятый театр", "price": 55, "text": "Старый театр заколочен уже 50 лет. Внутри продолжаются представления с участием теней умерших актёров.", "icon": "👤"},
	"r6": {"name": "Культ Чёрного Сердца", "price": 90, "text": "В подземельях гильдии магов собирается культ Чёрного Сердца. Их знак — выжженная ладонь.", "icon": "👤"},
	"r7": {"name": "Вампир в городе", "price": 70, "text": "Среди знати завёлся вампир. Уже три девушки из богатых семей найдены обескровленными.", "icon": "👤"},
	"r8": {"name": "Озеро мёртвых", "price": 85, "text": "Западнее города есть озеро, где вода чёрная как смоль. Рыбаки пропадают там каждую весну.", "icon": "👤"},
	"r9": {"name": "Проклятие оборотня", "price": 65, "text": "Мясник с южной улицы каждое полнолуние превращается в зверя. Он сам не знает об этом.", "icon": "👤"},
	"r10": {"name": "Говорящий череп", "price": 100, "text": "В подвале старой башни хранится череп, который отвечает на вопросы. Каждый ответ отнимает год жизни.", "icon": "👤"},
	"r11": {"name": "Тёмный алтарь", "price": 95, "text": "В чащобе есть алтарь из чёрного камня. Если принести жертву, твоя тень оживёт.", "icon": "👤"},
	"r12": {"name": "Повелитель крыс", "price": 45, "text": "В канализации живёт Король Крыс. Говорят, у него есть кольцо, делающее хозяина невидимым.", "icon": "👤"},
	"r13": {"name": "Проклятое зеркало", "price": 110, "text": "В особняке купца висит зеркало, в котором отражается будущее. Тот, кто посмотрит в него, умрёт в течение года.", "icon": "👤"},
	"r14": {"name": "Некромант-отшельник", "price": 120, "text": "В горах живёт некромант, воскрешающий мёртвых. Он ищет помощника для древнего ритуала.", "icon": "👤"},
	"r15": {"name": "Лес шепчущих", "price": 130, "text": "Глубоко в лесу есть поляна, где деревья растут из человеческих костей. Там можно услышать голоса погибших.", "icon": "👤"}
}

# ----- СЛУХИ СТРАЖНИКА (ТОЛЬКО ЗОЛОТО) -----
var guard_rumors = {
	"g1": {"name": "Награда за банду", "price": 50, "text": "Лорд-командующий объявил награду в 1000 золотых за голову главаря банды 'Чёрные псы'.", "icon": "🛡️"},
	"g2": {"name": "Горный тролль", "price": 60, "text": "Любой, кто доставит голову горного тролля, получит земли и титул барона.", "icon": "🛡️"},
	"g3": {"name": "Пропавший патруль", "price": 55, "text": "Патрульные пропадают в восточном лесу. Последний дозорный успел прошептать: 'Они движутся под землёй'.", "icon": "🛡️"},
	"g4": {"name": "Караванная дорога", "price": 40, "text": "Купеческая гильдия нанимает охрану для каравана в столицу. Обещают 300 золотых.", "icon": "🛡️"},
	"g5": {"name": "Беглый маг", "price": 70, "text": "Из городской тюрьмы сбежал опасный маг. Награда за поимку — 500 золотых.", "icon": "🛡️"},
	"g6": {"name": "Контрабандисты", "price": 45, "text": "В порту орудует банда контрабандистов. Таможня ищет смельчаков для рейда на склад.", "icon": "🛡️"},
	"g7": {"name": "Странные огни", "price": 65, "text": "В подземельях старой крепости видели странные огни. Капитан стражи предлагает 200 золотых.", "icon": "🛡️"},
	"g8": {"name": "Бешеные волки", "price": 35, "text": "В северном лесу появились бешеные волки-мутанты. Награда за каждого — 50 золотых.", "icon": "🛡️"},
	"g9": {"name": "Похищение детей", "price": 80, "text": "В пригороде пропадают дети. Все улики ведут к старой мельнице.", "icon": "🛡️"},
	"g10": {"name": "Поддельные монеты", "price": 55, "text": "В городе появились фальшивые золотые. Награда 400 золотых за поимку фальшивомонетчиков.", "icon": "🛡️"},
	"g11": {"name": "Запретная книга", "price": 90, "text": "Из библиотеки украдена книга 'Некрономикон'. Награда 1000 золотых.", "icon": "🛡️"},
	"g12": {"name": "Чумной мор", "price": 75, "text": "В трущобах начался мор. Нужны смельчаки, чтобы доставить лекарства.", "icon": "🛡️"},
	"g13": {"name": "Побег из тюрьмы", "price": 85, "text": "Трое опасных преступников сбежали. Награда за каждого — 200 золотых.", "icon": "🛡️"},
	"g14": {"name": "Подземелье гильдии", "price": 95, "text": "Под штабом воровской гильдии есть секретный ход в королевскую казну.", "icon": "🛡️"},
	"g15": {"name": "Говорящий конь", "price": 100, "text": "Король ищет мудреца, который сможет перевести речь его говорящего коня.", "icon": "🛡️"}
}

# ----- СЛУХИ АВАНТЮРИСТА (ТОЛЬКО ЗОЛОТО) -----
var adventurer_rumors = {
	"a1": {"name": "Меч первого короля", "price": 200, "text": "Легендарный меч, разрубающий камень, в гробнице первого короля. Вход охраняют каменные големы.", "icon": "🧙"},
	"a2": {"name": "Клад пиратов", "price": 150, "text": "Клад пиратов Золотой Бороды в пустыне. Карта разделена на три части.", "icon": "🧙"},
	"a3": {"name": "Храм Времени", "price": 250, "text": "Древний храм, где можно увидеть прошлое и будущее, но путешественник стареет на 10 лет.", "icon": "🧙"},
	"a4": {"name": "Глаз дракона", "price": 300, "text": "Глаз дракона — артефакт, исполняющий желание. Хранится в гнезде последнего живого дракона.", "icon": "🧙"},
	"a5": {"name": "Остров духов", "price": 180, "text": "За туманами есть остров, где обитают духи предков. Нужно принести жертву.", "icon": "🧙"},
	"a6": {"name": "Амулет тьмы", "price": 220, "text": "Амулет, поглощающий души врагов, разбит на три осколка. Нужно собрать все.", "icon": "🧙"},
	"a7": {"name": "Летающий город", "price": 350, "text": "В небесах парит древний город атлантов. Там хранятся знания богов.", "icon": "🧙"},
	"a8": {"name": "Бессмертный воин", "price": 280, "text": "В горах живёт бессмертный воин, охраняющий врата в ад. Он научит любому оружию.", "icon": "🧙"},
	"a9": {"name": "Чаша Грааля", "price": 500, "text": "Чаша, дающая вечную жизнь, спрятана в замке, который появляется раз в сто лет.", "icon": "🧙"},
	"a10": {"name": "Ключ от всех дверей", "price": 180, "text": "Ключ, открывающий любую дверь, у старого отшельника на вершине горы.", "icon": "🧙"},
	"a11": {"name": "Зеркало истины", "price": 210, "text": "Зеркало, показывающее истинную сущность человека, в заброшенном монастыре.", "icon": "🧙"},
	"a12": {"name": "Книга мёртвых", "price": 400, "text": "Книга, воскрешающая любого, была уничтожена. Осталось три страницы.", "icon": "🧙"},
	"a13": {"name": "Камень судьбы", "price": 320, "text": "Камень, предсказывающий будущее, в храме на вершине вулкана.", "icon": "🧙"},
	"a14": {"name": "Печать древних", "price": 270, "text": "Печать, запечатывающая портал в мир демонов, ослабла. Нужно найти три кристалла.", "icon": "🧙"},
	"a15": {"name": "Венец власти", "price": 450, "text": "Венец, дающий власть над смертными, в гробнице первого императора.", "icon": "🧙"}
}

# ----- ПЕРЕМЕННЫЕ -----
var player_data = {}
var active_food_buff = null
var active_song_buff = null
var purchased_rumors = []

# ----- УЗЛЫ ИНТЕРФЕЙСА -----
var close_btn
var npc_buttons = {}
var content_panel
var npc_title_label
var avatar_label
var greeting_label
var items_list
var buff_status_label
var rumor_log_btn
var active_buffs_window = null
var rumor_log_window = null
var current_npc = "barman"
var buff_timer
var card_style

func _ready():
	build_ui()
	load_player_data()
	create_card_style()
	update_currency_display()
	update_buff_status()
	
	close_btn.pressed.connect(_on_close)
	rumor_log_btn.pressed.connect(_open_rumor_log)
	
	for npc in npc_buttons:
		npc_buttons[npc].pressed.connect(_on_npc_selected.bind(npc))
	
	buff_timer = Timer.new()
	buff_timer.wait_time = 1.0
	buff_timer.timeout.connect(_check_buff_expiry)
	add_child(buff_timer)
	buff_timer.start()
	
	_on_npc_selected("barman")
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

func create_card_style():
	card_style = StyleBoxFlat.new()
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
	title.text = "🍺 ТАВЕРНА 'ПЬЯНЫЙ ДРАКОН' 🎵"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 22)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var npc_panel = HBoxContainer.new()
	npc_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	npc_panel.add_theme_constant_override("separation", 15)
	main_vbox.add_child(npc_panel)
	
	var npcs = [
		{"id": "barman", "name": "🍺 БАРМЕН", "color": Color(1, 0.84, 0)},
		{"id": "bard", "name": "🎵 БАРД", "color": Color(0.5, 0.8, 1)},
		{"id": "stranger", "name": "👤 НЕЗНАКОМЕЦ", "color": Color(0.6, 0.3, 0.8)},
		{"id": "guard", "name": "🛡️ СТРАЖНИК", "color": Color(0.3, 0.7, 1)},
		{"id": "adventurer", "name": "🧙 АВАНТЮРИСТ", "color": Color(1, 0.7, 0.3)}
	]
	
	for npc in npcs:
		var btn = Button.new()
		btn.text = npc["name"]
		btn.custom_minimum_size = Vector2(140, 45)
		btn.add_theme_color_override("font_color", npc["color"])
		npc_panel.add_child(btn)
		npc_buttons[npc["id"]] = btn
	
	# Только золото
	var currency_row = HBoxContainer.new()
	currency_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(currency_row)
	
	var gold_display = Label.new()
	gold_display.name = "GoldDisplay"
	gold_display.text = "💰 0"
	gold_display.add_theme_color_override("font_color", Color(1, 0.84, 0))
	gold_display.add_theme_font_size_override("font_size", 18)
	currency_row.add_child(gold_display)
	
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
	
	avatar_label = Label.new()
	avatar_label.text = "🍺"
	avatar_label.horizontal_alignment = 1
	avatar_label.add_theme_font_size_override("font_size", 48)
	content_vbox.add_child(avatar_label)
	
	npc_title_label = Label.new()
	npc_title_label.text = "БАРМЕН"
	npc_title_label.horizontal_alignment = 1
	npc_title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	npc_title_label.add_theme_font_size_override("font_size", 20)
	content_vbox.add_child(npc_title_label)
	
	greeting_label = Label.new()
	greeting_label.text = "Добро пожаловать, путник!"
	greeting_label.horizontal_alignment = 1
	greeting_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	greeting_label.add_theme_font_size_override("font_size", 14)
	content_vbox.add_child(greeting_label)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1, 0.84, 0, 0.3)
	content_vbox.add_child(sep)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_vbox.add_child(scroll)
	
	items_list = VBoxContainer.new()
	items_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_list.add_theme_constant_override("separation", 8)
	scroll.add_child(items_list)
	
	var bottom_panel = HBoxContainer.new()
	bottom_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_panel.add_theme_constant_override("separation", 20)
	main_vbox.add_child(bottom_panel)
	
	var active_buffs_btn = Button.new()
	active_buffs_btn.text = "📋 АКТИВНЫЕ БАФЫ"
	active_buffs_btn.custom_minimum_size = Vector2(160, 30)
	active_buffs_btn.pressed.connect(_show_active_buffs)
	bottom_panel.add_child(active_buffs_btn)
	
	buff_status_label = Label.new()
	buff_status_label.text = "Нет активных бафов"
	buff_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	buff_status_label.add_theme_font_size_override("font_size", 12)
	buff_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_panel.add_child(buff_status_label)
	
	rumor_log_btn = Button.new()
	rumor_log_btn.text = "📖 ЖУРНАЛ СЛУХОВ"
	rumor_log_btn.custom_minimum_size = Vector2(160, 30)
	bottom_panel.add_child(rumor_log_btn)

func _show_active_buffs():
	if active_buffs_window and is_instance_valid(active_buffs_window):
		active_buffs_window.visible = true
		active_buffs_window.move_to_front()
		return
	
	active_buffs_window = Panel.new()
	active_buffs_window.name = "ActiveBuffsWindow"
	active_buffs_window.anchor_left = 0.25
	active_buffs_window.anchor_top = 0.25
	active_buffs_window.anchor_right = 0.75
	active_buffs_window.anchor_bottom = 0.75
	add_child(active_buffs_window)
	
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
	active_buffs_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.02
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.98
	active_buffs_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_row)
	
	var title = Label.new()
	title.text = "📋 АКТИВНЫЕ БАФЫ"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 20)
	title_row.add_child(title)
	
	var close_btn_local = Button.new()
	close_btn_local.text = "×"
	close_btn_local.custom_minimum_size = Vector2(35, 35)
	close_btn_local.pressed.connect(_close_active_buffs)
	title_row.add_child(close_btn_local)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)
	
	var buffs_list = VBoxContainer.new()
	buffs_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buffs_list.add_theme_constant_override("separation", 8)
	scroll.add_child(buffs_list)
	
	var current_time = Time.get_unix_time_from_system()
	var has_buffs = false
	
	if active_food_buff:
		var remaining = int(active_food_buff["expires_at"] - current_time)
		if remaining > 0:
			has_buffs = true
			var minutes = remaining / 60
			var seconds = remaining % 60
			var card = _create_buff_card(
				"🍽️ " + active_food_buff["name"],
				_get_buff_description(active_food_buff["type"], active_food_buff["value"]),
				"Осталось: " + str(minutes) + " мин " + str(seconds) + " сек"
			)
			buffs_list.add_child(card)
	
	if active_song_buff:
		var remaining = int(active_song_buff["expires_at"] - current_time)
		if remaining > 0:
			has_buffs = true
			var minutes = remaining / 60
			var seconds = remaining % 60
			var card = _create_buff_card(
				"🎵 " + active_song_buff["name"],
				_get_buff_description(active_song_buff["type"], active_song_buff["value"]),
				"Осталось: " + str(minutes) + " мин " + str(seconds) + " сек"
			)
			buffs_list.add_child(card)
	
	if not has_buffs:
		var empty_label = Label.new()
		empty_label.text = "Нет активных бафов.\n\nКупите еду у бармена или песню у барда!"
		empty_label.horizontal_alignment = 1
		empty_label.vertical_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 14)
		buffs_list.add_child(empty_label)

func _create_buff_card(card_title: String, description: String, time_text: String) -> Panel:
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
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = card_title
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)
	
	var desc_label = Label.new()
	desc_label.text = description
	desc_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	var time_label = Label.new()
	time_label.text = time_text
	time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	time_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(time_label)
	
	return card

func _get_buff_description(buff_type: String, value: int) -> String:
	match buff_type:
		"exp": return "⭐ +" + str(value) + "% к опыту"
		"max_hp": return "❤️ +" + str(value) + " к макс. здоровью"
		"strength": return "💪 +" + str(value) + " к атаке"
		"speed": return "⚡ +" + str(value) + "% к скорости"
		"defense": return "🛡️ +" + str(value) + "% к защите"
		"gold": return "💰 +" + str(value) + "% к золоту"
		"attack": return "⚔️ +" + str(value) + "% к атаке"
		"crit_chance": return "🎯 +" + str(value) + "% к шансу крита"
		"evasion": return "🌀 +" + str(value) + "% к уклонению"
		"regen": return "💚 +" + str(value) + " HP/сек регенерация"
		"berserk": return "🐉 +" + str(value) + "% к атаке"
		_: return "+" + str(value) + " к " + buff_type

func _close_active_buffs():
	if active_buffs_window and is_instance_valid(active_buffs_window):
		active_buffs_window.queue_free()
		active_buffs_window = null

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
	else:
		player_data = {
			"name": "Игрок",
			"gold": 1000,
			"inventory": []
		}
	
	if player_data.has("tavern_buffs"):
		active_food_buff = player_data["tavern_buffs"].get("active_food_buff", null)
		active_song_buff = player_data["tavern_buffs"].get("active_song_buff", null)
	
	if player_data.has("purchased_rumors"):
		purchased_rumors = player_data["purchased_rumors"]
	else:
		purchased_rumors = []
		player_data["purchased_rumors"] = purchased_rumors

func save_player_data():
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.emit(player_data)

func update_currency_display():
	var gold_display = find_child("GoldDisplay", true, false)
	if gold_display:
		gold_display.text = "💰 " + str(player_data.get("gold", 0))

func _on_npc_selected(npc_id: String):
	current_npc = npc_id
	
	for child in items_list.get_children():
		child.queue_free()
	
	match npc_id:
		"barman":
			avatar_label.text = "🍺"
			npc_title_label.text = "БАРМЕН"
			greeting_label.text = "Чего желаешь, путник? У меня лучшая еда в городе!"
			_fill_food_items()
		"bard":
			avatar_label.text = "🎵"
			npc_title_label.text = "БАРД"
			greeting_label.text = "Хочешь услышать песню? Мои мелодии вдохновляют на подвиги!"
			_fill_song_items()
		"stranger":
			avatar_label.text = "👤"
			npc_title_label.text = "НЕЗНАКОМЕЦ"
			greeting_label.text = "Псс... Хочешь узнать то, о чём не говорят вслух?"
			_fill_rumor_items(stranger_rumors)
		"guard":
			avatar_label.text = "🛡️"
			npc_title_label.text = "СТРАЖНИК"
			greeting_label.text = "Официально: есть несколько объявлений от городской стражи."
			_fill_rumor_items(guard_rumors)
		"adventurer":
			avatar_label.text = "🧙"
			npc_title_label.text = "СТАРЫЙ АВАНТЮРИСТ"
			greeting_label.text = "Молодой человек, хотите услышать легенды из моих странствий?"
			_fill_rumor_items(adventurer_rumors)
	
	for npc in npc_buttons:
		if npc == npc_id:
			npc_buttons[npc].modulate = Color(1, 1, 1)
		else:
			npc_buttons[npc].modulate = Color(0.6, 0.6, 0.6)

func _fill_food_items():
	for id in food_db:
		var item = food_db[id]
		var card = _create_item_card(
			item["icon"], 
			item["name"], 
			item["description"],
			"💰 " + str(item["price_gold"]),
			"+" + str(item["buff_value"]) + _get_buff_name(item["buff_type"]),
			"Длительность: 30 мин"
		)
		var card_hbox = card.get_child(0).get_child(0) if card.get_child_count() > 0 else null
		if card_hbox:
			var buy_btn = card_hbox.get_child(card_hbox.get_child_count() - 1)
			buy_btn.text = "КУПИТЬ"
			buy_btn.pressed.connect(_buy_food.bind(id))
		items_list.add_child(card)

func _fill_song_items():
	for id in songs_db:
		var item = songs_db[id]
		var card = _create_item_card(
			item["icon"], 
			item["name"], 
			item["description"],
			"💰 " + str(item["price_gold"]),
			"+" + str(item["buff_value"]) + _get_buff_name(item["buff_type"]),
			"Длительность: 60 мин"
		)
		var card_hbox = card.get_child(0).get_child(0) if card.get_child_count() > 0 else null
		if card_hbox:
			var buy_btn = card_hbox.get_child(card_hbox.get_child_count() - 1)
			buy_btn.text = "СЛУШАТЬ"
			buy_btn.pressed.connect(_buy_song.bind(id))
		items_list.add_child(card)

func _fill_rumor_items(rumors_dict: Dictionary):
	for id in rumors_dict:
		var rumor = rumors_dict[id]
		var is_purchased = id in purchased_rumors
		
		var card = _create_item_card(
			rumor["icon"], 
			rumor["name"], 
			rumor["text"],
			"💰 " + str(rumor["price"]),
			"",
			""
		)
		var card_hbox = card.get_child(0).get_child(0) if card.get_child_count() > 0 else null
		if card_hbox:
			var buy_btn = card_hbox.get_child(card_hbox.get_child_count() - 1)
			if is_purchased:
				buy_btn.text = "ПРОЧИТАНО"
				buy_btn.disabled = true
				buy_btn.modulate = Color(0.5, 0.5, 0.5)
			else:
				buy_btn.text = "КУПИТЬ"
				buy_btn.pressed.connect(_buy_rumor.bind(id, rumor))
		
		items_list.add_child(card)

func _create_item_card(icon: String, item_name: String, desc: String, price_text: String, bonus_text: String, time_text: String) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 90
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
	icon_label.text = icon
	icon_label.custom_minimum_size = Vector2(50, 50)
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.horizontal_alignment = 1
	icon_label.vertical_alignment = 1
	hbox.add_child(icon_label)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 15)
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = desc
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_vbox.add_child(desc_label)
	
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 15)
	info_vbox.add_child(bottom_row)
	
	var price_label = Label.new()
	price_label.text = price_text
	price_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	price_label.add_theme_font_size_override("font_size", 12)
	bottom_row.add_child(price_label)
	
	if bonus_text != "":
		var bonus_label = Label.new()
		bonus_label.text = bonus_text
		bonus_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		bonus_label.add_theme_font_size_override("font_size", 12)
		bottom_row.add_child(bonus_label)
	
	if time_text != "":
		var time_label = Label.new()
		time_label.text = time_text
		time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		time_label.add_theme_font_size_override("font_size", 11)
		bottom_row.add_child(time_label)
	
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(100, 35)
	buy_btn.text = "КУПИТЬ"
	hbox.add_child(buy_btn)
	
	return card

func _buy_food(item_id: String):
	var item = food_db[item_id]
	var price = item["price_gold"]
	
	if player_data.get("gold", 0) < price:
		_show_message("Не хватает золота!")
		return
	
	player_data["gold"] -= price
	
	active_food_buff = {
		"type": item["buff_type"],
		"value": item["buff_value"],
		"expires_at": Time.get_unix_time_from_system() + item["duration"],
		"name": item["name"]
	}
	
	if not player_data.has("tavern_buffs"):
		player_data["tavern_buffs"] = {}
	player_data["tavern_buffs"]["active_food_buff"] = active_food_buff
	player_data["tavern_buffs"]["active_song_buff"] = active_song_buff
	
	save_player_data()
	update_currency_display()
	update_buff_status()
	_show_message("Вы съели " + item["name"] + "! " + _get_buff_description(item["buff_type"], item["buff_value"]))

func _buy_song(song_id: String):
	var song = songs_db[song_id]
	var price = song["price_gold"]
	
	if player_data.get("gold", 0) < price:
		_show_message("Не хватает золота!")
		return
	
	player_data["gold"] -= price
	
	active_song_buff = {
		"type": song["buff_type"],
		"value": song["buff_value"],
		"expires_at": Time.get_unix_time_from_system() + song["duration"],
		"name": song["name"]
	}
	
	if not player_data.has("tavern_buffs"):
		player_data["tavern_buffs"] = {}
	player_data["tavern_buffs"]["active_food_buff"] = active_food_buff
	player_data["tavern_buffs"]["active_song_buff"] = active_song_buff
	
	save_player_data()
	update_currency_display()
	update_buff_status()
	_show_message("Бард исполнил " + song["name"] + "! " + _get_buff_description(song["buff_type"], song["buff_value"]))

func _buy_rumor(rumor_id: String, rumor: Dictionary):
	var price = rumor["price"]
	
	if player_data.get("gold", 0) < price:
		_show_message("Не хватает золота!")
		return
	
	player_data["gold"] -= price
	
	purchased_rumors.append(rumor_id)
	player_data["purchased_rumors"] = purchased_rumors
	
	save_player_data()
	update_currency_display()
	_show_rumor_text(rumor["name"], rumor["text"])
	
	_on_npc_selected(current_npc)

func _show_rumor_text(title: String, text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "📖 " + title
	dialog.dialog_text = text
	dialog.add_theme_font_size_override("font_size", 14)
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _show_message(msg_text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Таверна"
	dialog.dialog_text = msg_text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _get_buff_name(buff_type: String) -> String:
	match buff_type:
		"exp": return "⭐ к опыту"
		"max_hp": return "❤️ к HP"
		"strength": return "💪 к силе"
		"speed": return "⚡ к скорости"
		"defense": return "🛡️ к защите"
		"gold": return "💰 к золоту"
		"attack": return "⚔️ к атаке"
		"crit_chance": return "🎯 к шансу крита"
		"evasion": return "🌀 к уклонению"
		"regen": return "💚 к регенерации"
		"berserk": return "🐉 к атаке"
		_: return " к " + buff_type

func update_buff_status():
	var buff_texts = []
	var current_time = Time.get_unix_time_from_system()
	
	if active_food_buff:
		var remaining = int(active_food_buff["expires_at"] - current_time)
		if remaining > 0:
			var minutes = remaining / 60
			var seconds = remaining % 60
			buff_texts.append("🍽️ " + active_food_buff["name"] + " (" + str(minutes) + ":" + str(seconds).pad_zeros(2) + ")")
		else:
			active_food_buff = null
			if player_data.has("tavern_buffs"):
				player_data["tavern_buffs"]["active_food_buff"] = null
			save_player_data()
	
	if active_song_buff:
		var remaining = int(active_song_buff["expires_at"] - current_time)
		if remaining > 0:
			var minutes = remaining / 60
			var seconds = remaining % 60
			buff_texts.append("🎵 " + active_song_buff["name"] + " (" + str(minutes) + ":" + str(seconds).pad_zeros(2) + ")")
		else:
			active_song_buff = null
			if player_data.has("tavern_buffs"):
				player_data["tavern_buffs"]["active_song_buff"] = null
			save_player_data()
	
	if buff_texts.size() > 0:
		buff_status_label.text = "Активные бафы: " + " | ".join(buff_texts)
	else:
		buff_status_label.text = "Нет активных бафов"

func _check_buff_expiry():
	var changed = false
	var current_time = Time.get_unix_time_from_system()
	
	if active_food_buff and current_time >= active_food_buff["expires_at"]:
		active_food_buff = null
		changed = true
	
	if active_song_buff and current_time >= active_song_buff["expires_at"]:
		active_song_buff = null
		changed = true
	
	if changed:
		if not player_data.has("tavern_buffs"):
			player_data["tavern_buffs"] = {}
		player_data["tavern_buffs"]["active_food_buff"] = active_food_buff
		player_data["tavern_buffs"]["active_song_buff"] = active_song_buff
		save_player_data()
		update_buff_status()

func _open_rumor_log():
	if rumor_log_window and is_instance_valid(rumor_log_window):
		rumor_log_window.visible = true
		rumor_log_window.move_to_front()
		return
	
	rumor_log_window = Panel.new()
	rumor_log_window.name = "RumorLogWindow"
	rumor_log_window.anchor_left = 0.15
	rumor_log_window.anchor_top = 0.1
	rumor_log_window.anchor_right = 0.85
	rumor_log_window.anchor_bottom = 0.9
	add_child(rumor_log_window)
	
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
	rumor_log_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.02
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.98
	rumor_log_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title_row = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_row)
	
	var log_title = Label.new()
	log_title.text = "📖 МОИ СЛУХИ"
	log_title.horizontal_alignment = 1
	log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	log_title.add_theme_font_size_override("font_size", 20)
	title_row.add_child(log_title)
	
	var close_log_btn = Button.new()
	close_log_btn.text = "×"
	close_log_btn.custom_minimum_size = Vector2(35, 35)
	close_log_btn.pressed.connect(_close_rumor_log)
	title_row.add_child(close_log_btn)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)
	
	var rumors_list = VBoxContainer.new()
	rumors_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rumors_list.add_theme_constant_override("separation", 8)
	scroll.add_child(rumors_list)
	
	var all_rumors = {}
	for id in stranger_rumors:
		all_rumors[id] = {"data": stranger_rumors[id]}
	for id in guard_rumors:
		all_rumors[id] = {"data": guard_rumors[id]}
	for id in adventurer_rumors:
		all_rumors[id] = {"data": adventurer_rumors[id]}
	
	if purchased_rumors.size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Вы ещё не купили ни одного слуха."
		empty_label.horizontal_alignment = 1
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_label.add_theme_font_size_override("font_size", 14)
		rumors_list.add_child(empty_label)
	else:
		for rumor_id in purchased_rumors:
			if all_rumors.has(rumor_id):
				var rumor = all_rumors[rumor_id]["data"]
				var card = _create_rumor_log_card(rumor["name"], rumor["text"], rumor["icon"])
				rumors_list.add_child(card)

func _create_rumor_log_card(name: String, text: String, icon: String) -> Panel:
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
	
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.custom_minimum_size = Vector2(45, 45)
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.horizontal_alignment = 1
	icon_label.vertical_alignment = 1
	hbox.add_child(icon_label)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = name
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)
	
	var text_label = Label.new()
	text_label.text = text
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 11)
	text_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(text_label)
	
	return card

func _close_rumor_log():
	if rumor_log_window and is_instance_valid(rumor_log_window):
		rumor_log_window.queue_free()
		rumor_log_window = null

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	purchased_rumors = player_data.get("purchased_rumors", [])
	
	if player_data.has("tavern_buffs"):
		active_food_buff = player_data["tavern_buffs"].get("active_food_buff", null)
		active_song_buff = player_data["tavern_buffs"].get("active_song_buff", null)
	
	update_currency_display()
	update_buff_status()
	_on_npc_selected(current_npc)

func _on_close():
	queue_free()
