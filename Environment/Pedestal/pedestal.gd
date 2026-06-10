extends StaticBody3D

var current_item: Node3D = null
@onready var slot = $Slot

func interact(player):
	if player.held_small_item != null:
		print("Сначала освободите руки!")
		return
	
	# Кликнули по пустому пьедесталу с ульем/механизмом в руках
	if current_item == null and player.held_heavy_item != null:
		place_item(player)

func place_item(player):
	var item = player.held_heavy_item
	player.held_heavy_item = null
	
	item.reparent(self)
	item.global_position = slot.global_position
	
	var head_forward = -player.head.global_transform.basis.z
	head_forward.y = 0
	head_forward = head_forward.normalized()
	item.look_at(item.global_position + head_forward, Vector3.UP)
	var snapped_y = snapped(item.global_rotation.y, PI / 2)
	item.global_rotation = Vector3(0, snapped_y, 0)
	
	if item is RigidBody3D:
		item.freeze = true
		item.collision_layer = 1
		item.collision_mask = 1
		
	current_item = item
	player.update_hand_ui()

func remove_item(player):
	if current_item != null:
		var item = current_item
		current_item = null
		
		item.reparent(player.heavy_hand_socket)
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO
		
		if item is RigidBody3D:
			item.freeze = true
			item.collision_layer = 0
			item.collision_mask = 0
			
		player.held_heavy_item = item
		player.update_hand_ui()
