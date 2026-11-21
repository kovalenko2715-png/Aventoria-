extends Panel

# === УЗЛЫ ===
@onready var close_btn = $CloseBtn

# Звук
@onready var music_toggle_btn = $VBox/MusicToggle/Btn
@onready var music_slider = $VBox/MusicSlider/HSlider
@onready var music_value_label = $VBox/MusicSlider/ValueLabel

# Чат
@onready var font_small_btn = $VBox/FontSize/SmallBtn
@onready var font_medium_btn = $VBox/FontSize/MediumBtn
@onready var font_large_btn = $VBox/FontSize/LargeBtn

# Аккаунт
@onready var change_pass_btn = $VBox/ChangePass/Btn
@onready var change_skin_btn = $VBox/ChangeSkin/Btn
@onready var logout_btn = $VBox/Logout/Btn

# === ПЕРЕМЕННЫЕ ===
var music_enabled = true
var music_volume = 80
var font_size = "medium"

func _ready():
	print("🟢 settings.gd: _ready()")
	
	# Проверяем что все узлы найдены
	print("   close_btn: ", close_btn)
	print("   music_toggle_btn: ", music_toggle_btn)
	print("   music_slider: ", music_slider)
	print("   font_small_btn: ", font_small_btn)
	
	# Подключаем сигналы
	close_btn.pressed.connect(_on_close)
	music_toggle_btn.pressed.connect(_on_music_toggle)
	music_slider.value_changed.connect(_on_music_volume_changed)
	font_small_btn.pressed.connect(_on_font_small)
	font_medium_btn.pressed.connect(_on_font_medium)
	font_large_btn.pressed.connect(_on_font_large)
	change_pass_btn.pressed.connect(_on_change_pass)
	change_skin_btn.pressed.connect(_on_change_skin)
	logout_btn.pressed.connect(_on_logout)
	
	print("✅ Сигналы подключены")
	
	# Загружаем настройки
	load_settings()
	update_ui()

func load_settings():
	print("📂 load_settings()")
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		print("   Файл не найден, создаём по умолчанию")
		music_enabled = true
		music_volume = 80
		font_size = "medium"
		save_settings()
		return
	
	music_enabled = config.get_value("audio", "music_enabled", true)
	music_volume = config.get_value("audio", "music_volume", 80)
	font_size = config.get_value("chat", "font_size", "medium")
	
	print("   music_enabled: ", music_enabled)
	print("   music_volume: ", music_volume)
	print("   font_size: ", font_size)

func save_settings():
	print("💾 save_settings()")
	var config = ConfigFile.new()
	
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("chat", "font_size", font_size)
	
	config.save("user://settings.cfg")
	print("   music_enabled: ", music_enabled)
	print("   music_volume: ", music_volume)
	print("   font_size: ", font_size)

func update_ui():
	print("🎨 update_ui()")
	
	# Обновляем текст кнопки музыки
	if music_enabled:
		music_toggle_btn.text = "Вкл"
		music_toggle_btn.modulate = Color(0, 1, 0)  # Зелёный
	else:
		music_toggle_btn.text = "Выкл"
		music_toggle_btn.modulate = Color(1, 0, 0)  # Красный
	
	# Обновляем ползунок и значение
	music_slider.value = music_volume
	music_value_label.text = str(music_volume)
	
	# Применяем настройки
	apply_audio_settings()
	apply_font_settings()

func apply_audio_settings():
	print("🔊 apply_audio_settings()")
	var main = get_parent()
	if main and main.has_method("apply_audio_settings"):
		main.apply_audio_settings(music_enabled, music_volume)
		print("   ✅ метод apply_audio_settings вызван")
	else:
		print("   ❌ метод apply_audio_settings НЕ НАЙДЕН")

func apply_font_settings():
	print("📏 apply_font_settings()")
	var main = get_parent()
	if main and main.has_method("apply_chat_font_size"):
		main.apply_chat_font_size(font_size)
		print("   ✅ метод apply_chat_font_size вызван")
	else:
		print("   ❌ метод apply_chat_font_size НЕ НАЙДЕН")

func _on_music_toggle():
	print("🎵 _on_music_toggle()")
	music_enabled = !music_enabled
	update_ui()
	save_settings()

func _on_music_volume_changed(value: float):
	print("🔊 _on_music_volume_changed(", value, ")")
	music_volume = value
	update_ui()
	save_settings()

func _on_font_small():
	print("📏 _on_font_small()")
	font_size = "small"
	apply_font_settings()
	save_settings()

func _on_font_medium():
	print("📏 _on_font_medium()")
	font_size = "medium"
	apply_font_settings()
	save_settings()

func _on_font_large():
	print("📏 _on_font_large()")
	font_size = "large"
	apply_font_settings()
	save_settings()

func _on_change_pass():
	print("🔑 _on_change_pass()")
	show_change_password_dialog()

func show_change_password_dialog():
	print("📱 show_change_password_dialog()")
	
	# Создаём окно смены пароля
	var dialog = Window.new()
	dialog.title = "Смена пароля"
	dialog.size = Vector2(400, 300)
	dialog.exclusive = true
	dialog.transient = true
	get_tree().root.add_child(dialog)
	
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.05
	vbox.anchor_right = 0.95
	vbox.anchor_top = 0.05
	vbox.anchor_bottom = 0.95
	dialog.add_child(vbox)
	
	# Текущий пароль
	var old_label = Label.new()
	old_label.text = "Текущий пароль:"
	vbox.add_child(old_label)
	
	var old_input = LineEdit.new()
	old_input.secret = true
	old_input.placeholder_text = "Введите текущий пароль"
	vbox.add_child(old_input)
	
	# Новый пароль
	var new_label = Label.new()
	new_label.text = "Новый пароль:"
	vbox.add_child(new_label)
	
	var new_input = LineEdit.new()
	new_input.secret = true
	new_input.placeholder_text = "Введите новый пароль"
	vbox.add_child(new_input)
	
	# Повтор пароля
	var repeat_label = Label.new()
	repeat_label.text = "Повторите пароль:"
	vbox.add_child(repeat_label)
	
	var repeat_input = LineEdit.new()
	repeat_input.secret = true
	repeat_input.placeholder_text = "Повторите новый пароль"
	vbox.add_child(repeat_input)
	
	# Информационное сообщение
	var info_label = Label.new()
	info_label.text = ""
	info_label.add_theme_color_override("font_color", Color(1, 0, 0))
	vbox.add_child(info_label)
	
	# Кнопки
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var save_btn = Button.new()
	save_btn.text = "Сохранить"
	hbox.add_child(save_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Отмена"
	hbox.add_child(cancel_btn)
	
	# Растягивающийся элемент
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Логика смены пароля
	save_btn.pressed.connect(func():
		var old_pass = old_input.text.strip_edges()
		var new_pass = new_input.text.strip_edges()
		var repeat_pass = repeat_input.text.strip_edges()
		
		# Проверки
		if old_pass == "" or new_pass == "" or repeat_pass == "":
			info_label.text = "Все поля должны быть заполнены!"
			return
		
		if new_pass != repeat_pass:
			info_label.text = "Новый пароль и повтор не совпадают!"
			return
		
		# Проверяем текущий пароль
		var login = NetworkManager.player_data.get("name", "")
		var file = FileAccess.open("user://players.dat", FileAccess.READ)
		var players = {}
		if file:
			players = file.get_var()
			file.close()
		
		if not players.has(login) or players[login]["password"] != old_pass:
			info_label.text = "Неверный текущий пароль!"
			return
		
		# Меняем пароль
		players[login]["password"] = new_pass
		file = FileAccess.open("user://players.dat", FileAccess.WRITE)
		file.store_var(players)
		file.close()
		
		info_label.text = "✅ Пароль успешно изменён!"
		info_label.add_theme_color_override("font_color", Color(0, 1, 0))
		
		# Закрываем окно через 2 секунды
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	
	cancel_btn.pressed.connect(func():
		if is_instance_valid(dialog):
			dialog.queue_free()
	)
	
	dialog.popup_centered()

func _on_change_skin():
	print("🎭 _on_change_skin()")
	
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Функция смены облика будет доступна позже"
	dialog.title = "Смена облика"
	add_child(dialog)
	dialog.popup_centered()
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(dialog):
		dialog.queue_free()

func _on_logout():
	print("🚪 _on_logout()")
	get_tree().change_scene_to_file("res://game.tscn")

func _on_close():
	print("❌ _on_close()")
	queue_free()
