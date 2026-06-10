extends Resource
class_name MutationRecipe

@export var parent1_id: String
@export var parent2_id: String
@export var result_species: BeeSpecies
@export var chance: float = 0.15 # 15% шанс успеха

@export_category("Условия Мутации (Задел на будущее)")
@export var requires_light: bool = false
@export var requires_temperature: String = "any" # any, hot, cold
@export var required_nearby_block_group: String = "" # например "magic_flower"

# Метод проверки условий (сейчас всегда возвращает true, как ты просил)
func check_conditions(_environment_data: Dictionary) -> bool:
	# В будущем здесь будет:
	# if requires_light and not _environment_data.get("is_lit", false): return false
	return true
