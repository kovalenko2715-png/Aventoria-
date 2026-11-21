extends Control

@onready var logo = $Logo
@onready var conn_panel = $ConnectionPanel
@onready var auth_panel = $AuthPanel

@onready var server_input = $ConnectionPanel/ServerInput
@onready var connect_btn = $ConnectionPanel/ConnectBtn

@onready var login_input = $AuthPanel/LoginInput
@onready var pass_input = $AuthPanel/PassInput
@onready var repeat_input = $AuthPanel/RepeatInput
@onready var toggle_btn = $AuthPanel/ToggleBtn
@onready var auth_btn = $AuthPanel/AuthBtn

# Без @onready для remember_check
var remember_check = null

var is_login = true
var audio_player

func _ready():
	print("🎮 Game загружен")
	
	# Проверяем что NetworkManager существует
	if not NetworkManager:
		print("❌ NetworkManager не найден! Проверьте автозагрузку.")
		return
	
	# Ищем remember_check вручную
	if has_node("AuthPanel/RememberCheck"):
		remember_check = $AuthPanel/RememberCheck
		print("✅ RememberCheck найден")
	else:
		print("⚠️ RememberCheck отсутствует в сцене")
	
	load_logo()
	
	logo.modulate = Color(1, 1, 1, 0)
	create_tween().tween_property(logo, "modulate", Color(1, 1, 1, 1), 2.0)
	
	load_music()
	
	connect_btn.pressed.connect(_on_connect)
	toggle_btn.pressed.connect(_toggle_auth)
	auth_btn.pressed.connect(_on_auth)
	
	# Подключаем сигналы только если NetworkManager существует
	if NetworkManager:
		NetworkManager.connected_to_server.connect(_on_network_connected)
		NetworkManager.auth_required.connect(_on_auth_required)
		NetworkManager.login_result.connect(_on_login_result)
		NetworkManager.register_result.connect(_on_register_result)
	
	load_saved_credentials()
	
	print("🎯 NetworkManager существует: ", NetworkManager != null)

func load_logo():
	var texture = load("res://assets/logo.png")
	if texture:
		logo.texture = texture
		print("🖼️ Лого загружен: logo.png")
	else:
		print("❌ Не удалось загрузить logo.png")

func load_music():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	var stream = load("res://assets/evoria.mp3")
	if stream:
		audio_player.stream = stream
		audio_player.play()
		print("🎵 Музыка загружена: evoria.mp3")
	else:
		print("❌ Не удалось загрузить evoria.mp3")

func load_saved_credentials():
	if not remember_check:
		return
		
	var file = FileAccess.open("user://credentials.cfg", FileAccess.READ)
	if file:
		var data = file.get_var()
		if data and data.has("login") and data.has("remember") and data["remember"]:
			login_input.text = data["login"]
			pass_input.text = data["password"]
			remember_check.button_pressed = true
			print("🔐 Загружены сохранённые данные")
		file.close()

func save_credentials():
	if not remember_check or not remember_check.button_pressed:
		return
	
	var data = {
		"login": login_input.text,
		"password": pass_input.text,
		"remember": true
	}
	
	var file = FileAccess.open("user://credentials.cfg", FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		print("💾 Данные сохранены")

func _on_connect():
	print("🖱️ Кнопка ПУТЕШЕСТВИЕ нажата")
	var addr = server_input.text.strip_edges()
	if addr == "":
		addr = "1111"
		print("🔄 Адрес пустой, установлен 1111")
	
	if not NetworkManager:
		print("❌ NetworkManager не найден!")
		return
		
	NetworkManager.connect_to_server(addr)

func _on_network_connected():
	print("🔗 connected_to_server сигнал получен")

func _on_auth_required():
	print("✅ _on_auth_required ВЫЗВАН!")
	conn_panel.hide()
	auth_panel.show()

func _toggle_auth():
	is_login = !is_login
	_update_auth_ui()

func _update_auth_ui():
	if is_login:
		auth_btn.text = "ВОЙТИ"
		toggle_btn.text = "Нет аккаунта? Регистрация"
		if repeat_input:
			repeat_input.hide()
		print("🔄 Режим: ВХОД")
	else:
		auth_btn.text = "ЗАРЕГИСТРИРОВАТЬСЯ"
		toggle_btn.text = "Уже есть аккаунт? Вход"
		if repeat_input:
			repeat_input.show()
		print("🔄 Режим: РЕГИСТРАЦИЯ")

func _on_auth():
	var login = login_input.text.strip_edges()
	var pass_text = pass_input.text.strip_edges()
	
	if login == "" or pass_text == "":
		print("❌ Логин или пароль пустые")
		return
	
	if not NetworkManager:
		print("❌ NetworkManager не найден!")
		return
	
	if is_login:
		print("📤 Отправка LOGIN")
		NetworkManager.send_login(login, pass_text)
	else:
		var repeat = repeat_input.text.strip_edges()
		if pass_text != repeat:
			print("❌ Пароли не совпадают")
			return
		print("📤 Отправка REG")
		NetworkManager.send_register(login, pass_text)

func _on_login_result(success: bool, message: String):
	if success:
		print("✅ Вход успешен: ", message)
		save_credentials()
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		print("❌ Ошибка входа: ", message)

func _on_register_result(success: bool, message: String):
	if success:
		print("✅ Регистрация успешна: ", message)
		is_login = true
		_update_auth_ui()
	else:
		print("❌ Ошибка регистрации: ", message)
