extends Panel

@onready var close_btn = $VBox/TopPanel/CloseBtn
@onready var level_label = $VBox/TopBar/LevelValue
@onready var hp_label = $VBox/TopBar/HPValue
@onready var mana_label = $VBox/TopBar/ManaValue
@onready var stat_points_value = $VBox/MainContent/LeftColumn/StatsSection/StatPointsValue

# Характеристики
@onready var stat_strength = $VBox/MainContent/LeftColumn/StatsSection/Strength/Value
@onready var stat_agility = $VBox/MainContent/LeftColumn/StatsSection/Agility/Value
@onready var stat_intuition = $VBox/MainContent/LeftColumn/StatsSection/Intuition/Value
@onready var stat_endurance = $VBox/MainContent/LeftColumn/StatsSection/Endurance/Value
@onready var stat_intellect = $VBox/MainContent/LeftColumn/StatsSection/Intellect/Value
@onready var stat_wisdom = $VBox/MainContent/LeftColumn/StatsSection/Wisdom/Value
@onready var stat_spirit = $VBox/MainContent/LeftColumn/StatsSection/Spirit/Value

# Кнопки +
@onready var btn_strength = $VBox/MainContent/LeftColumn/StatsSection/Strength/Plus
@onready var btn_agility = $VBox/MainContent/LeftColumn/StatsSection/Agility/Plus
@onready var btn_intuition = $VBox/MainContent/LeftColumn/StatsSection/Intuition/Plus
@onready var btn_endurance = $VBox/MainContent/LeftColumn/StatsSection/Endurance/Plus
@onready var btn_intellect = $VBox/MainContent/LeftColumn/StatsSection/Intellect/Plus
@onready var btn_wisdom = $VBox/MainContent/LeftColumn/StatsSection/Wisdom/Plus
@onready var btn_spirit = $VBox/MainContent/LeftColumn/StatsSection/Spirit/Plus

# Пассивные статы
@onready var passive_attack = $VBox/MainContent/MiddleColumn/PassivesSection/Attack/Value
@onready var passive_defense = $VBox/MainContent/MiddleColumn/PassivesSection/Defense/Value
@onready var passive_hp = $VBox/MainContent/MiddleColumn/PassivesSection/HP/Value
@onready var passive_mana = $VBox/MainContent/MiddleColumn/PassivesSection/Mana/Value
@onready var passive_crit_chance = $VBox/MainContent/MiddleColumn/PassivesSection/CritChance/Value
@onready var passive_crit_damage = $VBox/MainContent/MiddleColumn/PassivesSection/CritDamage/Value
@onready var passive_evasion = $VBox/MainContent/MiddleColumn/PassivesSection/Evasion/Value
@onready var passive_magic_find = $VBox/MainContent/MiddleColumn/PassivesSection/MagicFind/Value

# Стихии
@onready var element_fire = $VBox/MainContent/MiddleColumn/ElementsSection/Fire/Value
@onready var element_water = $VBox/MainContent/MiddleColumn/ElementsSection/Water/Value
@onready var element_earth = $VBox/MainContent/MiddleColumn/ElementsSection/Earth/Value
@onready var element_air = $VBox/MainContent/MiddleColumn/ElementsSection/Air/Value
@onready var element_light = $VBox/MainContent/MiddleColumn/ElementsSection/Light/Value
@onready var element_dark = $VBox/MainContent/MiddleColumn/ElementsSection/Dark/Value

# Информация аккаунта
@onready var info_nick = $VBox/MainContent/RightColumn/AccountInfo/Nick/Value
@onready var info_gender = $VBox/MainContent/RightColumn/AccountInfo/Gender/Value
@onready var info_element = $VBox/MainContent/RightColumn/AccountInfo/Element/Value
@onready var info_title = $VBox/MainContent/RightColumn/AccountInfo/Title/Value
@onready var info_guild = $VBox/MainContent/RightColumn/AccountInfo/Guild/Value
@onready var info_guild_emblem = $VBox/MainContent/RightColumn/AccountInfo/GuildEmblem/Value

# Статистика
@onready var stat_pvp_wins = $VBox/MainContent/RightColumn/StatsSection/PvpWins/Value
@onready var stat_monsters = $VBox/MainContent/RightColumn/StatsSection/Monsters/Value
@onready var stat_earned = $VBox/MainContent/RightColumn/StatsSection/Earned/Value
@onready var stat_bosses = $VBox/MainContent/RightColumn/StatsSection/Bosses/Value

var player_data = {}
var stat_points = 5

func _ready():
	close_btn.pressed.connect(_on_close)
	load_player_data()
	update_ui()
	btn_strength.pressed.connect(_on_strength_plus)
	btn_agility.pressed.connect(_on_agility_plus)
	btn_intuition.pressed.connect(_on_intuition_plus)
	btn_endurance.pressed.connect(_on_endurance_plus)
	btn_intellect.pressed.connect(_on_intellect_plus)
	btn_wisdom.pressed.connect(_on_wisdom_plus)
	btn_spirit.pressed.connect(_on_spirit_plus)

func load_player_data():
	if NetworkManager and NetworkManager.player_data:
		player_data = NetworkManager.player_data.duplicate()
		stat_points = player_data.get("stat_points", 5)
	else:
		player_data = {
			"name": "Игрок123",
			"level": 37,
			"gender": "Мужской",
			"element": "Огонь",
			"title": "Завоеватель",
			"guild": "Легион Света",
			"guild_emblem": "🛡️",
			"stat_points": 5,
			"stats": {
				"strength": 25,
				"agility": 50,
				"intuition": 10,
				"endurance": 75,
				"intellect": 30,
				"wisdom": 40,
				"spirit": 15
			},
			"elements": {
				"fire": 3,
				"water": 2,
				"earth": 4,
				"air": 1,
				"light": 0,
				"dark": 0
			},
			"stats_pvp": {
				"pvp_wins": 153,
				"monsters": 2847,
				"earned": 1500000,
				"bosses": 47
			}
		}

func update_ui():
	level_label.text = str(player_data.get("level", 1))
	stat_points_value.text = str(stat_points)
	var s = player_data["stats"]
	var max_hp = 200 + s["endurance"] * 5
	var max_mana = 100 + s["wisdom"] * 3
	hp_label.text = str(max_hp) + "/" + str(max_hp)
	mana_label.text = str(max_mana) + "/" + str(max_mana)
	
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
	passive_attack.text = str(100 + s["strength"] * 2)
	passive_defense.text = str(50 + s["endurance"])
	var hp = 200 + s["endurance"] * 5
	passive_hp.text = str(hp) + "/" + str(hp)
	var mana = 100 + s["wisdom"] * 3
	passive_mana.text = str(mana) + "/" + str(mana)
	passive_crit_chance.text = str(int(5 + s["agility"] * 0.5)) + "%"
	passive_crit_damage.text = str(150 + s["intuition"]) + "%"
	passive_evasion.text = str(int(5 + s["agility"] * 0.5)) + "%"
	passive_magic_find.text = str(int(5 + s["intuition"] * 0.3)) + "%"

func format_number(num: int) -> String:
	if num >= 1000000:
		return str(num / 1000000) + "M"
	elif num >= 1000:
		return str(num / 1000) + "K"
	return str(num)

func _on_strength_plus():
	if stat_points > 0:
		player_data["stats"]["strength"] += 1
		stat_points -= 1
		update_ui()

func _on_agility_plus():
	if stat_points > 0:
		player_data["stats"]["agility"] += 1
		stat_points -= 1
		update_ui()

func _on_intuition_plus():
	if stat_points > 0:
		player_data["stats"]["intuition"] += 1
		stat_points -= 1
		update_ui()

func _on_endurance_plus():
	if stat_points > 0:
		player_data["stats"]["endurance"] += 1
		stat_points -= 1
		update_ui()

func _on_intellect_plus():
	if stat_points > 0:
		player_data["stats"]["intellect"] += 1
		stat_points -= 1
		update_ui()

func _on_wisdom_plus():
	if stat_points > 0:
		player_data["stats"]["wisdom"] += 1
		stat_points -= 1
		update_ui()

func _on_spirit_plus():
	if stat_points > 0:
		player_data["stats"]["spirit"] += 1
		stat_points -= 1
		update_ui()

func _on_close():
	queue_free()
