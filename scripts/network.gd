# res://network.gd
extends Node

signal connected_to_server
signal connection_failed
signal auth_required
signal data_received(data)
signal login_result(success, message)
signal register_result(success, message)
signal player_data_updated(new_data)

var socket = WebSocketPeer.new()
var connection_established = false
var current_mode = "local"
var player_data = {}
var online_players = []

func connect_to_server(address: String):
	current_mode = "local" if address == "1111" else "server"
	
	if current_mode == "local":
		print("🎮 Локальный режим")
		connection_established = true
		connected_to_server.emit()
		auth_required.emit()
		return
	
	var url = "ws://" + address
	var err = socket.connect_to_url(url)
	if err != OK:
		connection_failed.emit()

func _process(_delta):
	if current_mode != "server": return
	
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN and not connection_established:
		connection_established = true
		auth_required.emit()
	
	while socket.get_available_packet_count():
		var packet = socket.get_packet().get_string_from_utf8()
		handle_server_response(packet)

func handle_server_response(response: String):
	print("📩 Ответ сервера: ", response)
	data_received.emit(response)
	
	var parts = response.split("|")
	var cmd = parts[0]
	
	match cmd:
		"LOGIN_OK":
			player_data = {
				"name": parts[1],
				"gold": int(parts[2]),
				"rune": int(parts[3]),
				"stat_points": int(parts[4]) if parts.size() > 4 else 15,
				"level": int(parts[5]) if parts.size() > 5 else 1,
				"gender": parts[6] if parts.size() > 6 else "Не указан",
				"element": parts[7] if parts.size() > 7 else "—",
				"title": parts[8] if parts.size() > 8 else "—",
				"guild": parts[9] if parts.size() > 9 else "—",
				"guild_emblem": parts[10] if parts.size() > 10 else "—",
				"stats": {
					"strength": int(parts[11]) if parts.size() > 11 else 0,
					"agility": int(parts[12]) if parts.size() > 12 else 0,
					"intuition": int(parts[13]) if parts.size() > 13 else 0,
					"endurance": int(parts[14]) if parts.size() > 14 else 0,
					"intellect": int(parts[15]) if parts.size() > 15 else 0,
					"wisdom": int(parts[16]) if parts.size() > 16 else 0,
					"spirit": int(parts[17]) if parts.size() > 17 else 0
				},
				"elements": {
					"fire": int(parts[18]) if parts.size() > 18 else 0,
					"water": int(parts[19]) if parts.size() > 19 else 0,
					"earth": int(parts[20]) if parts.size() > 20 else 0,
					"air": int(parts[21]) if parts.size() > 21 else 0,
					"light": int(parts[22]) if parts.size() > 22 else 0,
					"dark": int(parts[23]) if parts.size() > 23 else 0
				},
				"stats_pvp": {
					"pvp_wins": int(parts[24]) if parts.size() > 24 else 0,
					"monsters": int(parts[25]) if parts.size() > 25 else 0,
					"earned": int(parts[26]) if parts.size() > 26 else 0,
					"bosses": int(parts[27]) if parts.size() > 27 else 0
				},
				"inventory": [],
				"equipment": {},
				"quick_slots": [null, null, null, null],
				"guild_quest_points": 0,
				"personal_storage": []
			}
			login_result.emit(true, "Успешный вход")
			player_data_updated.emit(player_data)
			
		"LOGIN_FAIL":
			login_result.emit(false, parts[1])
			
		"REG_OK":
			register_result.emit(true, "Регистрация успешна")
			
		"REG_FAIL":
			register_result.emit(false, parts[1])
			
		"CHAT_MSG":
			var sender = parts[1]
			var tab = parts[2]
			var text = parts[3]
			data_received.emit("CHAT_MSG|%s|%s|%s" % [sender, tab, text])
			
		"ONLINE_UPDATE":
			var count = int(parts[1])
			var players = parts[2].split(",") if parts.size() > 2 and parts[2] != "" else []
			online_players = players
			data_received.emit("ONLINE_UPDATE|%s|%s" % [count, ",".join(players)])
			
		"PLAYER_JOIN":
			var player_name = parts[1]
			if not player_name in online_players:
				online_players.append(player_name)
			data_received.emit("ONLINE_UPDATE|%s|%s" % [online_players.size(), ",".join(online_players)])
			
		"PLAYER_LEFT":
			var player_name = parts[1]
			online_players.erase(player_name)
			data_received.emit("ONLINE_UPDATE|%s|%s" % [online_players.size(), ",".join(online_players)])
		
		"STAT_UPDATE_OK":
			data_received.emit("STAT_UPDATE_OK|" + parts[1])
		
		"STAT_UPDATE_FAIL":
			data_received.emit("STAT_UPDATE_FAIL|" + parts[1])
		
		"INVENTORY_UPDATE_OK":
			data_received.emit("INVENTORY_UPDATE_OK")
		
		"INVENTORY_UPDATE_FAIL":
			data_received.emit("INVENTORY_UPDATE_FAIL")
		
		"PLAYER_DATA":
			var json_string = parts[1]
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				player_data = json.data
				player_data_updated.emit(player_data)
			else:
				print("❌ Ошибка парсинга PLAYER_DATA")
		
		"GUILD_QUESTS":
			var json_str = parts[1]
			var json = JSON.new()
			if json.parse(json_str) == OK:
				player_data["guild_quests"] = json.data
			data_received.emit("GUILD_QUESTS|" + json_str)
		
		"GUILD_STORAGE":
			var json_str = parts[1]
			var json = JSON.new()
			if json.parse(json_str) == OK:
				player_data["personal_storage"] = json.data
			data_received.emit("GUILD_STORAGE|" + json_str)
		
		"GUILD_POINTS":
			var points = int(parts[1])
			player_data["guild_quest_points"] = points
			data_received.emit("GUILD_POINTS|" + str(points))
		
		"GUILD_QUEST_TAKE_OK":
			data_received.emit("GUILD_QUEST_TAKE_OK|" + parts[1])
		
		"GUILD_QUEST_TAKE_FAIL":
			data_received.emit("GUILD_QUEST_TAKE_FAIL|" + parts[1])
		
		"GUILD_QUEST_COMPLETE_OK":
			data_received.emit("GUILD_QUEST_COMPLETE_OK|" + parts[1])
		
		"GUILD_QUEST_COMPLETE_FAIL":
			data_received.emit("GUILD_QUEST_COMPLETE_FAIL|" + parts[1])
		
		"GUILD_STORAGE_PUT_OK":
			data_received.emit("GUILD_STORAGE_PUT_OK")
		
		"GUILD_STORAGE_PUT_FAIL":
			data_received.emit("GUILD_STORAGE_PUT_FAIL")
		
		"GUILD_STORAGE_TAKE_OK":
			data_received.emit("GUILD_STORAGE_TAKE_OK")
		
		"GUILD_STORAGE_TAKE_FAIL":
			data_received.emit("GUILD_STORAGE_TAKE_FAIL")

func send_login(login: String, password: String):
	if current_mode == "local":
		var file = FileAccess.open("user://players.dat", FileAccess.READ)
		var players = {}
		if file:
			players = file.get_var()
			file.close()
		
		if players.has(login):
			if players[login]["password"] == password:
				player_data = players[login].duplicate()
				if not player_data.has("level"): player_data["level"] = 1
				if not player_data.has("gender"): player_data["gender"] = "Не указан"
				if not player_data.has("element"): player_data["element"] = "—"
				if not player_data.has("title"): player_data["title"] = "—"
				if not player_data.has("guild"): player_data["guild"] = "—"
				if not player_data.has("guild_emblem"): player_data["guild_emblem"] = "—"
				if not player_data.has("stat_points"): player_data["stat_points"] = 15
				if not player_data.has("stats"): player_data["stats"] = { "strength":0, "agility":0, "intuition":0, "endurance":0, "intellect":0, "wisdom":0, "spirit":0 }
				if not player_data.has("elements"): player_data["elements"] = { "fire":0, "water":0, "earth":0, "air":0, "light":0, "dark":0 }
				if not player_data.has("stats_pvp"): player_data["stats_pvp"] = { "pvp_wins":0, "monsters":0, "earned":0, "bosses":0 }
				if not player_data.has("inventory"): player_data["inventory"] = []
				if not player_data.has("equipment"): player_data["equipment"] = {}
				if not player_data.has("quick_slots"): player_data["quick_slots"] = [null, null, null, null]
				if not player_data.has("guild_quest_points"): player_data["guild_quest_points"] = 0
				if not player_data.has("personal_storage"): player_data["personal_storage"] = []
				
				online_players = [login]
				data_received.emit("ONLINE_UPDATE|1|%s" % login)
				login_result.emit(true, "Успешный вход")
				player_data_updated.emit(player_data)
			else:
				login_result.emit(false, "Неверный пароль")
		else:
			login_result.emit(false, "Аккаунт не найден")
		return
	
	var msg = "LOGIN|%s|%s" % [login, password]
	send(msg)

func send_register(login: String, password: String):
	if current_mode == "local":
		var file = FileAccess.open("user://players.dat", FileAccess.READ)
		var players = {}
		if file:
			players = file.get_var()
			file.close()
		
		if players.has(login):
			register_result.emit(false, "Логин уже занят")
			return
		
		players[login] = {
			"password": password,
			"name": login,
			"gold": 1000,
			"rune": 50,
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
			},
			"inventory": [],
			"equipment": {},
			"quick_slots": [null, null, null, null],
			"guild_quest_points": 0,
			"personal_storage": []
		}
		
		file = FileAccess.open("user://players.dat", FileAccess.WRITE)
		file.store_var(players)
		file.close()
		
		player_data = players[login].duplicate()
		online_players = [login]
		data_received.emit("ONLINE_UPDATE|1|%s" % login)
		
		register_result.emit(true, "Регистрация успешна")
		player_data_updated.emit(player_data)
		return
	
	var msg = "REG|%s|%s" % [login, password]
	send(msg)

func send_chat_message(tab: String, text: String):
	if current_mode == "local":
		var sender_name = player_data.get("name", "Игрок")
		data_received.emit("CHAT_MSG|%s|%s|%s" % [sender_name, tab, text])
		return
	
	var msg = "CHAT|%s|%s" % [tab, text]
	send(msg)

func send_stat_update(stat_name: String, new_value: int, stat_points_left: int):
	var msg = "STAT_UPDATE|%s|%d|%d" % [stat_name, new_value, stat_points_left]
	send(msg)

func save_local_data():
	if current_mode != "local":
		return
	var login = player_data.get("name")
	if login == null or login == "":
		return
	var file = FileAccess.open("user://players.dat", FileAccess.READ)
	var players = {}
	if file:
		players = file.get_var()
		file.close()
	if players.has(login):
		players[login] = player_data.duplicate()
		file = FileAccess.open("user://players.dat", FileAccess.WRITE)
		file.store_var(players)
		file.close()

func send(data: String):
	if current_mode == "local":
		print("📤 Локально: ", data)
		if data.begins_with("STAT_UPDATE|"):
			var parts = data.split("|")
			if parts.size() >= 4:
				var stat = parts[1]
				var value = int(parts[2])
				var points = int(parts[3])
				if player_data.has("stats") and player_data["stats"].has(stat):
					player_data["stats"][stat] = value
					player_data["stat_points"] = points
					save_local_data()
					data_received.emit("STAT_UPDATE_OK|" + stat)
					player_data_updated.emit(player_data)
		elif data.begins_with("INVENTORY_UPDATE|"):
			var parts = data.split("|")
			if parts.size() >= 2:
				var json = JSON.new()
				var error = json.parse(parts[1])
				if error == OK:
					var inv_data = json.data
					if inv_data.has("inventory"):
						player_data["inventory"] = inv_data["inventory"]
					if inv_data.has("equipment"):
						player_data["equipment"] = inv_data["equipment"]
					if inv_data.has("quick_slots"):
						player_data["quick_slots"] = inv_data["quick_slots"]
					save_local_data()
					data_received.emit("INVENTORY_UPDATE_OK")
					player_data_updated.emit(player_data)
				else:
					data_received.emit("INVENTORY_UPDATE_FAIL")
		elif data.begins_with("PLAYER_DATA_UPDATE|"):
			var parts = data.split("|")
			if parts.size() >= 2:
				var json = JSON.new()
				var error = json.parse(parts[1])
				if error == OK:
					player_data = json.data
					save_local_data()
					data_received.emit("PLAYER_DATA_UPDATE_OK")
					player_data_updated.emit(player_data)
				else:
					data_received.emit("PLAYER_DATA_UPDATE_FAIL")
		return
	
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(data)
		print("📤 Отправлено: ", data)

func send_get_guild_quests():
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("GET_GUILD_QUESTS")

func send_take_guild_quest(quest_id: String):
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("TAKE_GUILD_QUEST|" + quest_id)

func send_complete_guild_quest(quest_id: String):
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("COMPLETE_GUILD_QUEST|" + quest_id)

func send_get_guild_storage():
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("GET_GUILD_STORAGE")

func send_put_guild_storage(item_id: String, quantity: int):
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("PUT_GUILD_STORAGE|" + item_id + "|" + str(quantity))

func send_take_guild_storage(slot: int):
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("TAKE_GUILD_STORAGE|" + str(slot))

func send_get_guild_points():
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("GET_GUILD_POINTS")

func send_add_guild_points(amount: int):
	if current_mode == "local":
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send("ADD_GUILD_POINTS|" + str(amount))
