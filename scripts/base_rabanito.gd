extends Area2D

var max_health: int = 100
var current_health: int = 100

@onready var health_bar: ProgressBar = $ProgressBar

# --- HABILIDADES (ESCENAS - MAYÚSCULAS ANDROID) ---
var seed_scene = preload("res://scenes/seed_projectile.tscn")
var shield_scene = preload("res://scenes/orbital_shield.tscn")

var turret_timer: Timer
var active_shield: Node2D
var aura_timer: Timer

func _ready() -> void:
	# La salud base ahora viene de tu meta-progresión de la tienda
	max_health = GameManager.meta_base_health
	current_health = max_health
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Detectar cuando un enemigo nos toca
	area_entered.connect(_on_area_entered)
	
	# Torreta
	turret_timer = Timer.new(); turret_timer.wait_time = 1.5; turret_timer.timeout.connect(_on_turret_timeout); add_child(turret_timer)
	
	# Aura de Voluntad (Knockback)
	aura_timer = Timer.new()
	aura_timer.wait_time = 5.0
	aura_timer.timeout.connect(_on_aura_timeout)
	add_child(aura_timer)

func _physics_process(_delta: float) -> void:
	# Lógica para activar/actualizar habilidades si suben de nivel
	check_abilities()

func check_abilities() -> void:
	# 1. Gestionar Torreta
	if GameManager.turret_level > 0 and turret_timer.is_stopped():
		turret_timer.start()
		turret_timer.wait_time = max(0.4, 1.5 - (GameManager.turret_level * 0.2))
	
	# 2. Gestionar Escudo
	if GameManager.shield_level > 0 and active_shield == null:
		active_shield = shield_scene.instantiate()
		active_shield.z_index = 5
		call_deferred("add_child", active_shield)
		active_shield.position = Vector2.ZERO # Centrado en el rabanito
		
	# Aura
	if GameManager.aura_level > 0 and aura_timer.is_stopped():
		aura_timer.start()
		aura_timer.wait_time = max(2.0, 5.0 - (GameManager.aura_level * 0.5))

func _on_turret_timeout() -> void:
	var target = get_closest_enemy()
	if target:
		var bullet_count = min(3, GameManager.turret_level)
		var base_dir = global_position.direction_to(target.global_position)
		for i in range(bullet_count):
			var bullet = seed_scene.instantiate()
			bullet.z_index = 10 # Asegurar visibilidad total
			get_parent().add_child(bullet)
			bullet.global_position = global_position
			var angle_offset = (i - (bullet_count-1)/2.0) * 0.2
			bullet.direction = base_dir.rotated(angle_offset)

func get_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var min_dist = 99999.0
	for enemy in enemies:
		if is_instance_valid(enemy) and "current_health" in enemy and enemy.current_health > 0:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = enemy
	return closest

func _on_aura_timeout() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var range_dist = 200 + (GameManager.aura_level * 50)
	var force = 600.0 + (GameManager.aura_level * 100)
	shake_camera(0.2, 10)
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < range_dist:
			var dir = global_position.direction_to(e.global_position)
			if "dispersion_velocity" in e: e.dispersion_velocity = dir * force

func shake_camera(d, i):
	var s = get_tree().current_scene
	if s.has_method("shake_camera"): s.shake_camera(d, i)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("kamikaze_attack"):
			take_damage(5)
			area.kamikaze_attack()

func take_damage(amount: int) -> void:
	current_health -= amount
	health_bar.value = current_health
	if current_health <= 0:
		game_over()

func game_over() -> void:
	print("¡El Rabanito ha caído! GAME OVER")
	var main_scene = get_tree().current_scene
	if main_scene.has_node("CanvasPausa/GameOver"):
		var game_over_screen = main_scene.get_node("CanvasPausa/GameOver")
		if game_over_screen.has_method("show_game_over"): game_over_screen.show_game_over()
		else: game_over_screen.visible = true
	else:
		print("Error: No se encontró el nodo CanvasPausa/GameOver en Main")
