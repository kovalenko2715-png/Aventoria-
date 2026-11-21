# res://main.gd (РАБОЧАЯ ВЕРСИЯ С ТАВЕРНОЙ, ГИЛЬДИЕЙ, ЗАДАНИЯМИ, КАРТОЙ, БОССАМИ И ПОЧТОЙ)
extends Control

# === УЗЛЫ ИНТЕРФЕЙСА ===
@onready var background = $Background
@onready var gold_text = $TopBar/TopContainer/Gold/GoldText
@onready var gold_label = $TopBar/TopContainer/Gold/GoldLabel
@onready var gold_icon = $TopBar/TopContainer/Gold/GoldIcon
@onready var player_name = $TopBar/TopContainer/PlayerName
@onready var game_logo = $TopBar/TopContainer/GameLogo
@onready var time_label = $TopBar/TopContainer/TimeLabel
@onready var rune_label = $TopBar/TopContainer/Rune/RuneLabel
@onready var rune_icon = $TopBar/TopContainer/Rune/RuneIcon
@onready var rune_text = $TopBar/TopContainer/Rune/RuneText
@onready var content = $Content
@onready var bottom_nav = $BottomNav
@onready var burger_btn = $BottomNav/BurgerBtn
@onready var guild_btn = $BottomNav/GuildBtn
@onready var tavern_btn = $BottomNav/TavernBtn
@onready var market_btn = $BottomNav/MarketBtn
@onready var boss_btn = $BottomNav/BossBtn
@onready var map_btn = $BottomNav/MapBtn
@onready var last_message = $BottomNav/LastMessage
@onready var chat_btn = $BottomNav/ChatBtn
@onready var online_text = $BottomNav/OnlineContainer/OnlineText
@onready var burger_menu = $BurgerMenu
@onready var profile_btn = $BurgerMenu/ProfileBtn
@onready var craft_btn = $BurgerMenu/CraftBtn
@onready var inventory_btn = $BurgerMenu/InventoryBtn
@onready var auction_btn = $BurgerMenu/AuctionBtn
@onready var quests_menu_btn = $BurgerMenu/QuestsBtn
@onready var mail_btn = $BurgerMenu/MailBtn
@onready var settings_btn = $BurgerMenu/SettingsBtn

# === ПЕРЕМЕННЫЕ ===
var music_tracks = [
	"res://assets/audio/menu1.mp3",
	"res://assets/audio/menu2.mp3",
	"res://assets/audio/menu.mp3"
]
var current_track_index = 0
var music_player
var chat_panel = null
var current_chat_tab = "general"
var messages_db = []
var my_nickname = ""
var last_online_players = []

var game_state = {
	"gold": 1000,
	"rune": 50,
	"player_name": "",
	"online": 0
}

# === ЦВЕТА ДЛЯ РАЗДЕЛОВ ===
const COLOR_GENERAL = Color(1, 1, 1)
const COLOR_TRADE = Color(0.27, 1, 0.27)
const COLOR_GUILD = Color(1, 0.6, 0)
const COLOR_SYSTEM = Color(1, 0.27, 0.27)

# === ОКНА МОДУЛЕЙ ===
var settings_window = null
var profile_window = null
var inventory_window = null
var market_window = null
var auction_window = null
var tavern_window = null
var guild_window = null
var my_quests_window = null
var map_window = null
var bosses_window = null
var mail_window = null
var player_menu = null

func _ready():
	print("🎮 Главный экран загружен")
	
	if NetworkManager.player_data:
		game_state.player_name = NetworkManager.player_data.get("name", "Игрок")
		game_state.gold = NetworkManager.player_data.get("gold", 1000)
		game_state.rune = NetworkManager.player_data.get("rune", 50)
		my_nickname = game_state.player_name
		print("   ник игрока: ", my_nickname)
	
	load_icons()
	setup_colors()
	set_background_by_time()
	setup_timers()
	setup_signals()
	update_ui()
	setup_background_music()
	animate_gold_glow()
	animate_rune_glow()
	animate_rune_text_vip()
	adjust_burger_buttons()
	
	NetworkManager.data_received.connect(_on_network_data)
	NetworkManager.player_data_updated.connect(_on_player_data_updated)
	
	if NetworkManager.current_mode == "local" and my_nickname != "":
		game_state.online = 1
		last_online_players = [my_nickname]
		update_ui()
		print("🟢 Локальный онлайн установлен: 1")
	
	apply_settings()

func apply_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	
	if music_player:
		var music_enabled = config.get_value("audio", "music_enabled", true)
		var music_volume = config.get_value("audio", "music_volume", 80)
		apply_audio_settings(music_enabled, music_volume)
	
	var font_size_value = config.get_value("chat", "font_size", "medium")
	apply_chat_font_size(font_size_value)

func load_icons():
	if gold_icon:
		var tex = load("res://assets/images/ui/gold_icon.png")
		if tex:
			gold_icon.texture = tex
	
	if rune_icon:
		var tex = load("res://assets/images/ui/rune_icon.png")
		if tex:
			rune_icon.texture = tex

func animate_gold_glow():
	var elements = [gold_icon, gold_label, gold_text]
	for element in elements:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(element, "modulate", Color(1, 0.9, 0.4, 1), 1.2)
		tween.tween_property(element, "modulate", Color(1, 0.8, 0.2, 1), 1.2)

func animate_rune_glow():
	var elements = [rune_icon, rune_label]
	for element in elements:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(element, "modulate", Color(0.7, 1, 1, 1), 1.5)
		tween.tween_property(element, "modulate", Color(0.4, 0.7, 1, 1), 1.5)

func animate_rune_text_vip():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(rune_text, "modulate", Color(0.9, 0.9, 1, 1), 0.6)
	tween.tween_property(rune_text, "modulate", Color(0.4, 0.7, 1, 1), 0.6)
	tween.tween_property(rune_text, "modulate", Color(0.7, 1, 1, 1), 0.6)

func set_background_by_time():
	var time = Time.get_time_dict_from_system()
	if time.hour >= 6 and time.hour < 18:
		var tex = load("res://assets/images/day1.png")
		if tex:
			background.texture = tex
	else:
		var tex = load("res://assets/images/day2.png")
		if tex:
			background.texture = tex

func setup_timers():
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(update_time)
	add_child(timer)
	timer.start()
	update_time()

func update_time():
	if not time_label:
		return
	var t = Time.get_time_dict_from_system()
	time_label.text = "%02d:%02d" % [t.hour, t.minute]

func update_ui():
	if gold_label:
		gold_label.text = str(game_state.gold)
	if player_name:
		player_name.text = game_state.player_name
	if rune_label:
		rune_label.text = str(game_state.rune)
	if online_text:
		online_text.text = "Онлайн " + str(game_state.online)

func adjust_burger_buttons():
	var buttons = [profile_btn, craft_btn, inventory_btn, auction_btn, quests_menu_btn, mail_btn, settings_btn]
	for btn in buttons:
		if btn:
			btn.custom_minimum_size.x = 100

func setup_colors():
	if gold_text:
		gold_text.add_theme_color_override("font_color", Color(1, 0.84, 0))
	if gold_label:
		gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	if rune_text:
		rune_text.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	if rune_label:
		rune_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	if online_text:
		online_text.add_theme_color_override("font_color", Color(1, 0.84, 0))

func setup_background_music():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_next_track)
	_next_track()

func _next_track():
	current_track_index = (current_track_index + 1) % music_tracks.size()
	var s = load(music_tracks[current_track_index])
	if s:
		music_player.stream = s
		music_player.play()

func update_last_message(sender: String, text: String, tab: String):
	if not last_message:
		return
	
	var display_sender = "Вы" if sender == my_nickname else sender
	var full_text = display_sender + ": " + text
	last_message.text = full_text
	
	match tab:
		"trade":
			last_message.add_theme_color_override("font_color", COLOR_TRADE)
		"guild":
			last_message.add_theme_color_override("font_color", COLOR_GUILD)
		"system":
			last_message.add_theme_color_override("font_color", COLOR_SYSTEM)
		_:
			last_message.add_theme_color_override("font_color", COLOR_GENERAL)

func refresh_chat_messages():
	if not chat_panel:
		return
	
	var messages_list = chat_panel.find_child("MessagesList", true, false)
	if not messages_list:
		return
	
	for child in messages_list.get_children():
		child.queue_free()
	
	for msg in messages_db:
		if current_chat_tab == "general" or msg.tab == current_chat_tab:
			var msg_label = Label.new()
			var display_sender = "Вы" if msg.sender == my_nickname else msg.sender
			msg_label.text = display_sender + ": " + msg.text
			msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			msg_label.mouse_filter = Control.MOUSE_FILTER_STOP
			msg_label.gui_input.connect(_on_message_click.bind(msg.sender))
			
			match msg.tab:
				"trade":
					msg_label.add_theme_color_override("font_color", COLOR_TRADE)
				"guild":
					msg_label.add_theme_color_override("font_color", COLOR_GUILD)
				"system":
					msg_label.add_theme_color_override("font_color", COLOR_SYSTEM)
				_:
					msg_label.add_theme_color_override("font_color", COLOR_GENERAL)
			
			messages_list.add_child(msg_label)

func _on_message_click(event: InputEvent, sender: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if sender != my_nickname:
			show_player_menu(sender, get_global_mouse_position())

func update_online_list(players: Array):
	last_online_players = players.duplicate()
	
	if not chat_panel:
		print("⚠️ chat_panel нет, список сохранён")
		return
	
	var players_list = chat_panel.find_child("PlayersList", true, false)
	if not players_list:
		print("⚠️ players_list не найден")
		return
	
	print("🔄 Обновление списка онлайн: ", players)
	
	for child in players_list.get_children():
		child.queue_free()
	
	for player in players:
		if player == my_nickname:
			player = "👤 " + player + " (Вы)"
		
		var label = Label.new()
		label.text = "• " + player
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.gui_input.connect(_on_player_click.bind(player.replace("👤 ", "").replace(" (Вы)", "")))
		players_list.add_child(label)

func _on_player_click(event: InputEvent, player: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player != my_nickname:
			show_player_menu(player, get_global_mouse_position())

func show_player_menu(player: String, mouse_pos: Vector2):
	if player_menu and is_instance_valid(player_menu):
		player_menu.queue_free()
	
	player_menu = Panel.new()
	player_menu.name = "PlayerMenu"
	player_menu.position = mouse_pos
	player_menu.size = Vector2(200, 120)
	add_child(player_menu)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(1, 1, 1, 0.2)
	style.border_width_all = 1
	style.corner_radius_all = 5
	player_menu.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_top = 0.0
	vbox.anchor_bottom = 1.0
	player_menu.add_child(vbox)
	
	var write_btn = Button.new()
	write_btn.text = "💬 Написать"
	write_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	write_btn.pressed.connect(_on_write_to_player.bind(player))
	vbox.add_child(write_btn)
	
	var profile_btn_local = Button.new()
	profile_btn_local.text = "👤 Профиль"
	profile_btn_local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_btn_local.pressed.connect(_on_player_profile.bind(player))
	vbox.add_child(profile_btn_local)
	
	var gift_btn = Button.new()
	gift_btn.text = "🎁 Подарок"
	gift_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gift_btn.pressed.connect(_on_player_gift.bind(player))
	vbox.add_child(gift_btn)
	
	var overlay = ColorRect.new()
	overlay.name = "MenuOverlay"
	overlay.color = Color(0, 0, 0, 0)
	overlay.anchor_left = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_top = 0.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_overlay_click)
	add_child(overlay)
	
	player_menu.tree_exited.connect(func(): if is_instance_valid(overlay): overlay.queue_free())

func _on_overlay_click(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if player_menu and is_instance_valid(player_menu):
			player_menu.queue_free()

func _on_write_to_player(player: String):
	if chat_panel:
		var input_field = chat_panel.find_child("ChatInputField", true, false)
		if input_field:
			input_field.text = "/w " + player + " "
			input_field.grab_focus()
	
	if player_menu and is_instance_valid(player_menu):
		player_menu.queue_free()

func _on_player_profile(player: String):
	print("👤 Профиль игрока ", player, " (заглушка)")
	show_info_dialog("Профиль игрока", "Функция просмотра профиля будет доступна позже")
	if player_menu and is_instance_valid(player_menu):
		player_menu.queue_free()

func _on_player_gift(player: String):
	print("🎁 Подарок для ", player, " (заглушка)")
	show_info_dialog("Подарок", "Функция отправки подарков будет доступна позже")
	if player_menu and is_instance_valid(player_menu):
		player_menu.queue_free()

func show_info_dialog(title: String, message: String):
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(dialog):
		dialog.queue_free()

func _on_network_data(data: String):
	print("📩 Данные от сервера: ", data)
	var parts = data.split("|")
	
	match parts[0]:
		"CHAT_MSG":
			var sender = parts[1]
			var tab = parts[2]
			var text = parts[3]
			messages_db.append({"sender": sender, "text": text, "tab": tab})
			update_last_message(sender, text, tab)
			if chat_panel and chat_panel.visible:
				refresh_chat_messages()
		
		"ONLINE_UPDATE":
			var count = int(parts[1])
			game_state.online = count
			update_ui()
			print("🟢 ONLINE_UPDATE получен, count = ", count)
			
			if parts.size() > 2 and parts[2] != "":
				var players = parts[2].split(",")
				print("   игроки: ", players)
				update_online_list(players)
			else:
				print("   список игроков пуст")
				update_online_list([])

func setup_signals():
	if chat_btn:
		chat_btn.pressed.connect(_expand_chat)
	if burger_btn:
		burger_btn.pressed.connect(_toggle_burger)
	if guild_btn:
		guild_btn.pressed.connect(open_guild)
	if tavern_btn:
		tavern_btn.pressed.connect(open_tavern)
	if market_btn:
		market_btn.pressed.connect(open_market)
	if boss_btn:
		boss_btn.pressed.connect(open_bosses)
	if map_btn:
		map_btn.pressed.connect(open_map)
	if profile_btn:
		profile_btn.pressed.connect(open_profile)
	if craft_btn:
		craft_btn.pressed.connect(func(): open_module("craft"))
	if inventory_btn:
		inventory_btn.pressed.connect(open_inventory)
	if auction_btn:
		auction_btn.pressed.connect(open_auction)
	if quests_menu_btn:
		quests_menu_btn.pressed.connect(open_my_quests)
	if mail_btn:
		mail_btn.pressed.connect(open_mail)
	if settings_btn:
		settings_btn.pressed.connect(open_settings)

# === ФУНКЦИИ ОТКРЫТИЯ ОКОН ===
func open_profile():
	if profile_window and is_instance_valid(profile_window):
		profile_window.visible = true
		profile_window.move_to_front()
		return
	
	profile_window = load("res://modules/profile.gd").new()
	add_child(profile_window)
	profile_window.tree_exited.connect(_on_profile_closed)

func _on_profile_closed():
	profile_window = null
	print("👤 Окно профиля закрыто")

func open_inventory():
	if inventory_window and is_instance_valid(inventory_window):
		inventory_window.visible = true
		inventory_window.move_to_front()
		return
	
	inventory_window = load("res://modules/inventory.gd").new()
	add_child(inventory_window)
	inventory_window.tree_exited.connect(_on_inventory_closed)

func _on_inventory_closed():
	inventory_window = null
	print("🧰 Окно инвентаря закрыто")

func open_market():
	if market_window and is_instance_valid(market_window):
		market_window.visible = true
		market_window.move_to_front()
		return
	
	market_window = load("res://modules/market.gd").new()
	add_child(market_window)
	market_window.tree_exited.connect(_on_market_closed)

func _on_market_closed():
	market_window = null
	print("🏪 Окно лавки закрыто")

func open_auction():
	if auction_window and is_instance_valid(auction_window):
		auction_window.visible = true
		auction_window.move_to_front()
		return
	
	auction_window = load("res://modules/auction.gd").new()
	add_child(auction_window)
	auction_window.tree_exited.connect(_on_auction_closed)

func _on_auction_closed():
	auction_window = null
	print("📦 Окно аукциона закрыто")

func open_tavern():
	if tavern_window and is_instance_valid(tavern_window):
		tavern_window.visible = true
		tavern_window.move_to_front()
		return
	
	tavern_window = load("res://modules/tavern.gd").new()
	add_child(tavern_window)
	tavern_window.tree_exited.connect(_on_tavern_closed)

func _on_tavern_closed():
	tavern_window = null
	print("🍺 Окно таверны закрыто")

func open_guild():
	if guild_window and is_instance_valid(guild_window):
		guild_window.visible = true
		guild_window.move_to_front()
		return
	
	guild_window = load("res://modules/guild.gd").new()
	add_child(guild_window)
	guild_window.tree_exited.connect(_on_guild_closed)

func _on_guild_closed():
	guild_window = null
	print("🏰 Окно гильдии закрыто")

func open_my_quests():
	if my_quests_window and is_instance_valid(my_quests_window):
		my_quests_window.visible = true
		my_quests_window.move_to_front()
		return
	
	my_quests_window = load("res://modules/my_quests.gd").new()
	add_child(my_quests_window)
	my_quests_window.tree_exited.connect(_on_my_quests_closed)

func _on_my_quests_closed():
	my_quests_window = null
	print("📋 Окно моих заданий закрыто")

func open_map():
	if map_window and is_instance_valid(map_window):
		map_window.visible = true
		map_window.move_to_front()
		return
	
	map_window = load("res://modules/map.gd").new()
	add_child(map_window)
	map_window.tree_exited.connect(_on_map_closed)

func _on_map_closed():
	map_window = null
	print("🗺️ Окно карты закрыто")

func open_bosses():
	if bosses_window and is_instance_valid(bosses_window):
		bosses_window.visible = true
		bosses_window.move_to_front()
		return
	
	bosses_window = load("res://modules/bosses.gd").new()
	add_child(bosses_window)
	bosses_window.tree_exited.connect(_on_bosses_closed)

func _on_bosses_closed():
	bosses_window = null
	print("👑 Окно боссов закрыто")

func open_mail():
	if mail_window and is_instance_valid(mail_window):
		mail_window.visible = true
		mail_window.move_to_front()
		return
	
	mail_window = load("res://modules/mail.gd").new()
	add_child(mail_window)
	mail_window.tree_exited.connect(_on_mail_closed)

func _on_mail_closed():
	mail_window = null
	print("📧 Окно почты закрыто")

func open_settings():
	if settings_window and is_instance_valid(settings_window):
		settings_window.visible = true
		settings_window.move_to_front()
		return
	
	settings_window = load("res://modules/settings.tscn").instantiate()
	add_child(settings_window)
	settings_window.tree_exited.connect(_on_settings_closed)

func _on_settings_closed():
	settings_window = null
	print("⚙️ Окно настроек закрыто")

# === ОБРАБОТЧИК ОБНОВЛЕНИЯ ДАННЫХ ===
func _on_player_data_updated(new_data: Dictionary):
	print("🔄 Обновление данных игрока в главном экране")
	NetworkManager.player_data = new_data.duplicate()
	
	game_state.gold = new_data.get("gold", game_state.gold)
	game_state.rune = new_data.get("rune", game_state.rune)
	game_state.player_name = new_data.get("name", game_state.player_name)
	
	update_ui()
	print("💰 Золото обновлено: ", game_state.gold)

# === ОСТАЛЬНЫЕ ФУНКЦИИ ===
func apply_audio_settings(enabled: bool, volume: float):
	if not music_player:
		return
	
	if enabled:
		music_player.volume_db = linear_to_db(volume / 100.0)
	else:
		music_player.volume_db = -80
	
	print("🔊 Громкость музыки: ", volume, " Вкл: ", enabled)

func apply_chat_font_size(font_size_val: String):
	var font_sizes = {
		"small": 10,
		"medium": 12,
		"large": 14
	}
	
	var new_size = font_sizes.get(font_size_val, 12)
	
	if chat_panel:
		var messages_list = chat_panel.find_child("MessagesList", true, false)
		if messages_list:
			for msg in messages_list.get_children():
				if msg is Label:
					msg.add_theme_font_size_override("font_size", new_size)
	
	print("📏 Размер шрифта чата: ", font_size_val)

func _expand_chat():
	if chat_panel and is_instance_valid(chat_panel):
		chat_panel.visible = true
		refresh_chat_messages()
		if last_online_players.size() > 0:
			update_online_list(last_online_players)
		return
	
	chat_panel = Panel.new()
	chat_panel.name = "ChatPanel"
	chat_panel.anchor_left = 0.2
	chat_panel.anchor_right = 0.8
	chat_panel.anchor_top = 0.15
	chat_panel.anchor_bottom = 0.8
	add_child(chat_panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(1, 1, 1, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	chat_panel.add_theme_stylebox_override("panel", style)
	
	var tabs_panel = HBoxContainer.new()
	tabs_panel.name = "TabsPanel"
	tabs_panel.anchor_left = 0.0
	tabs_panel.anchor_right = 1.0
	tabs_panel.anchor_top = 0.0
	tabs_panel.anchor_bottom = 0.07
	tabs_panel.alignment = BoxContainer.ALIGNMENT_END
	chat_panel.add_child(tabs_panel)
	
	var tabs = HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_panel.add_child(tabs)
	
	var general_tab = Button.new()
	general_tab.name = "GeneralTab"
	general_tab.text = "Общий"
	general_tab.add_theme_color_override("font_color", COLOR_GENERAL)
	tabs.add_child(general_tab)
	general_tab.pressed.connect(func(): switch_chat_tab("general"))
	
	var trade_tab = Button.new()
	trade_tab.name = "TradeTab"
	trade_tab.text = "Торговля"
	trade_tab.add_theme_color_override("font_color", COLOR_TRADE)
	tabs.add_child(trade_tab)
	trade_tab.pressed.connect(func(): switch_chat_tab("trade"))
	
	var guild_tab = Button.new()
	guild_tab.name = "GuildTab"
	guild_tab.text = "Гильдия"
	guild_tab.add_theme_color_override("font_color", COLOR_GUILD)
	tabs.add_child(guild_tab)
	guild_tab.pressed.connect(func(): switch_chat_tab("guild"))
	
	var system_tab = Button.new()
	system_tab.name = "SystemTab"
	system_tab.text = "Система"
	system_tab.add_theme_color_override("font_color", COLOR_SYSTEM)
	tabs.add_child(system_tab)
	system_tab.pressed.connect(func(): switch_chat_tab("system"))
	
	var close_btn_chat = Button.new()
	close_btn_chat.name = "CloseChatBtn"
	close_btn_chat.text = "×"
	close_btn_chat.custom_minimum_size.x = 40
	close_btn_chat.custom_minimum_size.y = 30
	tabs_panel.add_child(close_btn_chat)
	close_btn_chat.pressed.connect(_close_chat)
	
	var chat_area = HBoxContainer.new()
	chat_area.name = "ChatArea"
	chat_area.anchor_left = 0.0
	chat_area.anchor_right = 1.0
	chat_area.anchor_top = 0.07
	chat_area.anchor_bottom = 0.93
	chat_panel.add_child(chat_area)
	
	var messages_container = VBoxContainer.new()
	messages_container.name = "MessagesContainer"
	messages_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_area.add_child(messages_container)
	
	var messages_scroll = ScrollContainer.new()
	messages_scroll.name = "MessagesScroll"
	messages_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	messages_container.add_child(messages_scroll)
	
	var messages_list = VBoxContainer.new()
	messages_list.name = "MessagesList"
	messages_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages_scroll.add_child(messages_list)
	
	var players_container = VBoxContainer.new()
	players_container.name = "PlayersContainer"
	players_container.custom_minimum_size.x = 180
	players_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_area.add_child(players_container)
	
	var players_label = Label.new()
	players_label.name = "PlayersLabel"
	players_label.text = "Игроки онлайн"
	players_label.add_theme_color_override("font_color", Color(1, 1, 1))
	players_label.horizontal_alignment = 1
	players_container.add_child(players_label)
	
	var players_scroll = ScrollContainer.new()
	players_scroll.name = "PlayersScroll"
	players_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	players_container.add_child(players_scroll)
	
	var players_list = VBoxContainer.new()
	players_list.name = "PlayersList"
	players_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	players_scroll.add_child(players_list)
	
	var input_row = HBoxContainer.new()
	input_row.name = "InputRow"
	input_row.anchor_left = 0.0
	input_row.anchor_right = 1.0
	input_row.anchor_top = 0.93
	input_row.anchor_bottom = 1.0
	input_row.alignment = BoxContainer.ALIGNMENT_CENTER
	chat_panel.add_child(input_row)
	
	var chat_input_field = LineEdit.new()
	chat_input_field.name = "ChatInputField"
	chat_input_field.placeholder_text = "Введите сообщение..."
	chat_input_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input_field.custom_minimum_size.y = 30
	input_row.add_child(chat_input_field)
	
	var send_msg_btn = Button.new()
	send_msg_btn.name = "SendMsgBtn"
	send_msg_btn.text = "Отправить"
	send_msg_btn.custom_minimum_size.x = 80
	send_msg_btn.custom_minimum_size.y = 30
	input_row.add_child(send_msg_btn)
	send_msg_btn.pressed.connect(_send_chat_message.bind(chat_input_field))
	
	if last_online_players.size() > 0:
		update_online_list(last_online_players)
	
	switch_chat_tab("general")
	
	print("📢 Чат развёрнут")

func _send_chat_message(input_field: LineEdit):
	var text = input_field.text.strip_edges()
	if text == "":
		return
	
	if text.begins_with("/w "):
		var parts = text.split(" ", true, 2)
		if parts.size() >= 3:
			var target = parts[1]
			var msg = parts[2]
			print("💌 Личное сообщение для ", target, ": ", msg)
			messages_db.append({"sender": "Вы -> " + target, "text": msg, "tab": current_chat_tab})
			update_last_message("Вы -> " + target, msg, current_chat_tab)
			if chat_panel and chat_panel.visible:
				refresh_chat_messages()
			input_field.text = ""
			return
	
	NetworkManager.send_chat_message(current_chat_tab, text)
	input_field.text = ""

# === ФУНКЦИИ УПРАВЛЕНИЯ ===
func _toggle_burger():
	if burger_menu:
		burger_menu.visible = not burger_menu.visible

func open_module(module_name: String):
	print("📂 Открываем модуль: ", module_name)
	if not content:
		return
	for c in content.get_children():
		c.queue_free()
	var label = Label.new()
	label.text = module_name.to_upper() + "\n(в разработке)"
	label.horizontal_alignment = 1
	label.vertical_alignment = 1
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_font_size_override("font_size", 24)
	content.add_child(label)
	if burger_menu and burger_menu.visible:
		_toggle_burger()

func switch_chat_tab(tab_name: String):
	current_chat_tab = tab_name
	print("📌 Переключено на вкладку: ", tab_name)
	if chat_panel and chat_panel.visible:
		refresh_chat_messages()

func _close_chat():
	if chat_panel and is_instance_valid(chat_panel):
		chat_panel.visible = false
		print("📢 Чат свёрнут")
