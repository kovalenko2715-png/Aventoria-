extends Panel

var player_data = {}
var stat_points = 15

# Ссылки на узлы
var close_btn
var level_label
var hp_label
var mana_label
var stat_points_label

# Характеристики
var stat_strength
var stat_agility
var stat_intuition
var stat_endurance
var stat_intellect
var stat_wisdom
var stat_spirit

# Кнопки +
var btn_strength
var btn_agility
var btn_intuition
var btn_endurance
var btn_intellect
var btn_wisdom
var btn_spirit

# Пассивные статы
var passive_attack
var passive_defense
var passive_hp
var passive_mana
var passive_crit_chance
var passive_crit_damage
var passive_evasion
var passive_magic_find

# Стихии
var element_fire
var element_water
var element_earth
var element_air
var element_light
var element_dark

# Информация аккаунта
var info_nick
var info_gender
var info_element
var info_title
var info_guild
var info_guild_emblem

# Статистика
var stat_pvp_wins
var stat_monsters
var stat_earned
var stat_bosses

# Бафы из таверны
var active_buffs_label = null
var buffs_timer = null

func _ready():
	build_ui()
	
	if NetworkManager:
		NetworkManager.data_received.connect(_on_network_data)
		NetworkManager.player_data_updated.connect(_on_player_data_updated)
	
	load_player_data()
	update_ui()
	setup_buffs_display()
	
	close_btn.pressed.connect(_on_close)
	btn_strength.pressed.connect(_on_strength_plus)
	btn_agility.pressed.connect(_on_agility_plus)
	btn_intuition.pressed.connect(_on_intuition_plus)
	btn_endurance.pressed.connect(_on_endurance_plus)
	btn_intellect.pressed.connect(_on_intellect_plus)
	btn_wisdom.pressed.connect(_on_wisdom_plus)
	btn_spirit.pressed.connect(_on_spirit_plus)

func build_ui():
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
	vbox.name = "VBox"
	vbox.anchor_left = 0.02
	vbox.anchor_top = 0.02
	vbox.anchor_right = 0.98
	vbox.anchor_bottom = 0.98
	add_child(vbox)
	
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "ПРОФИЛЬ ИГРОКА"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(top_bar)
	
	var level_box = HBoxContainer.new()
	top_bar.add_child(level_box)
	
	var level_icon = Label.new()
	level_icon.text = "🎚️"
	level_icon.add_theme_font_size_override("font_size", 16)
	level_box.add_child(level_icon)
	
	var level_lab = Label.new()
	level_lab.text = "Уровень:"
	level_lab.add_theme_font_size_override("font_size", 14)
	level_box.add_child(level_lab)
	
	level_label = Label.new()
	level_label.name = "LevelValue"
	level_label.text = "1"
	level_label.add_theme_color_override("font_color", Color(1,0.84,0))
	level_label.add_theme_font_size_override("font_size", 14)
	level_box.add_child(level_label)
	
	var sp1 = Control.new()
	sp1.custom_minimum_size.x = 20
	top_bar.add_child(sp1)
	
	var hp_box = HBoxContainer.new()
	top_bar.add_child(hp_box)
	
	var hp_icon = Label.new()
	hp_icon.text = "❤️"
	hp_icon.add_theme_font_size_override("font_size", 16)
	hp_box.add_child(hp_icon)
	
	var hp_lab = Label.new()
	hp_lab.text = "HP:"
	hp_lab.add_theme_font_size_override("font_size", 14)
	hp_box.add_child(hp_lab)
	
	hp_label = Label.new()
	hp_label.name = "HPValue"
	hp_label.text = "200/200"
	hp_label.add_theme_color_override("font_color", Color(1,0.3,0.3))
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_box.add_child(hp_label)
	
	var sp2 = Control.new()
	sp2.custom_minimum_size.x = 20
	top_bar.add_child(sp2)
	
	var mana_box = HBoxContainer.new()
	top_bar.add_child(mana_box)
	
	var mana_icon = Label.new()
	mana_icon.text = "🔮"
	mana_icon.add_theme_font_size_override("font_size", 16)
	mana_box.add_child(mana_icon)
	
	var mana_lab = Label.new()
	mana_lab.text = "Мана:"
	mana_lab.add_theme_font_size_override("font_size", 14)
	mana_box.add_child(mana_lab)
	
	mana_label = Label.new()
	mana_label.name = "ManaValue"
	mana_label.text = "100/100"
	mana_label.add_theme_color_override("font_color", Color(0.3,0.6,1))
	mana_label.add_theme_font_size_override("font_size", 14)
	mana_box.add_child(mana_label)
	
	var main_content = HBoxContainer.new()
	main_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(main_content)
	
	var plus_style = StyleBoxFlat.new()
	plus_style.bg_color = Color(0.3,0.3,0.3,1)
	plus_style.border_color = Color(1,0.84,0,0.8)
	plus_style.border_width_left = 1
	plus_style.border_width_right = 1
	plus_style.border_width_top = 1
	plus_style.border_width_bottom = 1
	plus_style.corner_radius_top_left = 3
	plus_style.corner_radius_top_right = 3
	plus_style.corner_radius_bottom_left = 3
	plus_style.corner_radius_bottom_right = 3
	
	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_content.add_child(left_col)
	
	var stats_section = VBoxContainer.new()
	left_col.add_child(stats_section)
	
	var stats_title = Label.new()
	stats_title.text = "ХАРАКТЕРИСТИКИ"
	stats_title.horizontal_alignment = 1
	stats_title.add_theme_color_override("font_color", Color(1,0.84,0))
	stats_title.add_theme_font_size_override("font_size", 16)
	stats_section.add_child(stats_title)
	
	var sp_hbox = HBoxContainer.new()
	stats_section.add_child(sp_hbox)
	
	var sp_label = Label.new()
	sp_label.text = "⭐ Свободные очки:"
	sp_label.add_theme_font_size_override("font_size", 14)
	sp_hbox.add_child(sp_label)
	
	stat_points_label = Label.new()
	stat_points_label.text = "15"
	stat_points_label.add_theme_color_override("font_color", Color(1,0.84,0))
	stat_points_label.add_theme_font_size_override("font_size", 14)
	sp_hbox.add_child(stat_points_label)
	
	var sp_spacer = Control.new()
	sp_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp_hbox.add_child(sp_spacer)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1,0.84,0,0.3)
	stats_section.add_child(sep)
	
	var stat_names = [
		"💪 Сила:", "🎯 Ловкость:", "🧠 Интуиция:",
		"❤️ Выносливость:", "🔮 Интеллект:", "📿 Мудрость:", "✨ Духовность:"
	]
	var stat_values = ["0","0","0","0","0","0","0"]
	var stat_fields = ["strength","agility","intuition","endurance","intellect","wisdom","spirit"]
	
	for i in range(7):
		var hbox = HBoxContainer.new()
		stats_section.add_child(hbox)
		
		var label = Label.new()
		label.text = stat_names[i]
		label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(label)
		
		var val = Label.new()
		val.name = "Value"
		val.text = stat_values[i]
		val.add_theme_font_size_override("font_size", 14)
		hbox.add_child(val)
		val.owner = self
		match stat_fields[i]:
			"strength": stat_strength = val
			"agility": stat_agility = val
			"intuition": stat_intuition = val
			"endurance": stat_endurance = val
			"intellect": stat_intellect = val
			"wisdom": stat_wisdom = val
			"spirit": stat_spirit = val
		
		var hbox_spacer = Control.new()
		hbox_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(hbox_spacer)
		
		var plus = Button.new()
		plus.name = "Plus"
		plus.text = "+"
		plus.custom_minimum_size = Vector2(30,25)
		plus.add_theme_stylebox_override("normal", plus_style)
		hbox.add_child(plus)
		plus.owner = self
		match stat_fields[i]:
			"strength": btn_strength = plus
			"agility": btn_agility = plus
			"intuition": btn_intuition = plus
			"endurance": btn_endurance = plus
			"intellect": btn_intellect = plus
			"wisdom": btn_wisdom = plus
			"spirit": btn_spirit = plus
	
	var mid_col = VBoxContainer.new()
	mid_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_content.add_child(mid_col)
	
	var pass_section = VBoxContainer.new()
	mid_col.add_child(pass_section)
	
	var pass_title = Label.new()
	pass_title.text = "ПАССИВНЫЕ"
	pass_title.horizontal_alignment = 1
	pass_title.add_theme_color_override("font_color", Color(1,0.84,0))
	pass_title.add_theme_font_size_override("font_size", 16)
	pass_section.add_child(pass_title)
	
	var pass_list = [
		["⚔️ Атака:", "100"],
		["🛡️ Защита:", "50"],
		["❤️ НР:", "200/200"],
		["🔮 Мана:", "100/100"],
		["🎯 Шанс крита:", "5%"],
		["💥 Крит.урон:", "150%"],
		["🌀 Уклонение:", "5%"],
		["✨ Маг.файнд:", "5%"]
	]
	var pass_fields = ["attack","defense","hp","mana","crit_chance","crit_damage","evasion","magic_find"]
	
	for i in range(8):
		var hbox = HBoxContainer.new()
		pass_section.add_child(hbox)
		
		var label = Label.new()
		label.text = pass_list[i][0]
		label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(label)
		
		var val = Label.new()
		val.name = "Value"
		val.text = pass_list[i][1]
		val.add_theme_font_size_override("font_size", 14)
		hbox.add_child(val)
		val.owner = self
		match pass_fields[i]:
			"attack": passive_attack = val
			"defense": passive_defense = val
			"hp": passive_hp = val
			"mana": passive_mana = val
			"crit_chance": passive_crit_chance = val
			"crit_damage": passive_crit_damage = val
			"evasion": passive_evasion = val
			"magic_find": passive_magic_find = val
		
		var hbox_spacer = Control.new()
		hbox_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(hbox_spacer)
	
	var elem_section = VBoxContainer.new()
	mid_col.add_child(elem_section)
	
	var elem_title = Label.new()
	elem_title.text = "СТИХИИ"
	elem_title.horizontal_alignment = 1
	elem_title.add_theme_color_override("font_color", Color(1,0.84,0))
	elem_title.add_theme_font_size_override("font_size", 16)
	elem_section.add_child(elem_title)
	
	var elem_list = [
		["🔥 Огонь:", "0"],
		["💧 Вода:", "0"],
		["🌍 Земля:", "0"],
		["🌪️ Воздух:", "0"],
		["☀️ Свет:", "0"],
		["🌑 Тьма:", "0"]
	]
	var elem_fields = ["fire","water","earth","air","light","dark"]
	
	for i in range(6):
		var hbox = HBoxContainer.new()
		elem_section.add_child(hbox)
		
		var label = Label.new()
		label.text = elem_list[i][0]
		label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(label)
		
		var val = Label.new()
		val.name = "Value"
		val.text = elem_list[i][1]
		val.add_theme_font_size_override("font_size", 14)
		hbox.add_child(val)
		val.owner = self
		match elem_fields[i]:
			"fire": element_fire = val
			"water": element_water = val
			"earth": element_earth = val
			"air": element_air = val
			"light": element_light = val
			"dark": element_dark = val
		
		var hbox_spacer = Control.new()
		hbox_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(hbox_spacer)
	
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_content.add_child(right_col)
	
	var acc_section = VBoxContainer.new()
	right_col.add_child(acc_section)
	
	var acc_title = Label.new()
	acc_title.text = "ИНФОРМАЦИЯ"
	acc_title.horizontal_alignment = 1
	acc_title.add_theme_color_override("font_color", Color(1,0.84,0))
	acc_title.add_theme_font_size_override("font_size", 16)
	acc_section.add_child(acc_title)
	
	var acc_info = [
		["🏷️ Ник:", "Новичок"],
		["⚥ Пол:", "Не указан"],
		["🔮 Стихия:", "—"],
		["👑 Титул:", "—"],
		["🏛️ Гильдия:", "—"],
		["🛡️ Герб:", "—"]
	]
	var acc_fields = ["nick","gender","element","title","guild","emblem"]
	
	for i in range(6):
		var hbox = HBoxContainer.new()
		acc_section.add_child(hbox)
		
		var label = Label.new()
		label.text = acc_info[i][0]
		label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(label)
		
		var val = Label.new()
		val.name = "Value"
		val.text = acc_info[i][1]
		val.add_theme_font_size_override("font_size", 14)
		hbox.add_child(val)
		val.owner = self
		match acc_fields[i]:
			"nick": info_nick = val
			"gender": info_gender = val
			"element": info_element = val
			"title": info_title = val
			"guild": info_guild = val
			"emblem": info_guild_emblem = val
		
		var hbox_spacer = Control.new()
		hbox_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(hbox_spacer)
	
	var stat_section = VBoxContainer.new()
	right_col.add_child(stat_section)
	
	var stat_title2 = Label.new()
	stat_title2.text = "СТАТИСТИКА"
	stat_title2.horizontal_alignment = 1
	stat_title2.add_theme_color_override("font_color", Color(1,0.84,0))
	stat_title2.add_theme_font_size_override("font_size", 16)
	stat_section.add_child(stat_title2)
	
	var stat_list = [
		["⚔️ ПВП побед:", "0"],
		["👾 Монстров:", "0"],
		["💰 Заработано:", "0"],
		["👑 Боссов:", "0"]
	]
	var stat_fields2 = ["pvp_wins","monsters","earned","bosses"]
	
	for i in range(4):
		var hbox = HBoxContainer.new()
		stat_section.add_child(hbox)
		
		var label = Label.new()
		label.text = stat_list[i][0]
		label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(label)
		
		var val = Label.new()
		val.name = "Value"
		val.text = stat_list[i][1]
		val.add_theme_font_size_override("font_size", 14)
		hbox.add_child(val)
		val.owner = self
		match stat_fields2[i]:
			"pvp_wins": stat_pvp_wins = val
			"monsters": stat_monsters = val
			"earned": stat_earned = val
			"bosses": stat_bosses = val
		
		var hbox_spacer = Control.new()
		hbox_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(hbox_spacer)

func setup_buffs_display():
	var right_col = null
	for child in get_children():
		if child is VBoxContainer:
			var vbox = child
			for c in vbox.get_children():
				if c is HBoxContainer:
					for col in c.get_children():
						if col is VBoxContainer and col.get_child_count() > 0:
							var first_child = col.get_child(0)
							if first_child is Label and first_child.text == "СТАТИСТИКА":
								right_col = col
								break
				if right_col:
					break
		if right_col:
			break
	
	if not right_col:
		for child in get_children():
			if child is VBoxContainer:
				for c in child.get_children():
					if c is HBoxContainer and c.get_child_count() >= 3:
						right_col = c.get_child(2)
						break
			if right_col:
				break
	
	if not right_col:
		return
	
	var buff_section = VBoxContainer.new()
	buff_section.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_col.add_child(buff_section)
	
	var buff_title = Label.new()
	buff_title.text = "АКТИВНЫЕ БАФЫ"
	buff_title.horizontal_alignment = 1
	buff_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	buff_title.add_theme_font_size_override("font_size", 16)
	buff_section.add_child(buff_title)
	
	active_buffs_label = Label.new()
	active_buffs_label.text = "Нет активных бафов"
	active_buffs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	active_buffs_label.add_theme_font_size_override("font_size", 12)
	active_buffs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buff_section.add_child(active_buffs_label)
	
	buffs_timer = Timer.new()
	buffs_timer.wait_time = 1.0
	buffs_timer.timeout.connect(_update_buffs_display)
	add_child(buffs_timer)
	buffs_timer.start()

func _update_buffs_display():
	if not active_buffs_label:
		return
	
	if not NetworkManager or not NetworkManager.player_data:
		active_buffs_label.text = "Нет активных бафов"
		return
	
	var tavern_buffs = NetworkManager.player_data.get("tavern_buffs", {})
	var food_buff = tavern_buffs.get("active_food_buff", null)
	var song_buff = tavern_buffs.get("active_song_buff", null)
	
	var buff_texts = []
	var current_time = Time.get_unix_time_from_system()
	
	if food_buff:
		var remaining = int(food_buff["expires_at"] - current_time)
		if remaining > 0:
			var minutes = remaining / 60
			var seconds = remaining % 60
			var buff_desc = _get_buff_description(food_buff["type"], food_buff["value"])
			buff_texts.append("🍽️ " + food_buff["name"] + " (" + buff_desc + ") - " + str(minutes) + ":" + str(seconds).pad_zeros(2))
	
	if song_buff:
		var remaining = int(song_buff["expires_at"] - current_time)
		if remaining > 0:
			var minutes = remaining / 60
			var seconds = remaining % 60
			var buff_desc = _get_buff_description(song_buff["type"], song_buff["value"])
			buff_texts.append("🎵 " + song_buff["name"] + " (" + buff_desc + ") - " + str(minutes) + ":" + str(seconds).pad_zeros(2))
	
	if buff_texts.size() > 0:
		active_buffs_label.text = "• " + ("\n• ".join(buff_texts))
		active_buffs_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	else:
		active_buffs_label.text = "Нет активных бафов"
		active_buffs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _get_buff_description(buff_type: String, value: int) -> String:
	match buff_type:
		"exp": return "+" + str(value) + "% опыта"
		"max_hp": return "+" + str(value) + " HP"
		"strength": return "+" + str(value) + " к атаке"
		"speed": return "+" + str(value) + "% скорости"
		"defense": return "+" + str(value) + "% защиты"
		"gold": return "+" + str(value) + "% золота"
		"attack": return "+" + str(value) + "% атаки"
		"crit_chance": return "+" + str(value) + "% крита"
		"evasion": return "+" + str(value) + "% уклонения"
		"regen": return "+" + str(value) + " HP/сек"
		"berserk": return "+" + str(value) + "% атаки"
		_: return "+" + str(value) + " к " + buff_type

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
		stat_points = player_data.get("stat_points", 15)
	else:
		player_data = {
			"name": "Новичок",
			"level": 1,
			"gender": "Не указан",
			"element": "—",
			"title": "—",
			"guild": "—",
			"guild_emblem": "—",
			"stat_points": 15,
			"stats": {
				"strength": 0,
				"agility": 0,
				"intuition": 0,
				"endurance": 0,
				"intellect": 0,
				"wisdom": 0,
				"spirit": 0
			},
			"elements": {
				"fire": 0,
				"water": 0,
				"earth": 0,
				"air": 0,
				"light": 0,
				"dark": 0
			},
			"stats_pvp": {
				"pvp_wins": 0,
				"monsters": 0,
				"earned": 0,
				"bosses": 0
			}
		}

func update_ui():
	level_label.text = str(player_data.get("level", 1))
	stat_points_label.text = str(stat_points)
	var s = player_data["stats"]
	
	stat_strength.text = str(s["strength"])
	stat_agility.text = str(s["agility"])
	stat_intuition.text = str(s["intuition"])
	stat_endurance.text = str(s["endurance"])
	stat_intellect.text = str(s["intellect"])
	stat_wisdom.text = str(s["wisdom"])
	stat_spirit.text = str(s["spirit"])
	
	update_plus_buttons()
	calculate_passives()
	
	element_fire.text = str(player_data["elements"]["fire"])
	element_water.text = str(player_data["elements"]["water"])
	element_earth.text = str(player_data["elements"]["earth"])
	element_air.text = str(player_data["elements"]["air"])
	element_light.text = str(player_data["elements"]["light"])
	element_dark.text = str(player_data["elements"]["dark"])
	
	info_nick.text = player_data.get("name", "—")
	info_gender.text = player_data.get("gender", "—")
	info_element.text = player_data.get("element", "—")
	info_title.text = player_data.get("title", "—")
	info_guild.text = player_data.get("guild", "—")
	info_guild_emblem.text = player_data.get("guild_emblem", "—")
	
	stat_pvp_wins.text = str(player_data["stats_pvp"]["pvp_wins"])
	stat_monsters.text = str(player_data["stats_pvp"]["monsters"])
	stat_earned.text = format_number(player_data["stats_pvp"]["earned"])
	stat_bosses.text = str(player_data["stats_pvp"]["bosses"])

func update_plus_buttons():
	var buttons = [btn_strength, btn_agility, btn_intuition, btn_endurance, btn_intellect, btn_wisdom, btn_spirit]
	for btn in buttons:
		btn.disabled = stat_points <= 0
		btn.modulate = Color(1,1,1, 1.0 if stat_points > 0 else 0.5)

func calculate_passives():
	var s = player_data["stats"]
	
	var base_attack = 100 + s["strength"] * 2
	var base_defense = 50 + s["endurance"]
	var base_hp = 200 + s["endurance"] * 5
	var base_mana = 100 + s["wisdom"] * 3
	var base_crit_chance = 5 + s["agility"] * 0.5
	var base_crit_damage = 150 + s["intuition"]
	var base_evasion = 5 + s["agility"] * 0.5
	var base_magic_find = 5 + s["intuition"] * 0.3
	
	var tavern_buffs = player_data.get("tavern_buffs", {})
	var food_buff = tavern_buffs.get("active_food_buff", null)
	var song_buff = tavern_buffs.get("active_song_buff", null)
	
	var attack_mult = 1.0
	var defense_mult = 1.0
	var hp_bonus = 0
	var crit_bonus = 0
	var evasion_bonus = 0
	
	if food_buff:
		var remaining = int(food_buff["expires_at"] - Time.get_unix_time_from_system())
		if remaining > 0:
			match food_buff["type"]:
				"strength":
					base_attack += food_buff["value"]
				"max_hp":
					hp_bonus = food_buff["value"]
				"defense":
					defense_mult += food_buff["value"] / 100.0
				"attack":
					attack_mult += food_buff["value"] / 100.0
	
	if song_buff:
		var remaining = int(song_buff["expires_at"] - Time.get_unix_time_from_system())
		if remaining > 0:
			match song_buff["type"]:
				"attack":
					attack_mult += song_buff["value"] / 100.0
				"defense":
					defense_mult += song_buff["value"] / 100.0
				"crit_chance":
					crit_bonus = song_buff["value"]
				"evasion":
					evasion_bonus = song_buff["value"]
				"berserk":
					attack_mult += song_buff["value"] / 100.0
	
	var final_attack = int(base_attack * attack_mult)
	var final_defense = int(base_defense * defense_mult)
	var final_hp = int(base_hp + hp_bonus)
	var final_mana = int(base_mana)
	var final_crit_chance = int(base_crit_chance + crit_bonus)
	var final_evasion = int(base_evasion + evasion_bonus)
	
	passive_attack.text = str(final_attack)
	passive_defense.text = str(final_defense)
	passive_hp.text = str(final_hp) + "/" + str(final_hp)
	passive_mana.text = str(final_mana) + "/" + str(final_mana)
	passive_crit_chance.text = str(final_crit_chance) + "%"
	passive_crit_damage.text = str(int(base_crit_damage)) + "%"
	passive_evasion.text = str(final_evasion) + "%"
	passive_magic_find.text = str(int(base_magic_find)) + "%"
	
	hp_label.text = str(final_hp) + "/" + str(final_hp)
	mana_label.text = str(final_mana) + "/" + str(final_mana)

func format_number(num: int) -> String:
	if num >= 1000000:
		return str(num / 1000000) + "M"
	elif num >= 1000:
		return str(num / 1000) + "K"
	return str(num)

func send_stat_update(stat_name: String, new_value: int):
	if NetworkManager:
		NetworkManager.send_stat_update(stat_name, new_value, stat_points)

func _on_strength_plus():
	if stat_points > 0:
		player_data["stats"]["strength"] += 1
		stat_points -= 1
		update_ui()
		send_stat_update("strength", player_data["stats"]["strength"])

func _on_agility_plus():
	if stat_points > 0:
		player_data["stats"]["agility"] += 1
		stat_points -= 1
		update_ui()
		send_stat_update("agility", player_data["stats"]["agility"])

func _on_intuition_plus():
	if stat_points > 0:
		player_data["stats"]["intuition"] += 1
		stat_points -= 1
		update_ui()
		send_stat_update("intuition", player_data["stats"]["intuition"])

func _on_endurance_plus():
	if stat_points > 0:
		player_data["stats"]["endurance"] += 1
		stat_points -= 1
		update_ui()
		send_stat_update("endurance", player_data["stats"]["endurance"])

func _on_intellect_plus():
	if stat_points > 0:
		player_data["stats"]["intellect"] += 1
		stat_points -= 1
		update_ui()
		send_stat_update("intellect", player_data["stats"]["intellect"])

func _on_wisdom_plus():
	if stat_points > 0:
		player_data["stats"]["wisdom"] += 1
		stat_points -= 1
		update_ui()
		send_stat_update("wisdom", player_data["stats"]["wisdom"])

func _on_spirit_plus():
	if stat_points > 0:
		player_data["stats"]["spirit"] += 1
		stat_points -= 1
		update_ui()
		send_stat_update("spirit", player_data["stats"]["spirit"])

func _on_network_data(data: String):
	var parts = data.split("|")
	if parts[0] == "STAT_UPDATE_OK":
		pass
	elif parts[0] == "STAT_UPDATE_FAIL":
		print("❌ Ошибка обновления стата, откат")
		load_player_data()
		update_ui()

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	stat_points = player_data.get("stat_points", 15)
	update_ui()
	_update_buffs_display()

func _on_close():
	if buffs_timer:
		buffs_timer.stop()
	queue_free()
