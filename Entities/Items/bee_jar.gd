extends RigidBody3D

var bee_data: BeeData

func interact(player):
	if player.held_small_item == null and player.held_heavy_item == null:
		player.held_small_item = bee_data
		player.update_hand_ui()
		queue_free() 
	else:
		print("Руки заняты!")
