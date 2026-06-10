extends Resource
class_name BeeSpecies

@export var id: String = "forest" # Уникальный ID для логики
@export var name: String = "Лесная Пчела"
@export var model: PackedScene
@export var icon: Texture2D

@export_category("Базовые Гены (Шаблон)")
@export var base_lifespan: float = 60.0 # Время жизни Королевы (сек)
@export var base_work_speed: float = 1.0 # Скорость производства/опыления
@export var base_fertility: int = 2 # Количество рождаемых трутней (1-4)
@export var base_special_effect: String = "none" # Задел на будущее (свет, тепло, яд)
