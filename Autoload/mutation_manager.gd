extends Node

@export var all_recipes: Array[MutationRecipe] = []

func _ready():
	var recipe = load("res://Data/Resources/recipe_golden.tres")
	if recipe:
		all_recipes.append(recipe)

func calculate_offspring(princess: BeeData, drone: BeeData, environment_data: Dictionary) -> BeeData:
	var p1_id = princess.species.id
	var p2_id = drone.species.id
	
	var possible_mutations = []
	
	# 1. Ищем все подходящие рецепты скрещивания
	for recipe in all_recipes:
		var match_forward = (recipe.parent1_id == p1_id and recipe.parent2_id == p2_id)
		var match_reverse = (recipe.parent1_id == p2_id and recipe.parent2_id == p1_id)
		
		if match_forward or match_reverse:
			if recipe.check_conditions(environment_data):
				possible_mutations.append(recipe)
	
	# 2. Проверяем шанс мутации (если путей несколько, проверяем все по очереди)
	for mutation in possible_mutations:
		if randf() <= mutation.chance:
			# МУТАЦИЯ ПРОИЗОШЛА! Возвращаем новую принцессу
			print("Мутация успешна! Получена: ", mutation.result_species.name)
			return BeeData.create_wild(mutation.result_species, BeeData.Castes.PRINCESS)
			
	# 3. ЕСЛИ МУТАЦИЯ НЕ СРАБОТАЛА - Наследование
	# С шансом 50/50 берем вид матери или отца
	var inherited_species = princess.species if randf() > 0.5 else drone.species
	
	var offspring = BeeData.new()
	offspring.species = inherited_species
	offspring.caste = BeeData.Castes.PRINCESS
	
	# Микс генов: берем среднее или случайное от родителей
	offspring.work_speed = (princess.work_speed + drone.work_speed) / 2.0
	offspring.lifespan = princess.lifespan if randf() > 0.5 else drone.lifespan
	offspring.fertility = princess.fertility if randf() > 0.5 else drone.fertility
	offspring.special_effect = princess.special_effect # Допустим, эффекты идут по материнской линии
	
	print("Без мутаций. Родилась: ", inherited_species.name)
	return offspring
