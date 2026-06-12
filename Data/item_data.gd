extends Resource
class_name ItemData

enum ItemType { FRAME, COMB, HONEY, OTHER }

@export var type: ItemType = ItemType.OTHER
@export var name: String = "Предмет"
@export var species: BeeSpecies = null # Опционально: вид пчелы (для меда и сот)

static func create(item_type: ItemType, item_name: String, bee_species: BeeSpecies = null) -> ItemData:
	var item = ItemData.new()
	item.type = item_type
	item.name = item_name
	item.species = bee_species
	return item
