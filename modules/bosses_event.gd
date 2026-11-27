# res://modules/bosses_event.gd
extends Panel

var close_btn
var content_container
var player_data = {}
var purchased_rumors = []
var update_timer = null

var event_ended_bosses = []
var announced_event_bosses = []

var bosses_db = {
	"pumpkin_king": {
		"name": "Тыквоголовый",
		"icon": "🎃",
		"level": 30,
		"hp": 8000,
		"attack_min": 120,
		"attack_max": 180,
		"defense": 80,
		"location": "halloween_field",
		"location_name": "Тыквенное поле",
		"event_name": "halloween",
		"start_month": 10,
		"start_day": 25,
		"end_month": 10,
		"end_day": 31,
		"description": "Таинственное существо, появляющееся в канун Дня всех святых.",
		"enemies": [
			{"name": "Летучая мышь", "level": 20, "damage": "60-90", "icon": "🦇", "drops": "Крыло мыши"},
			{"name": "Призрачный слуга", "level": 25, "damage": "80-120", "icon": "👻", "drops": "Призрачная пыль"}
		],
		"rewards": {"exp": 800, "gold": 2000, "points": 80},
		"drops": [
			{"item": "pumpkin_helmet", "name": "Тыквенный шлем", "chance": 15, "icon": "🎃"},
			{"item": "candy", "name": "Конфета", "chance": 100, "icon": "🍬"},
			{"item": "glowing_sword", "name": "Светящийся меч", "chance": 8, "icon": "⚔️"}
		],
		"rumor": "Говорят, что тот, кто снимет шлем с Тыквоголового, получит его силу."
	},
	"ice_giant": {
		"name": "Ледяной великан",
		"icon": "❄️",
		"level": 40,
		"hp": 12000,
		"attack_min": 150,
		"attack_max": 220,
		"defense": 100,
		"location": "frozen_peak",
		"location_name": "Ледяная вершина",
		"event_name": "new_year",
		"start_month": 12,
		"start_day": 25,
		"end_month": 1,
		"end_day": 10,
		"description": "Гигантское существо из льда и снега, приносящее зимний холод.",
		"enemies": [
			{"name": "Снежный элементаль", "level": 30, "damage": "100-150", "icon": "❄️", "drops": "Снежный кристалл"},
			{"name": "Ледяной дракончик", "level": 35, "damage": "120-180", "icon": "🐉", "drops": "Ледяная чешуя"}
		],
		"rewards": {"exp": 1000, "gold": 3000, "points": 100},
		"drops": [
			{"item": "snowflake", "name": "Снежинка", "chance": 100, "icon": "❄️"},
			{"item": "new_year_hat", "name": "Новогодний колпак", "chance": 20, "icon": "🎩"},
			{"item": "ice_staff", "name": "Ледяной посох", "chance": 10, "icon": "🔮"}
		],
		"rumor": "Великан хранит секрет вечной зимы в своей ледяной короне."
	},
	"easter_bunny": {
		"name": "Пасхальный кролик",
		"icon": "🐰",
		"level": 25,
		"hp": 6000,
		"attack_min": 80,
		"attack_max": 120,
		"defense": 60,
		"location": "easter_meadow",
		"location_name": "Пасхальный луг",
		"event_name": "easter",
		"start_month": 3,
		"start_day": 20,
		"end_month": 4,
		"end_day": 15,
		"description": "Волшебный кролик, прячущий пасхальные яйца по всему миру.",
		"enemies": [
			{"name": "Золотой цыплёнок", "level": 20, "damage": "70-100", "icon": "🐥", "drops": "Золотое яйцо"},
			{"name": "Шоколадный заяц", "level": 22, "damage": "75-110", "icon": "🍫", "drops": "Шоколадное яйцо"}
		],
		"rewards": {"exp": 600, "gold": 1500, "points": 60},
		"drops": [
			{"item": "easter_egg", "name": "Пасхальное яйцо", "chance": 100, "icon": "🥚"},
			{"item": "gift_basket", "name": "Корзина с подарками", "chance": 15, "icon": "🧺"},
			{"item": "carrot_sword", "name": "Морковный меч", "chance": 8, "icon": "🥕"}
		],
		"rumor": "Кролик прячет самое большое золотое яйцо где-то в лесу."
	},
	"gingerbread_golem": {
		"name": "Имбирный голем",
		"icon": "🍪",
		"level": 35,
		"hp": 10000,
		"attack_min": 130,
		"attack_max": 190,
		"defense": 90,
		"location": "sweet_forest",
		"location_name": "Сладкий лес",
		"event_name": "birthday",
		"start_month": 6,
		"start_day": 1,
		"end_month": 6,
		"end_day": 7,
		"description": "Ожившая имбирная фигура, охраняющая праздничные подарки.",
		"enemies": [
			{"name": "Имбирный солдат", "level": 28, "damage": "90-130", "icon": "🍪", "drops": "Имбирное печенье"},
			{"name": "Конфетный дух", "level": 32, "damage": "110-160", "icon": "🍬", "drops": "Леденец"}
		],
		"rewards": {"exp": 900, "gold": 2500, "points": 90},
		"drops": [
			{"item": "gift_box", "name": "Подарочная коробка", "chance": 100, "icon": "🎁"},
			{"item": "birthday_cake", "name": "Праздничный торт", "chance": 20, "icon": "🎂"},
			{"item": "confetti", "name": "Конфетти", "chance": 50, "icon": "🎉"}
		],
		"rumor": "Голем спрятал главный подарок где-то внутри себя."
	}
}

func _ready():
	build_ui()
	load_player_data()
	update_bosses_list()
	
	close_btn.pressed.connect(_on_close)
	
	update_timer = Timer.new()
	update_timer.wait_time = 60.0
	update_timer.timeout.connect(_update_event_status)
	add_child(update_timer)
	update_timer.start()
	
	if NetworkManager:
		if NetworkManager.has_signal("player_data_updated"):
			NetworkManager.player_data_updated.connect(_on_player_data_updated)

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
	title.text = "⚡ СОБЫТИЙНЫЕ БОССЫ ⚡"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 24)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(40, 40)
	top_panel.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_vbox.add_child(scroll)
	
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 12)
	scroll.add_child(content_container)

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate(true)
		purchased_rumors = player_data.get("purchased_rumors", [])
		event_ended_bosses = player_data.get("event_bosses_defeated", [])
	else:
		player_data = {"name": "Игрок", "level": 1, "gold": 1000}
		purchased_rumors = []
		event_ended_bosses = []

func save_event_defeated():
	player_data["event_bosses_defeated"] = event_ended_bosses
	if NetworkManager:
		NetworkManager.player_data = player_data
		NetworkManager.save_local_data()

func get_current_date():
	var date = Time.get_date_dict_from_system()
	return {"month": date["month"], "day": date["day"]}

func is_event_active(boss: Dictionary) -> bool:
	var current = get_current_date()
	var start_month = boss["start_month"]
	var start_day = boss["start_day"]
	var end_month = boss["end_month"]
	var end_day = boss["end_day"]
	
	if start_month == end_month:
		return current["month"] == start_month and current["day"] >= start_day and current["day"] <= end_day
	else:
		if current["month"] == start_month and current["day"] >= start_day:
			return true
		if current["month"] == end_month and current["day"] <= end_day:
			return true
		return false

func get_event_status_text(boss: Dictionary) -> Dictionary:
	var end_month = boss["end_month"]
	var end_day = boss["end_day"]
	var start_month = boss["start_month"]
	var start_day = boss["start_day"]
	
	if is_event_active(boss):
		var days_left = _days_until_date(end_month, end_day)
		return {"text": "🟢 АКТИВНО! (осталось " + str(days_left) + " д.)", "color": Color(0.3, 0.8, 0.3)}
	
	if _is_date_passed(end_month, end_day):
		return {"text": "⚫ Ивент завершён", "color": Color(0.5, 0.5, 0.5)}
	
	var days_until = _days_until_date(start_month, start_day)
	if days_until > 0:
		return {"text": "🟡 Скоро (через " + str(days_until) + " д.)", "color": Color(0.8, 0.8, 0.2)}
	
	return {"text": "⚫ Недоступен", "color": Color(0.5, 0.5, 0.5)}

func _days_until_date(month: int, day: int) -> int:
	var current = Time.get_date_dict_from_system()
	var current_days = _day_of_year(current["year"], current["month"], current["day"])
	var target_days = _day_of_year(current["year"], month, day)
	
	if target_days >= current_days:
		return target_days - current_days
	else:
		var next_year = current["year"] + 1
		var days_in_year = 365 + (1 if _is_leap_year(next_year) else 0)
		return (days_in_year - current_days) + target_days

func _day_of_year(year: int, month: int, day: int) -> int:
	var days_in_month = [31, 28 + (1 if _is_leap_year(year) else 0), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var total_days = 0
	for i in range(month - 1):
		total_days += days_in_month[i]
	total_days += day
	return total_days

func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

func _is_date_passed(month: int, day: int) -> bool:
	var current = get_current_date()
	if current["month"] > month:
		return true
	if current["month"] == month and current["day"] > day:
		return true
	return false

func update_bosses_list():
	for child in content_container.get_children():
		child.queue_free()
	
	for boss_id in bosses_db:
		var boss = bosses_db[boss_id]
		var card = create_boss_card(boss_id, boss)
		content_container.add_child(card)

func create_boss_card(boss_id: String, boss: Dictionary) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size.y = 220
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var is_available = is_event_active(boss)
	var is_defeated = boss_id in event_ended_bosses
	var status = get_event_status_text(boss)
	
	var border_color = Color(0.3, 0.8, 0.3) if is_available else Color(0.5, 0.5, 0.5)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.1, 0.08, 0.9)
	card_style.border_color = border_color
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.01
	margin.anchor_top = 0.02
	margin.anchor_right = 0.99
	margin.anchor_bottom = 0.98
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = boss["icon"]
	icon_label.add_theme_font_size_override("font_size", 36)
	title_hbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = boss["name"]
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	name_label.add_theme_font_size_override("font_size", 18)
	title_hbox.add_child(name_label)
	
	var level_label = Label.new()
	level_label.text = "Ур. " + str(boss["level"])
	level_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	level_label.add_theme_font_size_override("font_size", 14)
	title_hbox.add_child(level_label)
	
	var period_hbox = HBoxContainer.new()
	period_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(period_hbox)
	
	var period_text = str(boss["start_day"]) + "." + str(boss["start_month"]) + " - " + str(boss["end_day"]) + "." + str(boss["end_month"])
	var period_label = Label.new()
	period_label.text = "📅 " + period_text
	period_label.add_theme_font_size_override("font_size", 11)
	period_hbox.add_child(period_label)
	
	var status_label = Label.new()
	status_label.text = status["text"]
	status_label.add_theme_color_override("font_color", status["color"])
	status_label.add_theme_font_size_override("font_size", 12)
	period_hbox.add_child(status_label)
	
	var info_grid = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 20)
	vbox.add_child(info_grid)
	
	var hp_label = Label.new()
	hp_label.text = "❤️ " + str(boss["hp"])
	hp_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(hp_label)
	
	var attack_label = Label.new()
	attack_label.text = "🗡️ " + str(boss["attack_min"]) + "-" + str(boss["attack_max"])
	attack_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(attack_label)
	
	var defense_label = Label.new()
	defense_label.text = "🛡️ " + str(boss["defense"])
	defense_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(defense_label)
	
	var location_label = Label.new()
	location_label.text = "📍 " + boss["location_name"]
	location_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1))
	location_label.add_theme_font_size_override("font_size", 11)
	info_grid.add_child(location_label)
	
	var desc_label = Label.new()
	desc_label.text = boss["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	
	var reward_hbox = HBoxContainer.new()
	reward_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(reward_hbox)
	
	var exp_label = Label.new()
	exp_label.text = "⭐ " + str(boss["rewards"]["exp"])
	exp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	exp_label.add_theme_font_size_override("font_size", 11)
	reward_hbox.add_child(exp_label)
	
	var gold_label = Label.new()
	gold_label.text = "💰 " + str(boss["rewards"]["gold"])
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	gold_label.add_theme_font_size_override("font_size", 11)
	reward_hbox.add_child(gold_label)
	
	var points_label = Label.new()
	points_label.text = "🏅 " + str(boss["rewards"]["points"])
	points_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	points_label.add_theme_font_size_override("font_size", 11)
	reward_hbox.add_child(points_label)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_END
	btn_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_hbox)
	
	var detail_btn = Button.new()
	detail_btn.text = "ПОДРОБНЕЕ"
	detail_btn.custom_minimum_size = Vector2(100, 32)
	detail_btn.pressed.connect(_show_boss_detail.bind(boss_id))
	btn_hbox.add_child(detail_btn)
	
	var fight_btn = Button.new()
	fight_btn.text = "СРАЖАТЬСЯ"
	fight_btn.custom_minimum_size = Vector2(100, 32)
	
	if is_available and not is_defeated:
		fight_btn.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		fight_btn.pressed.connect(_fight_boss.bind(boss_id))
	else:
		fight_btn.disabled = true
		fight_btn.modulate = Color(0.5, 0.5, 0.5)
		if is_defeated:
			fight_btn.text = "ПОБЕЖДЁН"
	
	btn_hbox.add_child(fight_btn)
	
	return card

func _update_event_status():
	var changed = false
	for boss_id in bosses_db:
		var boss = bosses_db[boss_id]
		if is_event_active(boss) and not (boss_id in announced_event_bosses):
			announced_event_bosses.append(boss_id)
			var text = boss["icon"] + " " + boss["name"] + " пробудился в локации \"" + boss["location_name"] + "\"! Ивент активен!"
			if NetworkManager:
				NetworkManager.data_received.emit("CHAT_MSG|Система|system|" + text)
			changed = true
	if changed or true:
		update_bosses_list()

func _convert_event_drops(boss_drops: Array) -> Array:
	var result = []
	for drop in boss_drops:
		result.append({
			"item_id": drop["item"],
			"name": drop["name"],
			"chance": drop["chance"],
			"min_qty": 1,
			"max_qty": 1,
			"icon": drop.get("icon", "📦")
		})
	return result

func _fight_boss(boss_id: String):
	var boss = bosses_db[boss_id]
	var is_defeated = boss_id in event_ended_bosses
	var player_level = player_data.get("level", 1)
	
	if is_defeated:
		_show_message("⚠️ Вы уже побеждали этого босса в этом году!")
		return
	
	if not is_event_active(boss):
		_show_message("⚠️ Событийный босс сейчас недоступен!")
		return
	
	if player_level < boss["level"]:
		_show_message("⚠️ Ваш уровень (" + str(player_level) + ") ниже уровня босса (" + str(boss["level"]) + ")!")
		return
	
	var boss_data = {
		"name": boss["name"],
		"hp": boss["hp"],
		"max_hp": boss["hp"],
		"attack": (boss["attack_min"] + boss["attack_max"]) / 2,
		"defense": boss["defense"],
		"level": boss["level"],
		"icon": boss["icon"],
		"mob_id": boss_id,
		"ai_pattern": "aggressive",
		"drops": _convert_event_drops(boss["drops"]),
		"gold_min": boss["rewards"]["gold"],
		"gold_max": boss["rewards"]["gold"] + 50,
		"exp_min": boss["rewards"]["exp"],
		"exp_max": boss["rewards"]["exp"] + 100
	}
	
	_on_close()
	
	var battle = load("res://modules/battle_system.gd").new()
	add_child(battle)
	battle.start_battle(boss_data, battle.BattleType.PVE, {
		"source": "boss_event",
		"boss_id": boss_id,
		"on_victory": _on_event_boss_defeated,
		"context": {"boss_id": boss_id, "boss": boss}
	})

func _on_event_boss_defeated(context: Dictionary):
	var boss_id = context.get("boss_id", "")
	var boss = context.get("boss", {})
	
	if boss_id == "" or boss.is_empty():
		return
	
	if not (boss_id in event_ended_bosses):
		event_ended_bosses.append(boss_id)
		save_event_defeated()
	
	update_bosses_list()

func _show_boss_detail(boss_id: String):
	var boss = bosses_db[boss_id]
	var status = get_event_status_text(boss)
	
	var detail_window = Panel.new()
	detail_window.anchor_left = 0.08
	detail_window.anchor_top = 0.03
	detail_window.anchor_right = 0.92
	detail_window.anchor_bottom = 0.97
	add_child(detail_window)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.03, 0.98)
	style.border_color = Color(0.6, 0.4, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	detail_window.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.anchor_left = 0.02
	margin.anchor_top = 0.02
	margin.anchor_right = 0.98
	margin.anchor_bottom = 0.98
	detail_window.add_child(margin)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(title_hbox)
	
	var icon_label = Label.new()
	icon_label.text = boss["icon"]
	icon_label.add_theme_font_size_override("font_size", 48)
	title_hbox.add_child(icon_label)
	
	var title_label = Label.new()
	title_label.text = boss["name"]
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title_label.add_theme_font_size_override("font_size", 26)
	title_hbox.add_child(title_label)
	
	var close_btn_detail = Button.new()
	close_btn_detail.text = "×"
	close_btn_detail.custom_minimum_size = Vector2(40, 40)
	close_btn_detail.pressed.connect(detail_window.queue_free)
	title_hbox.add_child(close_btn_detail)
	
	var info_line = Label.new()
	var period_text = "📅 " + str(boss["start_day"]) + "." + str(boss["start_month"]) + " - " + str(boss["end_day"]) + "." + str(boss["end_month"])
	info_line.text = period_text + " | " + status["text"]
	info_line.add_theme_color_override("font_color", status["color"])
	info_line.add_theme_font_size_override("font_size", 13)
	vbox.add_child(info_line)
	
	var lore_block = VBoxContainer.new()
	lore_block.add_theme_constant_override("separation", 5)
	vbox.add_child(lore_block)
	
	var lore_title = Label.new()
	lore_title.text = "📜 ЛЕГЕНДА"
	lore_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	lore_title.add_theme_font_size_override("font_size", 18)
	lore_block.add_child(lore_title)
	
	var lore_text = Label.new()
	lore_text.text = _get_boss_lore(boss_id)
	lore_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_text.add_theme_font_size_override("font_size", 13)
	lore_text.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lore_block.add_child(lore_text)
	
	var stats_block = VBoxContainer.new()
	stats_block.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_block)
	
	var stats_title = Label.new()
	stats_title.text = "⚔️ ХАРАКТЕРИСТИКИ"
	stats_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_block.add_child(stats_title)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 30)
	stats_block.add_child(stats_grid)
	
	var add_stat = func(label_text: String, value: String, col = null):
		var name_lbl = Label.new()
		name_lbl.text = label_text
		name_lbl.add_theme_font_size_override("font_size", 13)
		stats_grid.add_child(name_lbl)
		var val_lbl = Label.new()
		val_lbl.text = value
		val_lbl.add_theme_font_size_override("font_size", 13)
		if col != null:
			val_lbl.add_theme_color_override("font_color", col)
		stats_grid.add_child(val_lbl)
	
	add_stat.call("🎚️ Уровень:", str(boss["level"]))
	add_stat.call("❤️ HP:", str(boss["hp"]), Color(1, 0.5, 0.5))
	add_stat.call("🗡️ Атака:", str(boss["attack_min"]) + "-" + str(boss["attack_max"]), Color(1, 0.7, 0.3))
	add_stat.call("🛡️ Защита:", str(boss["defense"]), Color(0.5, 0.8, 1))
	add_stat.call("📍 Локация:", boss["location_name"], Color(0.6, 0.8, 1))
	
	var reward_block = VBoxContainer.new()
	reward_block.add_theme_constant_override("separation", 8)
	vbox.add_child(reward_block)
	
	var reward_title = Label.new()
	reward_title.text = "🎁 НАГРАДА"
	reward_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	reward_title.add_theme_font_size_override("font_size", 18)
	reward_block.add_child(reward_title)
	
	var reward_list = VBoxContainer.new()
	reward_list.add_theme_constant_override("separation", 3)
	reward_block.add_child(reward_list)
	
	reward_list.add_child(_make_reward_line("⭐ Опыт:", str(boss["rewards"]["exp"])))
	reward_list.add_child(_make_reward_line("💰 Золото:", str(boss["rewards"]["gold"]), Color(1, 0.84, 0)))
	reward_list.add_child(_make_reward_line("🏅 Очки:", str(boss["rewards"]["points"]), Color(1, 0.7, 0.3)))
	
	var drops_block = VBoxContainer.new()
	drops_block.add_theme_constant_override("separation", 5)
	vbox.add_child(drops_block)
	
	var drops_title = Label.new()
	drops_title.text = "🎲 ШАНС ДРОПА"
	drops_title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	drops_title.add_theme_font_size_override("font_size", 18)
	drops_block.add_child(drops_title)
	
	for drop in boss["drops"]:
		var drop_label = Label.new()
		drop_label.text = "   " + drop["icon"] + " " + drop["name"] + " — " + str(drop["chance"]) + "%"
		drop_label.add_theme_font_size_override("font_size", 12)
		drops_block.add_child(drop_label)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)
	
	var close_popup_btn = Button.new()
	close_popup_btn.text = "ЗАКРЫТЬ"
	close_popup_btn.custom_minimum_size = Vector2(140, 45)
	close_popup_btn.pressed.connect(detail_window.queue_free)
	btn_hbox.add_child(close_popup_btn)

func _make_reward_line(label: String, value: String, color: Color = Color(0.8, 0.8, 0.8)) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var label_part = Label.new()
	label_part.text = label
	label_part.add_theme_font_size_override("font_size", 13)
	hbox.add_child(label_part)
	
	var value_part = Label.new()
	value_part.text = value
	value_part.add_theme_color_override("font_color", color)
	value_part.add_theme_font_size_override("font_size", 13)
	hbox.add_child(value_part)
	
	return hbox

func _get_boss_lore(boss_id: String) -> String:
	var lore_dict = {
		"pumpkin_king": "В канун Дня всех святых, когда луна становится кроваво-красной, на Тыквенном поле появляется Тыквоголовый. Говорят, что тот, кто сможет сорвать его светящуюся тыкву, получит силу отпугивать злых духов.",
		"ice_giant": "Раз в году, когда земля покрывается снегом, из ледяных пещер выходит Ледяной великан. Он приносит метели и морозы, а его сердце, говорят, может подарить вечную зиму.",
		"easter_bunny": "Весной, когда земля пробуждается ото сна, появляется Пасхальный кролик. Он прячет разноцветные яйца по всему миру, и тот, кто найдёт золотое яйцо, получит исполнение желания.",
		"gingerbread_golem": "В день рождения игры оживает Имбирный голем. Он охраняет праздничные подарки и угощает сладостями всех, кто сможет его победить."
	}
	return lore_dict.get(boss_id, "История этого босса окутана тайной. Многие пытались победить его, но никто не вернулся живым.")

func _show_message(text: String):
	# Компактное уведомление сверху экрана вместо огромного диалогового окна
	var toast = Panel.new()
	toast.z_index = 200
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.anchor_left = 0.3
	toast.anchor_right = 0.7
	toast.anchor_top = 0.05
	toast.anchor_bottom = 0.13
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	style.border_color = Color(1, 0.84, 0, 0.8)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	toast.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = 1
	lbl.vertical_alignment = 1
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast.add_child(lbl)
	
	add_child(toast)
	
	var tw = create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)

func _on_player_data_updated(new_data: Dictionary):
	player_data = new_data.duplicate(true)
	purchased_rumors = player_data.get("purchased_rumors", [])
	event_ended_bosses = player_data.get("event_bosses_defeated", [])
	update_bosses_list()

func _on_close():
	if update_timer:
		update_timer.stop()
	queue_free()
