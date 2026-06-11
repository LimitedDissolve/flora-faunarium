extends RigidBody3D

var analyzed_bee: BeeData = null
var tooltip: Label3D

func _ready():
	tooltip = Label3D.new()
	add_child(tooltip)
	tooltip.position = Vector3(0, 0.7, 0)
	tooltip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tooltip.pixel_size = 0.003
	tooltip.no_depth_test = true
	update_tooltip()

func get_item_name() -> String:
	return "Анализатор ДНК"

func interact(player):
	# 1. Кладем пчелу в анализатор
	if analyzed_bee == null and player.held_small_item is BeeData:
		analyzed_bee = player.held_small_item
		player.held_small_item = null
		player.update_hand_ui()
		update_tooltip()
		
		show_analyzer_ui(player)
		
	# 2. Если внутри уже есть пчела - забираем её
	elif analyzed_bee != null and player.held_small_item == null:
		player.held_small_item = analyzed_bee
		analyzed_bee = null
		player.update_hand_ui()
		update_tooltip()

	# 3. Поднимаем сам Анализатор, если он пуст
	elif analyzed_bee == null and player.held_small_item == null:
		var parent = get_parent()
		if parent.is_in_group("pedestal"):
			parent.remove_item(player)
		else:
			# Поднятие с пола в руки
			reparent(player.heavy_hand_socket)
			position = Vector3.ZERO
			rotation = Vector3.ZERO
			freeze = true
			player.held_heavy_item = self
			player.update_hand_ui()

func update_tooltip():
	if analyzed_bee:
		tooltip.text = "Анализатор\n[Внутри: " + analyzed_bee.species.name + "]\nНажми E чтобы забрать"
		tooltip.modulate = Color.CYAN
	else:
		tooltip.text = "Анализатор\n[Вставь пчелу]"
		tooltip.modulate = Color.WHITE

func show_analyzer_ui(player):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.is_ui_active = true	
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(400, 300)
	panel.position = (player.get_viewport().size / 2) - Vector2i(200, 150)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var text = RichTextLabel.new()
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.position = Vector2(20, 20)
	text.size = Vector2(360, 200)
	text.bbcode_enabled = true
	
	var caste_name = "Принцесса" if analyzed_bee.caste == BeeData.Castes.PRINCESS else "Трутень"
	
	text.text = "[center][b]ДНК: " + analyzed_bee.species.name + " (" + caste_name + ")[/b][/center]\n\n"
	text.text += "Скорость работы:\t[color=yellow]" + str(snapped(analyzed_bee.work_speed, 0.1)) + "[/color]\n"
	text.text += "Время жизни:\t\t[color=green]" + str(snapped(analyzed_bee.lifespan, 0.1)) + " сек[/color]\n"
	text.text += "Плодовитость:\t\t[color=orange]" + str(analyzed_bee.fertility) + " потомков[/color]\n"
	text.text += "Скрытый эффект:\t[color=cyan]" + str(analyzed_bee.special_effect) + "[/color]\n"
	
	var btn = Button.new()
	btn.text = "Закрыть Анализатор"
	btn.position = Vector2(100, 240)
	btn.size = Vector2(200, 40)
	
	panel.add_child(text)
	panel.add_child(btn)
	player.get_node("CanvasLayer").add_child(panel)
	
	btn.pressed.connect(func(): 
		panel.queue_free()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		player.is_ui_active = false
	)
