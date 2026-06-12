extends RigidBody3D
class_name Analyzer

var analyzed_bee: BeeData = null
@onready var tooltip: Label3D = $StatusTooltip

func _ready() -> void:
	update_tooltip()

func get_item_name() -> String:
	return "Анализатор ДНК"

func interact(player: Player) -> void:
	if analyzed_bee == null and player.held_small_item is BeeData:
		analyzed_bee = player.held_small_item
		player.held_small_item = null
		player.update_hand_ui()
		update_tooltip()
		
		player.show_analyzer_ui(analyzed_bee) # Вызываем UI на стороне игрока
		
	elif analyzed_bee != null and player.held_small_item == null:
		player.held_small_item = analyzed_bee
		analyzed_bee = null
		player.update_hand_ui()
		update_tooltip()

	elif analyzed_bee == null and player.held_small_item == null:
		var parent = get_parent()
		if parent.is_in_group("pedestal"):
			parent.remove_item(player)
		else:
			reparent(player.heavy_socket)
			position = Vector3.ZERO
			rotation = Vector3.ZERO
			freeze = true
			player.held_heavy_item = self
			player.update_hand_ui()

func update_tooltip() -> void:
	if analyzed_bee:
		tooltip.text = "Анализатор\n[Внутри: " + analyzed_bee.species.name + "]\nНажми E чтобы забрать"
		tooltip.modulate = Color.CYAN
	else:
		tooltip.text = "Анализатор\n[Вставь пчелу]"
		tooltip.modulate = Color.WHITE
