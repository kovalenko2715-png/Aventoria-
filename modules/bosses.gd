# res://modules/bosses.gd
extends Panel

var close_btn
var dungeon_window = null
var world_window = null
var event_window = null

func _ready():
	build_ui()
	close_btn.pressed.connect(_on_close)

func build_ui():
	anchor_left = 0.1
	anchor_top = 0.05
	anchor_right = 0.9
	anchor_bottom = 0.95
	
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
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)
	
	var top_panel = HBoxContainer.new()
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(top_panel)
	
	var title = Label.new()
	title.text = "👑 БОССЫ 👑"
	title.horizontal_alignment = 1
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	title.add_theme_font_size_override("font_size", 28)
	top_panel.add_child(title)
	
	close_btn = Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(45, 45)
	top_panel.add_child(close_btn)
	
	var sep = HSeparator.new()
	sep.modulate = Color(1, 0.84, 0, 0.3)
	main_vbox.add_child(sep)
	
	var info_label = Label.new()
	info_label.text = "ВЫБЕРИТЕ ТИП БОССОВ"
	info_label.horizontal_alignment = 1
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(info_label)
	
	var center_container = CenterContainer.new()
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(center_container)
	
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_hbox.add_theme_constant_override("separation", 40)
	center_container.add_child(buttons_hbox)
	
	var dungeon_btn = create_boss_type_button(
		"ДАНЖЕН-БОССЫ", 
		"Подземелья", 
		"Доступно: 6", 
		Color(0.4, 0.5, 0.9)
	)
	dungeon_btn.pressed.connect(_on_dungeon_pressed)
	buttons_hbox.add_child(dungeon_btn)
	
	var world_btn = create_boss_type_button(
		"МИРОВЫЕ БОССЫ", 
		"Открытый мир", 
		"Доступно: 3", 
		Color(0.3, 0.8, 0.4)
	)
	world_btn.pressed.connect(_on_world_pressed)
	buttons_hbox.add_child(world_btn)
	
	var event_btn = create_boss_type_button(
		"СОБЫТИЙНЫЕ", 
		"Ограниченное время", 
		"Доступно: 3", 
		Color(0.9, 0.6, 0.2)
	)
	event_btn.pressed.connect(_on_event_pressed)
	buttons_hbox.add_child(event_btn)
	
	var bottom_info = Label.new()
	bottom_info.text = "⚔️ Сражайтесь с боссами, получайте награды и редкие предметы!\nНекоторые боссы доступны только в определённое время."
	bottom_info.horizontal_alignment = 1
	bottom_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	bottom_info.add_theme_font_size_override("font_size", 11)
	main_vbox.add_child(bottom_info)

func create_boss_type_button(title_text: String, subtitle: String, info: String, color: Color) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(220, 160)
	
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", transparent_style)
	btn.add_theme_stylebox_override("hover", transparent_style)
	btn.add_theme_stylebox_override("pressed", transparent_style)
	
	var inner_panel = Panel.new()
	inner_panel.anchor_left = 0
	inner_panel.anchor_top = 0
	inner_panel.anchor_right = 1
	inner_panel.anchor_bottom = 1
	inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.1, 0.08, 0.95)
	panel_style.border_color = color
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	inner_panel.add_theme_stylebox_override("panel", panel_style)
	btn.add_child(inner_panel)
	
	var center_container = CenterContainer.new()
	center_container.anchor_left = 0
	center_container.anchor_top = 0
	center_container.anchor_right = 1
	center_container.anchor_bottom = 1
	inner_panel.add_child(center_container)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.add_theme_constant_override("separation", 8)
	center_container.add_child(btn_vbox)
	
	var title_label = Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = 1
	title_label.add_theme_color_override("font_color", color)
	title_label.add_theme_font_size_override("font_size", 18)
	btn_vbox.add_child(title_label)
	
	var sub_label = Label.new()
	sub_label.text = subtitle
	sub_label.horizontal_alignment = 1
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	sub_label.add_theme_font_size_override("font_size", 12)
	btn_vbox.add_child(sub_label)
	
	var sep_line = HSeparator.new()
	sep_line.modulate = color
	sep_line.custom_minimum_size.y = 2
	btn_vbox.add_child(sep_line)
	
	var info_label = Label.new()
	info_label.text = info
	info_label.horizontal_alignment = 1
	info_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	info_label.add_theme_font_size_override("font_size", 13)
	btn_vbox.add_child(info_label)
	
	btn.mouse_entered.connect(func(): 
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.18, 0.15, 0.12, 0.98)
		hover_style.border_color = color
		hover_style.border_width_left = 2
		hover_style.border_width_right = 2
		hover_style.border_width_top = 2
		hover_style.border_width_bottom = 2
		hover_style.corner_radius_top_left = 15
		hover_style.corner_radius_top_right = 15
		hover_style.corner_radius_bottom_left = 15
		hover_style.corner_radius_bottom_right = 15
		inner_panel.add_theme_stylebox_override("panel", hover_style)
	)
	
	btn.mouse_exited.connect(func():
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.12, 0.1, 0.08, 0.95)
		normal_style.border_color = color
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.corner_radius_top_left = 15
		normal_style.corner_radius_top_right = 15
		normal_style.corner_radius_bottom_left = 15
		normal_style.corner_radius_bottom_right = 15
		inner_panel.add_theme_stylebox_override("panel", normal_style)
	)
	
	return btn

func _on_dungeon_pressed():
	if dungeon_window and is_instance_valid(dungeon_window):
		dungeon_window.visible = true
		dungeon_window.move_to_front()
		return
	
	dungeon_window = load("res://modules/bosses_dungeon.gd").new()
	add_child(dungeon_window)
	dungeon_window.tree_exited.connect(_on_dungeon_closed)

func _on_dungeon_closed():
	dungeon_window = null

func _on_world_pressed():
	if world_window and is_instance_valid(world_window):
		world_window.visible = true
		world_window.move_to_front()
		return
	
	world_window = load("res://modules/bosses_world.gd").new()
	add_child(world_window)
	world_window.tree_exited.connect(_on_world_closed)

func _on_world_closed():
	world_window = null

func _on_event_pressed():
	if event_window and is_instance_valid(event_window):
		event_window.visible = true
		event_window.move_to_front()
		return
	
	event_window = load("res://modules/bosses_event.gd").new()
	add_child(event_window)
	event_window.tree_exited.connect(_on_event_closed)

func _on_event_closed():
	event_window = null

func _on_close():
	if dungeon_window:
		dungeon_window.queue_free()
	if world_window:
		world_window.queue_free()
	if event_window:
		event_window.queue_free()
	queue_free()
