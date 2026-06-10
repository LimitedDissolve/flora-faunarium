extends StaticBody3D

const MAX_POLLEN = 5 # Сколько тиков опыления нужно для созревания
var pollination_level: int = 0

var fruit_scene = preload("res://Entities/Items/tree_fruit.tscn")

@onready var mesh_instance = $MeshInstance3D
var tree_material: StandardMaterial3D

func _ready():
	# === ГАРАНТИРОВАННО ДОБАВЛЯЕМ В ГРУППУ ЧЕРЕЗ КОД ===
	add_to_group("tree")
	
	# Создаем уникальный материал для этого дерева
	tree_material = StandardMaterial3D.new()
	tree_material.albedo_color = Color("2d4c1e") # Темно-зеленый
	mesh_instance.material_override = tree_material

# Заменили bee_name на _bee_name, чтобы убрать предупреждение редактора
func receive_pollen(_bee_name: String):
	pollination_level += 1
	
	# Выводим в консоль, чтобы точно видеть, что процесс идет
	print("Дерево опыляется! Прогресс: ", pollination_level, "/", MAX_POLLEN)
	
	# 1. Анимация подпрыгивания
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.1, 1.2, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
	
	# 2. Плавная смена цвета (от зеленого к спелому)
	var progress = float(pollination_level) / float(MAX_POLLEN)
	var ripen_color = Color("ffb703") # Спелый желтый цвет
	tree_material.albedo_color = Color("2d4c1e").lerp(ripen_color, progress)
	
	# 3. Если созрело - сбрасываем плод
	if pollination_level >= MAX_POLLEN:
		print("Дерево созрело! Сброс плода.")
		spawn_fruit()
		reset_tree()

func spawn_fruit():
	# Проверяем, существует ли сцена плода
	if fruit_scene == null:
		print("ОШИБКА: Сцена tree_fruit.tscn не найдена!")
		return
		
	var fruit = fruit_scene.instantiate()
	get_tree().current_scene.add_child(fruit)
	
	fruit.global_position = global_position + Vector3(0, 2.0, 0)
	var random_dir = Vector3(randf_range(-1, 1), 2.0, randf_range(-1, 1)).normalized()
	fruit.apply_impulse(random_dir * 3.0)

func reset_tree():
	pollination_level = 0
	var tween = create_tween()
	tween.tween_property(tree_material, "albedo_color", Color("2d4c1e"), 1.0)
