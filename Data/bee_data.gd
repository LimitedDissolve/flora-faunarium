extends Resource
class_name BeeData

enum Castes { PRINCESS, DRONE, QUEEN }

@export var species: BeeSpecies
@export var caste: Castes = Castes.PRINCESS

# Активные гены этой конкретной пчелы (передаются по наследству)
@export_category("Уникальные Гены")
@export var lifespan: float
@export var work_speed: float
@export var fertility: int
@export var special_effect: String

# Функция для быстрой генерации дикой пчелы со стандартными генами
static func create_wild(s: BeeSpecies, c: Castes) -> BeeData:
	var bee = BeeData.new()
	bee.species = s
	bee.caste = c
	bee.lifespan = s.base_lifespan
	bee.work_speed = s.base_work_speed
	bee.fertility = s.base_fertility
	bee.special_effect = s.base_special_effect
	return bee
