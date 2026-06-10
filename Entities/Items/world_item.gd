extends RigidBody3D

@export var item_data: Variant = null

@onready var mesh = $MeshInstance3D
@onready var label = $Label3D

func _ready():
	add_to_group("interactable")
	add_to_group("small_item")
	_update_visuals()

func interact(player):
	if player.held_small_item == null and player.held_heavy_item == null:
		player.held_small_item = item_data
		player.update_hand_ui()
		queue_free() 
	else:
		print("Руки заняты!")

func _update_visuals():
	if item_data == null:
		return
		
	var material = StandardMaterial3D.new()
	mesh.material_override = material
	
	# 1. Если это Пчела (BeeData)
	if item_data is BeeData:
		var caste_str = "Принцесса" if item_data.caste == BeeData.Castes.PRINCESS else "Трутень"
		label.text = item_data.species.name + "\n(" + caste_str + ")"
		label.modulate = Color.YELLOW
		material.albedo_color = Color("e0a96d")
		
	# 2. Если это Dictionary (рамка, мед, соты)
	elif typeof(item_data) == TYPE_DICTIONARY:
		var type = item_data.get("type", "")
		label.text = item_data.get("name", "Предмет")
		
		match type:
			"frame":
				material.albedo_color = Color("8d5b4c")
				label.modulate = Color.BROWN
			"comb":
				material.albedo_color = Color("ffb703")
				label.modulate = Color.GOLD
			"honey":
				material.albedo_color = Color("fb8500")
				label.modulate = Color.ORANGE
			_:
				material.albedo_color = Color.WHITE
				label.modulate = Color.WHITE
