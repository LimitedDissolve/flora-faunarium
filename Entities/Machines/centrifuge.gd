extends RigidBody3D
class_name Centrifuge

@onready var mesh: MeshInstance3D = $MeshInstance3D
var tooltip: Label3D

enum State { EMPTY, PROCESSING, DONE }
var current_state: State = State.EMPTY
var processing_time: float = 0.0
var result_species: BeeSpecies = null

func _ready() -> void:
	# Оставляем создание тултипа через код, как ты привык, чтобы ничего не сломать
	tooltip = Label3D.new()
	add_child(tooltip)
	tooltip.position = Vector3(0, 0.8, 0)
	tooltip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tooltip.pixel_size = 0.003
	tooltip.no_depth_test = true
	update_tooltip()

func get_item_name() -> String:
	return "Центрифуга"

func interact(player: Player) -> void:
	if current_state == State.EMPTY:
		var held_item = player.held_small_item
		
		# Пытаемся положить соту (теперь проверяем через новый класс ItemData)
		if held_item is ItemData and held_item.type == ItemData.ItemType.COMB:
			result_species = held_item.species
			player.held_small_item = null
			player.update_hand_ui()
			
			current_state = State.PROCESSING
			processing_time = 3.0
			update_tooltip()
			return
			
		# Если руки пусты - Поднимаем Центрифугу
		elif held_item == null and player.held_heavy_item == null:
			var parent = get_parent()
			if parent.is_in_group("pedestal") and parent.has_method("remove_item"):
				parent.remove_item(player)
			else:
				# Поднятие с пола в руки (ЗДЕСЬ ИСПРАВЛЕНА ОШИБКА: heavy_socket)
				reparent(player.heavy_socket)
				position = Vector3.ZERO
				rotation = Vector3.ZERO
				freeze = true
				collision_layer = 0
				collision_mask = 0
				player.held_heavy_item = self
				player.update_hand_ui()
			return
				
	elif current_state == State.DONE:
		# Выдаем игроку каплю меда (создаем через ItemData)
		if player.held_small_item == null:
			player.held_small_item = ItemData.create(ItemData.ItemType.HONEY, "Мед (" + result_species.name + ")", result_species)
			player.update_hand_ui()
			
			current_state = State.EMPTY
			result_species = null
			update_tooltip()

func _process(delta: float) -> void:
	if current_state == State.PROCESSING:
		processing_time -= delta
		mesh.rotate_y(10.0 * delta) 
		
		if processing_time <= 0:
			current_state = State.DONE
		update_tooltip()

func update_tooltip() -> void:
	match current_state:
		State.EMPTY:
			tooltip.text = "Центрифуга\n[Вставь Соту]"
			tooltip.modulate = Color.WHITE
		State.PROCESSING:
			tooltip.text = "Взбиваем...\n" + str(snapped(processing_time, 0.1)) + "с"
			tooltip.modulate = Color.YELLOW
		State.DONE:
			tooltip.text = "Готово!\n[Забрать Мед]"
			tooltip.modulate = Color.GREEN
