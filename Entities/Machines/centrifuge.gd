extends RigidBody3D

@onready var mesh = $MeshInstance3D
var tooltip: Label3D

enum State { EMPTY, PROCESSING, DONE }
var current_state = State.EMPTY
var processing_time: float = 0.0
var result_species: BeeSpecies = null

func _ready():
	tooltip = Label3D.new()
	add_child(tooltip)
	tooltip.position = Vector3(0, 0.8, 0)
	tooltip.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tooltip.pixel_size = 0.003
	tooltip.no_depth_test = true
	update_tooltip()

func get_item_name() -> String:
	return "Центрифуга"

func interact(player):
	if current_state == State.EMPTY:
		# Пытаемся положить соту
		if typeof(player.held_small_item) == TYPE_DICTIONARY and player.held_small_item.get("type") == "comb":
			result_species = player.held_small_item["species"]
			player.held_small_item = null
			player.update_hand_ui()
			
			current_state = State.PROCESSING
			processing_time = 3.0
			update_tooltip()
			
		# Если руки пусты - Поднимаем Центрифугу
		elif player.held_small_item == null:
			var parent = get_parent()
			if parent.is_in_group("pedestal"):
				parent.remove_item(player)
			else:
				# Поднятие с пола в руки
				reparent(player.heavy_hand_socket)
				position = Vector3.ZERO
				rotation = Vector3.ZERO
				freeze = true
				collision_layer = 0
				collision_mask = 0
				player.held_heavy_item = self
				player.update_hand_ui()
				
	elif current_state == State.DONE:
		# Выдаем игроку каплю меда
		if player.held_small_item == null:
			player.held_small_item = {
				"type": "honey", 
				"name": "Мед (" + result_species.name + ")"
			}
			player.update_hand_ui()
			
			current_state = State.EMPTY
			result_species = null
			update_tooltip()

func _process(delta):
	if current_state == State.PROCESSING:
		processing_time -= delta
		mesh.rotate_y(10.0 * delta) 
		
		if processing_time <= 0:
			current_state = State.DONE
		update_tooltip()

func update_tooltip():
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
