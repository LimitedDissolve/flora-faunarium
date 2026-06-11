extends CharacterBody3D

const SPEED = 5.0
const HEAVY_SPEED_MULTIPLIER = 0.65 # снижение скорости при подбирании тяжелого предмета

var is_ui_active: bool = false 

# --- СЛОТЫ РУК ---
var held_small_item: Variant = null # Может быть BeeData или Dictionary (рамка, мед, соты)
var held_heavy_item: Node3D = null  # Физический объект улья/механизма в руках
var small_item_visual: Node3D = null # Визуальная модель предмета в руке

# Ссылка на универсальный предмет для пола (полностью заменяет bee_jar)
var world_item_scene = preload("res://Entities/Items/world_item.tscn")

var forest_species = load("res://Data/Resources/species_forest.tres")
var meadow_species = load("res://Data/Resources/species_meadow.tres")

@onready var left_hand = $Head/Camera3D/LeftHand
@onready var right_hand = $Head/Camera3D/RightHand
@onready var heavy_socket = $Head/Camera3D/HeavySocket
@onready var hand_ui = $CanvasLayer/HandUI

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var interact_ray = $Head/Camera3D/InteractRay

var heavy_hand_socket: Node3D
var mouse_sensitivity = 0.003

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_ray.target_position = Vector3(0, 0, -4)
	
	# Привязываем переменную к узлу из сцены (который мы настроили по центру)
	heavy_hand_socket = heavy_socket 
	
	update_hand_ui()
	
func _input(event):
	# === ЧИТЫ ===
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			spawn_test_item(BeeData.create_wild(forest_species, BeeData.Castes.PRINCESS))
		elif event.keycode == KEY_2:
			spawn_test_item(BeeData.create_wild(meadow_species, BeeData.Castes.DRONE))
		elif event.keycode == KEY_3:
			held_small_item = {"type": "frame", "name": "Пустая Рамка"}
			update_hand_ui()
	
	# 1. ВЫБРОСИТЬ ПРЕДМЕТ (Кнопка Q)
	if event.is_action_pressed("drop"):
		if held_small_item != null:
			drop_small_item()
		elif held_heavy_item != null:
			drop_heavy_item()
		return
	
	# 2. ВЗАИМОДЕЙСТВИЕ (Кнопка E)
	if event.is_action_pressed("interact") and interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		
		if target.is_in_group("interactable") and target.has_method("interact"):
			target.interact(self)

func update_hand_ui():
	if small_item_visual:
		small_item_visual.queue_free()
		small_item_visual = null

	if held_heavy_item != null:
		# Когда несем тяжелое, маленькие руки можно визуально скрыть 
		# (если у вас есть меши рук)
		left_hand.visible = false 
		right_hand.visible = false
		hand_ui.text = "Несу в обеих руках: " + held_heavy_item.get_item_name()
		hand_ui.add_theme_color_override("font_color", Color.CYAN)
		
	elif held_small_item != null:
		left_hand.visible = true
		right_hand.visible = true
		_create_small_item_visual()
		
		if held_small_item is BeeData:
			hand_ui.text = "В правой руке: " + held_small_item.species.name
		else:
			hand_ui.text = "В правой руке: " + held_small_item.get("name", "Предмет")
		hand_ui.add_theme_color_override("font_color", Color.YELLOW)
	else:
		left_hand.visible = true
		right_hand.visible = true
		hand_ui.text = "Руки пусты"
		hand_ui.add_theme_color_override("font_color", Color.WHITE)

func _create_small_item_visual():
	small_item_visual = world_item_scene.instantiate()
	right_hand.add_child(small_item_visual)
	
	small_item_visual.freeze = true
	small_item_visual.collision_layer = 0
	small_item_visual.collision_mask = 0
	small_item_visual.item_data = held_small_item
	
	# Смещение, чтобы предмет был ПЕРЕД рукой, а не внутри неё
	small_item_visual.position = Vector3(0, 0, -0.1) 
	small_item_visual.rotation = Vector3.ZERO

func drop_small_item():
	var dropped_node = world_item_scene.instantiate()
	dropped_node.item_data = held_small_item
	get_tree().current_scene.add_child(dropped_node)
	
	var drop_pos = camera.global_position - camera.global_transform.basis.z * 1.2
	dropped_node.global_position = drop_pos
	dropped_node.apply_impulse(-camera.global_transform.basis.z * 3.0)
	
	held_small_item = null
	update_hand_ui()

func drop_heavy_item():
	if held_heavy_item:
		var item = held_heavy_item
		held_heavy_item = null
		
		# Возвращаем предмет в корень сцены
		item.reparent(get_tree().current_scene)
		
		# Позиция: чуть впереди и ниже головы, чтобы не застрять в игроке
		var drop_pos = head.global_position - head.global_transform.basis.z * 1.5
		item.global_position = drop_pos
		
		# ВАЖНО: Правильный сброс физики
		if item is RigidBody3D:
			item.freeze = false
			item.sleeping = false # Просыпаемся, чтобы физика заработала
			item.collision_layer = 1 # Слой, который видит RayCast
			item.collision_mask = 1
			# Небольшой импульс от игрока
			var impulse = -head.global_transform.basis.z * 2.0
			item.apply_central_impulse(impulse)
		
		update_hand_ui()

func spawn_test_item(data_to_spawn: Variant):
	var dropped_node = world_item_scene.instantiate()
	dropped_node.item_data = data_to_spawn
	get_tree().current_scene.add_child(dropped_node)
	dropped_node.global_position = camera.global_position - camera.global_transform.basis.z * 2.0

func _unhandled_input(event):
	# 1. Сначала обрабатываем клик для захвата мыши, даже если она сейчас видима
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled() # Помечаем событие как обработанное

	# 2. Если мышь всё еще видима, игнорируем вращение камеры
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		return

	# 3. Вращение камеры (работает только при захваченной мыши)
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	# Освобождение мыши по кнопке Esc (ui_cancel)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if is_ui_active:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		# РАССЧИТЫВАЕМ ТЕКУЩУЮ СКОРОСТЬ
		var current_speed = SPEED
		if held_heavy_item != null:
			current_speed *= HEAVY_SPEED_MULTIPLIER
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()
