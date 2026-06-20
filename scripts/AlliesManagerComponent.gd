extends Node2D

var pet_chayanne_scene = preload("res://scenes/allies/pet_chayanne.tscn")
var pet_minigun_scene = preload("res://scenes/allies/pet_minigun.tscn")
var sword_craft_scene = preload("res://scenes/sword_craft.tscn")

var pet_instance: Node2D
var minigun_instance: Node2D
var sword_instance: Node2D

func _ready() -> void:
	update_component()

func update_component() -> void:
	# 1. Chayanne Chiquito
	if GameManager.get_skill_level("pet_chayanne") > 0:
		if not is_instance_valid(pet_instance):
			pet_instance = pet_chayanne_scene.instantiate()
			# Añadir a la escena principal para que pueda moverse libremente
			get_parent().get_parent().call_deferred("add_child", pet_instance)
			pet_instance.global_position = global_position + Vector2(100, 0)
		elif pet_instance.has_method("setup_level"):
			pet_instance.setup_level(GameManager.get_skill_level("pet_chayanne"))
			
	# 2. Chalan con Minigun
	if GameManager.get_skill_level("pet_minigun") > 0:
		if not is_instance_valid(minigun_instance):
			minigun_instance = pet_minigun_scene.instantiate()
			get_parent().get_parent().call_deferred("add_child", minigun_instance)
			minigun_instance.global_position = global_position + Vector2(-100, 0)
		elif minigun_instance.has_method("setup_level"):
			minigun_instance.setup_level(GameManager.get_skill_level("pet_minigun"))
			
	# 3. Espada de Craft
	if GameManager.has_sword_craft:
		if not is_instance_valid(sword_instance):
			sword_instance = sword_craft_scene.instantiate()
			add_child(sword_instance)
