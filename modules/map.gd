# res://modules/map.gd
extends Panel

var close_btn
var map_container
var map_texture_rect
var location_markers = {}
var current_location_popup = null
var edit_mode = false

var player_data = {}
var purchased_rumors = []

var marker_colors = {
	"tower": Color(0.6, 0.3, 0.8),
	"forest": Color(0.2, 0.7, 0.3),
	"city": Color(1, 0.84, 0),
	"volcano": Color(1, 0.4, 0),
	"mountains": Color(0.4, 0.6, 1),
	"mansion": Color(0.8, 0.3, 0.5),
	"crypt": Color(0.5, 0.5, 0.5),
	"ruins": Color(0.8, 0.7, 0.3),
	"castle": Color(1, 0.2, 0.2)
}

var locations = {
	"tower": {
		"name": "БАШНЯ МАГА",
		"icon": "🧙",
		"x": 0.30202944713932, "y": 0.18962541345048,
		"desc": "Высокая башня, где живёт могущественный маг.",
		"enemies": [
			{"name": "Магический страж", "level": 20, "damage": "70-100", "icon": "🗡️", "drops": "Магический свиток", "mob_id": "golem"},
			{"name": "Вызванный демон", "level": 25, "damage": "80-120", "icon": "😈", "drops": "Демонический артефакт", "mob_id": "demon"},
			{"name": "Безумный маг", "level": 22, "damage": "75-110", "icon": "🧙", "drops": "Магический свиток", "mob_id": "ghost"}
		],
		"quests": ["Сердце демона", "Магический свиток"],
		"rumor": "На верхнем этаже хранится Книга Мертвых."
	},
	"forest": {
		"name": "ТЁМНЫЙ ЛЕС",
		"icon": "🌲",
		"x": 0.43908601963205, "y": 0.51293224177948,
		"desc": "Дремучий лес, где солнце едва пробивается сквозь кроны.",
		"enemies": [
			{"name": "Лесной волк", "level": 3, "damage": "20-35", "icon": "🐺", "drops": "Волчья шкура", "mob_id": "wolf"},
			{"name": "Дикий кабан", "level": 4, "damage": "25-40", "icon": "🐗", "drops": "Клык кабана", "mob_id": "orc"},
			{"name": "Лесной паук", "level": 5, "damage": "30-45", "icon": "🕷️", "drops": "Паутина", "mob_id": "rat"}
		],
		"quests": ["Охота на волков", "Волчьи шкуры"],
		"rumor": "По ночам на поляне собираются ведьмы."
	},
	"city": {
		"name": "ГОРОД",
		"icon": "🏰",
		"x": 0.59858453269976, "y": 0.67961486398357,
		"desc": "Столица королевства Эвория.",
		"enemies": [
			{"name": "Крысолюд", "level": 1, "damage": "10-20", "icon": "🐀", "drops": "Крысиный хвост", "mob_id": "rat"},
			{"name": "Гоблин-разбойник", "level": 2, "damage": "15-30", "icon": "👤", "drops": "Монеты", "mob_id": "orc"},
			{"name": "Бродячий пёс", "level": 1, "damage": "8-15", "icon": "🐕", "drops": "Шкура", "mob_id": "wolf"}
		],
		"quests": ["Крысиная угроза", "Трофеи Крысы"],
		"rumor": "Под городом есть древние катакомбы."
	},
	"volcano": {
		"name": "ОГНЕННАЯ ГОРА",
		"icon": "🔥",
		"x": 0.7476637087722, "y": 0.22267459190055,
		"desc": "Действующий вулкан, потоки лавы и пепла.",
		"enemies": [
			{"name": "Огненный саламандер", "level": 30, "damage": "100-150", "icon": "🦎", "drops": "Огненный самоцвет", "mob_id": "dragon"},
			{"name": "Лавовый голем", "level": 35, "damage": "120-180", "icon": "🗿", "drops": "Вулканическое стекло", "mob_id": "golem"},
			{"name": "Огненный дракончик", "level": 40, "damage": "150-200", "icon": "🐉", "drops": "Драконья чешуя", "mob_id": "dragon"}
		],
		"quests": ["Чешуя дракона", "Охотник на драконов"],
		"rumor": "В сердце вулкана спит Великий Дракон."
	},
	"mountains": {
		"name": "ГОРНЫЙ ПЕРЕВАЛ",
		"icon": "🏔️",
		"x": 0.52244199890739, "y": 0.24422838916517,
		"desc": "Опасный перевал, холодный ветер, скользкие тропы.",
		"enemies": [
			{"name": "Горный тролль", "level": 10, "damage": "50-80", "icon": "👹", "drops": "Зуб тролля", "mob_id": "troll"},
			{"name": "Снежный барс", "level": 8, "damage": "40-60", "icon": "🐆", "drops": "Мех барса", "mob_id": "wolf"},
			{"name": "Каменный голем", "level": 12, "damage": "60-90", "icon": "🗿", "drops": "Кристаллы", "mob_id": "golem"}
		],
		"quests": ["Охотник на троллей", "Зубы тролля"],
		"rumor": "На высокой горе есть древний храм."
	},
	"mansion": {
		"name": "ЗАБРОШЕННЫЙ ОСОБНЯК",
		"icon": "🏚️",
		"x": 0.28119042315427, "y": 0.44252319858499,
		"desc": "Старый особняк на холме.",
		"enemies": [
			{"name": "Призрак", "level": 15, "damage": "50-70", "icon": "👻", "drops": "Призрачная эссенция", "mob_id": "ghost"},
			{"name": "Летучая мышь", "level": 12, "damage": "40-60", "icon": "🦇", "drops": "Крыло", "mob_id": "rat"},
			{"name": "Призрачная крыса", "level": 10, "damage": "30-50", "icon": "🐀", "drops": "Старинная монета", "mob_id": "rat"}
		],
		"quests": ["Призрачная угроза", "Призрачная эссенция"],
		"rumor": "В подвале спрятано проклятое зеркало."
	},
	"crypt": {
		"name": "СКЛЕП",
		"icon": "🕯️",
		"x": 0.74365615480149, "y": 0.86785125732422,
		"desc": "Древнее захоронение рыцарей и королей.",
		"enemies": [
			{"name": "Скелет", "level": 5, "damage": "25-40", "icon": "💀", "drops": "Кость", "mob_id": "skeleton"},
			{"name": "Зомби", "level": 7, "damage": "30-50", "icon": "🧟", "drops": "Гнилая плоть", "mob_id": "skeleton"},
			{"name": "Скелет-рыцарь", "level": 10, "damage": "45-65", "icon": "⚔️", "drops": "Древний свиток", "mob_id": "skeleton"}
		],
		"quests": ["Истребление нежити", "Кости скелетов"],
		"rumor": "В глубине склепа похоронен великий король."
	},
	"ruins": {
		"name": "ДРЕВНИЕ РУИНЫ",
		"icon": "🏛️",
		"x": 0.74606061718501, "y": 0.47988306332941,
		"desc": "Останки древней цивилизации.",
		"enemies": [
			{"name": "Каменный голем", "level": 25, "damage": "80-120", "icon": "🗿", "drops": "Ядро голема", "mob_id": "golem"},
			{"name": "Магический конструкт", "level": 28, "damage": "90-130", "icon": "🤖", "drops": "Магический кристалл", "mob_id": "golem"},
			{"name": "Дух-хранитель", "level": 30, "damage": "100-140", "icon": "👻", "drops": "Древний артефакт", "mob_id": "ghost"}
		],
		"quests": ["Ядро голема", "Древний артефакт"],
		"rumor": "Под руинами находится подземный храм."
	},
	"castle": {
		"name": "ЗАМОК",
		"icon": "👑",
		"x": 0.88231570221657, "y": 0.65806109284701,
		"desc": "Величественный замок королевской семьи.",
		"enemies": [
			{"name": "Королевский страж", "level": 15, "damage": "60-90", "icon": "🛡️", "drops": "Королевская монета", "mob_id": "orc"},
			{"name": "Теневой убийца", "level": 18, "damage": "65-95", "icon": "🗡️", "drops": "Магическое кольцо", "mob_id": "ghost"},
			{"name": "Придворный маг", "level": 20, "damage": "70-100", "icon": "🔮", "drops": "Драгоценность", "mob_id": "demon"}
		],
		"quests": ["Сердце демона", "Защита замка"],
		"rumor": "В подземельях замка хранится чёрный дракон."
	}
}

func _ready():
	build_ui()
	load_player_data()
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	create_location_markers()
	
	close_btn.pressed.connect(_on_close)
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

func build_ui():
	anchor_left = 0.02
	anchor_top = 0.02
	anchor_right = 0.98
	anchor_bottom = 0.98
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.05, 0.95)
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
	main_vbox.anchor_left = 0.01
	main_vbox.anchor_top = 0.01
	main_vbox.anchor_right = 0.99
	main_vbox.anchor_bottom = 0.99
	main_vbox.add_theme_constant_override("separation", 8)
	add_child(main_vbox)
	
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "🗺️ КАРТА МИРА 🗺️"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	map_container = Control.new()
	map_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_container.clip_contents = false
	main_vbox.add_child(map_container)
	
	map_texture_rect = TextureRect.new()
	map_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var paths = [
		"res://assets/images/map.png",
		"res://assets/images/map.jpg",
		"res://assets/images/1780405503871.jpg"
	]
	
	var map_texture = null
	for path in paths:
		map_texture = load(path)
		if map_texture:
			print("✅ Карта загружена: ", path)
			break
	
	if map_texture:
		map_texture_rect.texture = map_texture
	else:
		print("❌ Карта не найдена!")
		var fallback = Label.new()
		fallback.text = "⚠️ КАРТА НЕ ЗАГРУЖЕНА ⚠️"
		map_container.add_child(fallback)
		return
	
	map_container.add_child(map_texture_rect)
	
	var bottom_info = Label.new()
	bottom_info.text = "🔴 Нажми на цветную метку, чтобы узнать о локации"
	bottom_info.horizontal_alignment = 1
	bottom_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	bottom_info.add_theme_font_size_override("font_size", 12)
	main_vbox.add_child(bottom_info)

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
		purchased_rumors = player_data.get("purchased_rumors", [])
	else:
		player_data = {"name": "Игрок", "level": 1, "gold": 1000}
		purchased_rumors = []

func create_location_markers():
	if not map_texture_rect or not map_texture_rect.texture:
		print("❌ Нет текстуры карты")
		return
	
	for marker in location_markers.values():
		if is_instance_valid(marker):
			marker.queue_free()
	location_markers.clear()
	
	map_texture_rect.set_size(map_container.get_size())
	await get_tree().process_frame
	
	var tex_size = map_texture_rect.texture.get_size()
	var rect_size = map_texture_rect.get_size()
	
	if rect_size.x <= 0 or rect_size.y <= 0:
		rect_size = map_container.get_size()
		map_texture_rect.set_size(rect_size)
	
	var scale_x = rect_size.x / tex_size.x
	var scale_y = rect_size.y / tex_size.y
	var scale = min(scale_x, scale_y)
	
	var scaled_width = tex_size.x * scale
	var scaled_height = tex_size.y * scale
	var offset_x = (rect_size.x - scaled_width) / 2
	var offset_y = (rect_size.y - scaled_height) / 2
	
	for loc_id in locations:
		var loc = locations[loc_id]
		var marker_color = marker_colors.get(loc_id, Color(1, 0, 0))
		
		var marker = Panel.new()
		marker.name = loc_id
		marker.custom_minimum_size = Vector2(30, 30)
		
		var style = StyleBoxFlat.new()
		style.bg_color = marker_color
		style.border_color = Color(1, 1, 1, 0.8)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 15
		style.corner_radius_top_right = 15
		style.corner_radius_bottom_left = 15
		style.corner_radius_bottom_right = 15
		marker.add_theme_stylebox_override("panel", style)
		
		var short_name = Label.new()
		short_name.text = loc["name"][0]
		short_name.horizontal_alignment = 1
		short_name.vertical_alignment = 1
		short_name.add_theme_color_override("font_color", Color(1, 1, 1))
		short_name.add_theme_font_size_override("font_size", 14)
		marker.add_child(short_name)
		
		var btn = Button.new()
		btn.text = ""
		btn.tooltip_text = loc["name"]
		btn.custom_minimum_size = Vector2(30, 30)
		btn.pressed.connect(_open_location_detail.bind(loc_id))
		
		var transparent_style = StyleBoxFlat.new()
		transparent_style.bg_color = Color(0, 0, 0, 0)
		transparent_style.border_width_left = 0
		transparent_style.border_width_right = 0
		transparent_style.border_width_top = 0
		transparent_style.border_width_bottom = 0
		btn.add_theme_stylebox_override("normal", transparent_style)
		btn.add_theme_stylebox_override("hover", transparent_style)
		btn.add_theme_stylebox_override("pressed", transparent_style)
		
		marker.add_child(btn)
		
		var marker_x = offset_x + (tex_size.x * scale * loc["x"]) - 15
		var marker_y = offset_y + (tex_size.y * scale * loc["y"]) - 15
		
		marker.position = Vector2(marker_x, marker_y)
		map_container.add_child(marker)
		location_markers[loc_id] = marker
		
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(marker, "scale", Vector2(1.15, 1.15), 0.5)
		tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.5)

func _open_location_detail(loc_id: String):
	var loc = locations[loc_id]
	
	if current_location_popup and is_instance_valid(current_location_popup):
		current_location_popup.queue_free()
	
	current_location_popup = Panel.new()
	current_location_popup.anchor_left = 0.18
	current_location_popup.anchor_top = 0.1
	current_location_popup.anchor_right = 0.82
	current_location_popup.anchor_bottom = 0.9
	add_child(current_location_popup)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.04, 0.98)
	style.border_color = Color(0.6, 0.4, 0.2, 0.8)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	current_location_popup.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.03
	margin.anchor_top = 0.03
	margin.anchor_right = 0.97
	margin.anchor_bottom = 0.97
	current_location_popup.add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(vbox)
	
	var icon_label = Label.new()
	icon_label.text = loc.get("icon", "📍")
	icon_label.horizontal_alignment = 1
	icon_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(icon_label)
	
	var title_label = Label.new()
	title_label.text = loc["name"]
	title_label.horizontal_alignment = 1
	title_label.add_theme_color_override("font_color", marker_colors.get(loc_id, Color(1, 0.84, 0)))
	title_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title_label)
	
	var sep = HSeparator.new()
	sep.modulate = Color(0.6, 0.4, 0.2, 0.5)
	vbox.add_child(sep)
	
	var desc_label = Label.new()
	desc_label.text = loc["desc"]
	desc_label.horizontal_alignment = 1
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	vbox.add_child(desc_label)
	
	# Отображение уровня врагов
	var min_level = 999
	var max_level = 0
	for enemy in loc["enemies"]:
		if enemy["level"] < min_level:
			min_level = enemy["level"]
		if enemy["level"] > max_level:
			max_level = enemy["level"]
	
	var level_range_label = Label.new()
	level_range_label.text = "📊 Уровень врагов: " + str(min_level) + " - " + str(max_level)
	level_range_label.horizontal_alignment = 1
	level_range_label.add_theme_font_size_override("font_size", 12)
	
	var player_lvl = player_data.get("level", 1)
	if player_lvl < min_level:
		level_range_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		level_range_label.text += " ⚠️ СЛИШКОМ ОПАСНО!"
	else:
		level_range_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	
	vbox.add_child(level_range_label)
	
	var enemies_label = Label.new()
	enemies_label.text = "⚔️ ВРАГИ"
	enemies_label.horizontal_alignment = 1
	enemies_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	enemies_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(enemies_label)
	
	for enemy in loc["enemies"]:
		var enemy_text = enemy["icon"] + " " + enemy["name"] + " (Ур." + str(enemy["level"]) + ") — " + enemy["damage"] + " урона"
		var enemy_label = Label.new()
		enemy_label.text = enemy_text
		enemy_label.horizontal_alignment = 1
		enemy_label.add_theme_font_size_override("font_size", 13)
		enemy_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
		vbox.add_child(enemy_label)
		
		var drop_text = "  🎁 " + enemy["drops"]
		var drop_label = Label.new()
		drop_label.text = drop_text
		drop_label.horizontal_alignment = 1
		drop_label.add_theme_font_size_override("font_size", 12)
		drop_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		vbox.add_child(drop_label)
	
	var quests_label = Label.new()
	quests_label.text = "📋 ЗАДАНИЯ"
	quests_label.horizontal_alignment = 1
	quests_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	quests_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(quests_label)
	
	for quest in loc["quests"]:
		var quest_label = Label.new()
		quest_label.text = "📌 " + quest
		quest_label.horizontal_alignment = 1
		quest_label.add_theme_font_size_override("font_size", 13)
		quest_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		vbox.add_child(quest_label)
	
	var rumor_label = Label.new()
	rumor_label.text = "💬 СЛУХ"
	rumor_label.horizontal_alignment = 1
	rumor_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	rumor_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(rumor_label)
	
	var rumor_text = Label.new()
	rumor_text.text = "🔮 " + loc["rumor"]
	rumor_text.horizontal_alignment = 1
	rumor_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor_text.add_theme_font_size_override("font_size", 13)
	rumor_text.add_theme_color_override("font_color", Color(0.7, 0.8, 1))
	vbox.add_child(rumor_text)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(btn_hbox)
	
	var fight_btn = Button.new()
	fight_btn.text = "⚔️ В БОЙ"
	fight_btn.custom_minimum_size = Vector2(110, 40)
	fight_btn.add_theme_font_size_override("font_size", 14)
	
	if player_lvl >= min_level:
		fight_btn.pressed.connect(_on_fight_location.bind(loc_id))
	else:
		fight_btn.disabled = true
		fight_btn.text = "⚔️ НУЖЕН УР. " + str(min_level)
		fight_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	
	btn_hbox.add_child(fight_btn)
	
	var explore_btn = Button.new()
	explore_btn.text = "🔍 ИССЛЕДОВАТЬ"
	explore_btn.custom_minimum_size = Vector2(130, 40)
	explore_btn.add_theme_font_size_override("font_size", 14)
	explore_btn.pressed.connect(_on_explore_location.bind(loc_id))
	btn_hbox.add_child(explore_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "❌ ЗАКРЫТЬ"
	cancel_btn.custom_minimum_size = Vector2(110, 40)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.pressed.connect(_close_location_detail)
	btn_hbox.add_child(cancel_btn)

func _get_mob_id_by_name(mob_name: String) -> String:
	var mobs = {
		"Лесной волк": "wolf",
		"Скелет": "skeleton",
		"Горный тролль": "troll",
		"Древний дракон": "dragon",
		"Крыса": "rat",
		"Крысолюд": "rat",
		"Гоблин-разбойник": "orc",
		"Орк": "orc",
		"Призрак": "ghost",
		"Каменный голем": "golem",
		"Демон": "demon",
		"Магический страж": "golem",
		"Вызванный демон": "demon",
		"Безумный маг": "ghost",
		"Дикий кабан": "orc",
		"Лесной паук": "rat",
		"Огненный саламандер": "dragon",
		"Лавовый голем": "golem",
		"Огненный дракончик": "dragon",
		"Снежный барс": "wolf",
		"Летучая мышь": "rat",
		"Призрачная крыса": "rat",
		"Зомби": "skeleton",
		"Скелет-рыцарь": "skeleton",
		"Магический конструкт": "golem",
		"Дух-хранитель": "ghost",
		"Королевский страж": "orc",
		"Теневой убийца": "ghost",
		"Придворный маг": "demon"
	}
	return mobs.get(mob_name, "wolf")

func _extract_damage_value(damage_str: String) -> int:
	var parts = damage_str.split("-")
	if parts.size() >= 2:
		return (int(parts[0]) + int(parts[1])) / 2
	return 30

func _on_fight_location(loc_id: String):
	var loc = locations[loc_id]
	
	var enemies = loc["enemies"]
	if enemies.size() == 0:
		_show_message("В этой локации нет врагов!")
		return
	
	var random_enemy = enemies[randi() % enemies.size()]
	var mob_id = _get_mob_id_by_name(random_enemy["name"])
	
	var battle_data = {
		"hp": random_enemy.get("level", 1) * 20,
		"max_hp": random_enemy.get("level", 1) * 20,
		"attack": _extract_damage_value(random_enemy["damage"]),
		"defense": random_enemy.get("level", 1) * 3,
		"level": random_enemy["level"],
		"name": random_enemy["name"],
		"icon": random_enemy["icon"],
		"mob_id": mob_id,
		"gold_min": random_enemy.get("level", 1) * 5,
		"gold_max": random_enemy.get("level", 1) * 15,
		"exp_min": random_enemy.get("level", 1) * 10,
		"exp_max": random_enemy.get("level", 1) * 25,
		"ai_pattern": "aggressive"
	}
	
	# Закрываем только окно с деталями
	_close_location_detail()
	
	print("🚀 Запуск боя в локации: ", loc_id, " против ", random_enemy["name"])
	
	var battle = load("res://modules/battle_system.gd").new()
	add_child(battle)
	battle.start_battle(battle_data, battle.BattleType.PVE, {
		"source": "map",
		"location_id": loc_id,
		"enemy_name": random_enemy["name"]
	})

func _on_explore_location(loc_id: String):
	var loc = locations[loc_id]
	var enemies = loc["enemies"]
	
	if enemies.size() == 0:
		_show_message("Вы исследуете окрестности, но никого не находите.")
		return
	
	if randi() % 100 < 70:
		var random_enemy = enemies[randi() % enemies.size()]
		_show_message("🔍 Вы нашли " + random_enemy["name"] + "! Начинается бой!")
		_on_fight_location(loc_id)
	else:
		var possible_items = ["монету", "траву", "камень", "старую карту", "пузырёк"]
		var found_item = possible_items[randi() % possible_items.size()]
		var gold_found = randi() % 20 + 5
		
		player_data["gold"] = player_data.get("gold", 0) + gold_found
		if NetworkManager:
			NetworkManager.player_data = player_data
			NetworkManager.save_local_data()
			if NetworkManager.has_signal("player_data_updated"):
				NetworkManager.player_data_updated.emit(player_data)
		
		_show_message("🔍 Вы нашли " + found_item + " и " + str(gold_found) + " золота!")

func _close_location_detail():
	if current_location_popup and is_instance_valid(current_location_popup):
		current_location_popup.queue_free()
		current_location_popup = null

func _show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Карта"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered.call_deferred()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	purchased_rumors = player_data.get("purchased_rumors", [])

func _on_close():
	if current_location_popup:
		current_location_popup.queue_free()
	queue_free()
