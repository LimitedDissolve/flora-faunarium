extends RigidBody3D

@onready var timer = $TickTimer
@onready var tooltip = $StatusTooltip

var world_item_scene = preload("res://Entities/Items/world_item.tscn")

enum HiveState { EMPTY, WAITING_FOR_MATE, WORKING, DEAD }
var current_state: HiveState = HiveState.EMPTY

var stored_princess: BeeData = null
var stored_drone: BeeData = null
var active_queen: BeeData = null

var output_princess: BeeData = null
var output_drones: Array[BeeData] = []

# Переменные рамок и сот
var frames_count: int = 0
const MAX_FRAMES: int = 3
var stored_combs: Array[BeeSpecies] = []
var comb_progress: float = 0.0
const COMB_THRESHOLD: float = 10.0

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	timer.stop()
	update_tooltip()

func is_busy() -> bool:
	return current_state != HiveState.EMPTY and current_state != HiveState.DEAD

func get_item_name() -> String:
	return "Улей"

func interact(player):
	# 1. Если в руках пчела
	if player.held_small_item is BeeData:
		var bee = player.held_small_item
		if current_state == HiveState.EMPTY and bee.caste == BeeData.Castes.PRINCESS:
			stored_princess = bee
			current_state = HiveState.WAITING_FOR_MATE
			player.held_small_item = null
			player.update_hand_ui()
			update_tooltip()
		elif current_state == HiveState.WAITING_FOR_MATE and bee.caste == BeeData.Castes.DRONE:
			stored_drone = bee
			player.held_small_item = null
			player.update_hand_ui()
			start_queen_cycle()
		return
		
	# 2. Если в руках рамка
	if typeof(player.held_small_item) == TYPE_DICTIONARY and player.held_small_item.get("type") == "frame":
		if frames_count < MAX_FRAMES:
			frames_count += 1
			player.held_small_item = null
			player.update_hand_ui()
			update_tooltip()
		else:
			print("Улей уже полон рамок!")
		return

	# 3. Клик пустой рукой (сбор сот, сбор пчел или подъем улья)
	if player.held_small_item == null and player.held_heavy_item == null:
		if stored_combs.size() > 0:
			var comb_species = stored_combs.pop_back()
			player.held_small_item = {
				"type": "comb", 
				"species": comb_species, 
				"name": "Сота (" + comb_species.name + ")"
			}
			player.update_hand_ui()
			update_tooltip()
			return
			
		if current_state == HiveState.DEAD:
			spawn_loot()
			reset_hive()
			return
			
		if not is_busy() and stored_combs.is_empty():
			var parent = get_parent()
			if parent.is_in_group("pedestal"):
				parent.remove_item(player)
			else:
				# Поднятие улья с пола в сокет рук игрока
				reparent(player.heavy_hand_socket)
				position = Vector3.ZERO
				rotation = Vector3.ZERO
				freeze = true
				# Отключаем коллизию в руках
				collision_layer = 0
				collision_mask = 0
				player.held_heavy_item = self
				player.update_hand_ui()

func _process(delta):
	if current_state == HiveState.WORKING and active_queen:
		active_queen.lifespan -= delta
		
		if frames_count > 0:
			var production_power = active_queen.work_speed * (0.5 + (frames_count * 0.5))
			comb_progress += production_power * delta
			if comb_progress >= COMB_THRESHOLD:
				comb_progress -= COMB_THRESHOLD
				stored_combs.append(active_queen.species)
		
		update_tooltip() 
		if active_queen.lifespan <= 0:
			die_and_reproduce()

func start_queen_cycle():
	current_state = HiveState.WORKING
	active_queen = BeeData.new()
	active_queen.caste = BeeData.Castes.QUEEN
	active_queen.species = stored_princess.species
	active_queen.work_speed = stored_princess.work_speed
	active_queen.lifespan = stored_princess.lifespan
	timer.wait_time = 1.0 
	timer.start()
	update_tooltip()

func _on_timer_timeout():
	if current_state == HiveState.WORKING:
		var tween = create_tween()
		tween.tween_property($MeshInstance3D, "scale", Vector3(0.55, 0.12, 0.55), 0.1)
		tween.tween_property($MeshInstance3D, "scale", Vector3(0.5, 0.1, 0.5), 0.1)
		
		var overlapping_bodies = $PollinationArea.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("tree") and body.has_method("receive_pollen"):
				body.receive_pollen(active_queen.species.name)

func die_and_reproduce():
	current_state = HiveState.DEAD
	timer.stop()
	var env_data = {} 
	output_princess = MutationManager.calculate_offspring(stored_princess, stored_drone, env_data)
	output_drones.clear()
	for i in range(2): 
		var d = MutationManager.calculate_offspring(stored_princess, stored_drone, env_data)
		d.caste = BeeData.Castes.DRONE
		output_drones.append(d)
	update_tooltip()

func spawn_loot():
	if output_princess:
		drop_loot_item(output_princess)
	for drone in output_drones:
		drop_loot_item(drone)

func drop_loot_item(data: Variant):
	var item_node = world_item_scene.instantiate()
	item_node.item_data = data 
	get_tree().current_scene.add_child(item_node)
	item_node.global_position = global_position + Vector3(0, 1.5, 0)
	var random_dir = Vector3(randf_range(-1, 1), 2.0, randf_range(-1, 1)).normalized()
	item_node.apply_impulse(random_dir * 3.0)

func reset_hive():
	stored_princess = null
	stored_drone = null
	active_queen = null
	output_princess = null
	output_drones.clear()
	current_state = HiveState.EMPTY
	update_tooltip()

func update_tooltip():
	var frames_str = "\n[Рамки: " + str(frames_count) + "/" + str(MAX_FRAMES) + "]"
	var combs_str = "\n🍯 Соты: " + str(stored_combs.size()) if stored_combs.size() > 0 else ""
	
	match current_state:
		HiveState.EMPTY:
			tooltip.text = "[Пусто]\nЖду Принцессу" + frames_str + combs_str
			tooltip.modulate = Color.WHITE
		HiveState.WAITING_FOR_MATE:
			tooltip.text = "[Принцесса: " + stored_princess.species.name + "]\nЖду Трутня" + frames_str + combs_str
			tooltip.modulate = Color.YELLOW
		HiveState.WORKING:
			tooltip.text = "[РАБОТАЕТ] " + str(snapped(active_queen.lifespan, 0.1)) + "с" + frames_str + combs_str
			tooltip.modulate = Color.GREEN
		HiveState.DEAD:
			tooltip.text = "[ГОТОВО] Нажми E" + frames_str + combs_str
			tooltip.modulate = Color.ORANGE
