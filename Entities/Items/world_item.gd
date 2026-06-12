extends RigidBody3D
class_name WorldItem

@export var item_data: Resource = null

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $Label3D

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("small_item")
	_update_visuals()

func interact(player: Player) -> void:
	if player.held_small_item == null and player.held_heavy_item == null:
		player.held_small_item = item_data
		player.update_hand_ui()
		queue_free() 

func _update_visuals() -> void:
	if not item_data: return
		
	var material = StandardMaterial3D.new()
	mesh.material_override = material
	
	if item_data is BeeData:
		var caste_str = "Принцесса" if item_data.caste == BeeData.Castes.PRINCESS else "Трутень"
		label.text = "%s\n(%s)" % [item_data.species.name, caste_str]
		label.modulate = Color.YELLOW
		material.albedo_color = Color("e0a96d")
		
	elif item_data is ItemData:
		label.text = item_data.name
		match item_data.type:
			ItemData.ItemType.FRAME:
				material.albedo_color = Color("8d5b4c")
				label.modulate = Color.BROWN
			ItemData.ItemType.COMB:
				material.albedo_color = Color("ffb703")
				label.modulate = Color.GOLD
			ItemData.ItemType.HONEY:
				material.albedo_color = Color("fb8500")
				label.modulate = Color.ORANGE
			_:
				material.albedo_color = Color.WHITE
				label.modulate = Color.WHITE
