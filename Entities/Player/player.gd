extends CharacterBody3D
class_name Player

const SPEED = 5.0
const HEAVY_SPEED_MULTIPLIER = 0.65 # снижение скорости при подбирании тяжелого предмета

var is_ui_active: bool = false 

# --- СЛОТЫ РУК ---
var held_small_item: Resource = null
var held_heavy_item: RigidBody3D = null
var small_item_visual: Node3D = null

@export var world_item_scene: PackedScene # Заменили preload на export
@export var forest_species: BeeSpecies
@export var meadow_species: BeeSpecies

@onready var left_hand: Node3D = $Head/Camera3D/LeftHand
@onready var right_hand: Node3D = $Head/Camera3D/RightHand
@onready var heavy_socket: Node3D = $Head/Camera3D/HeavySocket
@onready var hand_ui: Label = $CanvasLayer/HandUI
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

var mouse_sensitivity: float = 0.003

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_hand_ui()
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			spawn_test_item(BeeData.create_wild(forest_species, BeeData.Castes.PRINCESS))
		elif event.keycode == KEY_2:
			spawn_test_item(BeeData.create_wild(meadow_species, BeeData.Castes.DRONE))
		elif event.keycode == KEY_3:
			held_small_item = ItemData.create(ItemData.ItemType.FRAME, "Пустая Рамка")
			update_hand_ui()
	
	if event.is_action_pressed("drop"):
		if held_small_item:
			drop_small_item()
		elif held_heavy_item:
			drop_heavy_item()
		return
	
	if event.is_action_pressed("interact") and interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		if target.is_in_group("interactable") and target.has_method("interact"):
			target.interact(self)

func update_hand_ui() -> void:
	if is_instance_valid(small_item_visual):
		small_item_visual.queue_free()
		small_item_visual = null

	if held_heavy_item:
		left_hand.hide()
		right_hand.hide()
		hand_ui.text = "Несу: " + held_heavy_item.get_item_name() if held_heavy_item.has_method("get_item_name") else "Предмет"
		hand_ui.add_theme_color_override("font_color", Color.CYAN)
	elif held_small_item:
		left_hand.show()
		right_hand.show()
		_create_small_item_visual()
		
		if held_small_item is BeeData:
			hand_ui.text = "В руке: " + held_small_item.species.name
		elif held_small_item is ItemData:
			hand_ui.text = "В руке: " + held_small_item.name
		hand_ui.add_theme_color_override("font_color", Color.YELLOW)
	else:
		left_hand.show()
		right_hand.show()
		hand_ui.text = "Руки пусты"
		hand_ui.add_theme_color_override("font_color", Color.WHITE)

func _create_small_item_visual() -> void:
	small_item_visual = world_item_scene.instantiate()
	right_hand.add_child(small_item_visual)
	small_item_visual.freeze = true
	small_item_visual.collision_layer = 0
	small_item_visual.collision_mask = 0
	small_item_visual.item_data = held_small_item
	small_item_visual.position = Vector3(0, 0, -0.1) 
	small_item_visual.rotation = Vector3.ZERO

func drop_small_item() -> void:
	var dropped_node = world_item_scene.instantiate()
	dropped_node.item_data = held_small_item
	get_tree().current_scene.add_child(dropped_node)
	dropped_node.global_position = camera.global_position - camera.global_transform.basis.z * 1.2
	dropped_node.apply_impulse(-camera.global_transform.basis.z * 3.0)
	
	held_small_item = null
	update_hand_ui()

func drop_heavy_item() -> void:
	if not held_heavy_item: return
	
	var item = held_heavy_item
	held_heavy_item = null
	item.reparent(get_tree().current_scene)
	item.global_position = head.global_position - head.global_transform.basis.z * 1.5
	
	item.freeze = false
	item.sleeping = false 
	item.collision_layer = 1 
	item.collision_mask = 1
	item.apply_central_impulse(-head.global_transform.basis.z * 2.0)
	
	update_hand_ui()

func spawn_test_item(data_to_spawn: Resource) -> void:
	var dropped_node = world_item_scene.instantiate()
	dropped_node.item_data = data_to_spawn
	get_tree().current_scene.add_child(dropped_node)
	dropped_node.global_position = camera.global_position - camera.global_transform.basis.z * 2.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		return

	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if is_ui_active:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		var current_speed = SPEED * (HEAVY_SPEED_MULTIPLIER if held_heavy_item else 1.0)
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

func show_analyzer_ui(bee: BeeData) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_ui_active = true	
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(400, 300)
	panel.position = (get_viewport().size / 2) - Vector2i(200, 150)
	# ... (Стили панели как были в твоем коде) ...
	
	var text = RichTextLabel.new()
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.position = Vector2(20, 20)
	text.size = Vector2(360, 200)
	text.bbcode_enabled = true
	
	var caste_name = "Принцесса" if bee.caste == BeeData.Castes.PRINCESS else "Трутень"
	text.text = "[center][b]ДНК: %s (%s)[/b][/center]\n\n" % [bee.species.name, caste_name]
	text.text += "Скорость: [color=yellow]%.1f[/color]\n" % bee.work_speed
	text.text += "Жизнь: [color=green]%.1f сек[/color]\n" % bee.lifespan
	text.text += "Потомство: [color=orange]%d шт[/color]\n" % bee.fertility
	
	var btn = Button.new()
	btn.text = "Закрыть Анализатор"
	btn.position = Vector2(100, 240)
	btn.size = Vector2(200, 40)
	
	panel.add_child(text)
	panel.add_child(btn)
	$CanvasLayer.add_child(panel)
	
	btn.pressed.connect(func(): 
		panel.queue_free()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		is_ui_active = false
	)
