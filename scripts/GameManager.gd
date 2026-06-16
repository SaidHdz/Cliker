extends Node

# --- SEÑALES ---
signal coins_updated(total_coins)
signal enemy_defeated(total_defeated)
signal wave_updated(new_wave)
signal shop_updated
signal gems_updated(total_gems)
signal xp_updated(current_xp, max_xp)
signal level_up(new_level)
signal combo_updated(combo_count)

# --- VARIABLES DE PROGRESO ---
var total_coins: int = 0
var enemies_defeated: int = 0

# --- META-PROGRESIÓN ---
var total_gold: int = 0 
var best_wave: int = 1
var best_time: String = "00:00"

var meta_base_damage: int = 1
var meta_base_health: int = 100
var meta_crit_chance: float = 0.0

var cost_meta_damage: int = 50
var cost_meta_health: int = 50
var cost_meta_crit: int = 100

# --- SISTEMA DE EXPERIENCIA ---
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 10

# --- SISTEMA DE OLEADAS ---
var current_wave: int = 1
var enemies_spawned_this_wave: int = 0
var enemies_killed_in_wave: int = 0
var chests_spawned_this_wave: int = 0 # Límite por ronda
var is_boss_wave: bool = false

# --- SISTEMA DE PRESTIGIO ---
var radish_gems: int = 0
var prestige_multiplier: float = 1.0 

# --- ESTADÍSTICAS DE COMBATE ---
var click_damage: int = 1
var auto_damage: int = 0
var crit_chance: float = 0.0 
var crit_multiplier: float = 2.0
var auto_timer: Timer

# --- HABILIDADES ROGUELITE ---
var has_fire_slice: bool = false
var fire_slice_level: int = 0
var has_mirror_slice: bool = false
var mirror_slice_level: int = 0
var has_explosive_slice: bool = false
var has_toxic_compost: bool = false
var has_double_slice: bool = false
var has_lightning_slice: bool = false
var lightning_level: int = 0
var has_wind_gust: bool = false
var wind_gust_count: int = 0
var has_black_hole: bool = false
var black_hole_level: int = 0
var has_fire_wall: bool = false
var has_knockback_aura: bool = false
var aura_level: int = 0

# --- HABILIDADES DE APOYO ---
var turret_level: int = 0
var shield_level: int = 0
var shield_damage: int = 2

# --- SISTEMA DE COMBO ---
var current_combo: int = 0
var combo_timer: Timer

# --- PERSISTENCIA ---
const SAVE_PATH = "user://savegame.cfg"

func _ready() -> void:
	load_game()
	auto_timer = Timer.new()
	auto_timer.wait_time = 1.0
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	add_child(auto_timer)
	auto_timer.start()
	
	combo_timer = Timer.new()
	combo_timer.wait_time = 2.0 
	combo_timer.one_shot = true
	combo_timer.timeout.connect(_on_combo_timeout)
	add_child(combo_timer)

func add_combo() -> void:
	current_combo += 1
	combo_updated.emit(current_combo)
	combo_timer.start()

func _on_combo_timeout() -> void:
	current_combo = 0
	combo_updated.emit(current_combo)

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("Progreso", "total_gold", total_gold)
	config.set_value("Progreso", "best_wave", best_wave)
	config.set_value("Tienda", "meta_base_damage", meta_base_damage)
	config.set_value("Tienda", "meta_base_health", meta_base_health)
	config.set_value("Tienda", "meta_crit_chance", meta_crit_chance)
	config.set_value("Tienda", "cost_meta_damage", cost_meta_damage)
	config.set_value("Tienda", "cost_meta_health", cost_meta_health)
	config.set_value("Tienda", "cost_meta_crit", cost_meta_crit)
	config.save(SAVE_PATH)

func load_game() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		total_gold = config.get_value("Progreso", "total_gold", 0)
		best_wave = config.get_value("Progreso", "best_wave", 1)
		meta_base_damage = config.get_value("Tienda", "meta_base_damage", 1)
		meta_base_health = config.get_value("Tienda", "meta_base_health", 100)
		meta_crit_chance = config.get_value("Tienda", "meta_crit_chance", 0.0)
		cost_meta_damage = config.get_value("Tienda", "cost_meta_damage", 50)
		cost_meta_health = config.get_value("Tienda", "cost_meta_health", 50)
		cost_meta_crit = config.get_value("Tienda", "cost_meta_crit", 100)

func _on_auto_timer_timeout() -> void:
	if auto_damage > 0:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			for enemy in enemies:
				if is_instance_valid(enemy) and "current_health" in enemy and enemy.current_health > 0:
					enemy.take_damage(int(auto_damage * prestige_multiplier))
					break

func add_coins(amount: int) -> void:
	total_coins += amount
	coins_updated.emit(total_coins)
	shop_updated.emit()

func get_total_enemies_for_current_wave() -> int:
	return 20 + (current_wave * 8)

func notify_enemy_defeated() -> void:
	enemies_defeated += 1
	enemies_killed_in_wave += 1
	enemy_defeated.emit(enemies_defeated)
	if enemies_killed_in_wave >= get_total_enemies_for_current_wave():
		current_wave += 1
		chests_spawned_this_wave = 0 # REINICIO COFRES
		if current_wave > best_wave:
			best_wave = current_wave
			save_game()
		enemies_killed_in_wave = 0
		enemies_spawned_this_wave = 0
		is_boss_wave = (current_wave % 5 == 0)
		wave_updated.emit(current_wave)

func gain_xp(amount: int) -> void:
	current_xp += amount
	if current_xp >= xp_to_next_level:
		var overflow_xp = current_xp - xp_to_next_level
		current_level += 1
		xp_to_next_level = int(xp_to_next_level * 1.5)
		current_xp = 0
		xp_updated.emit(current_xp, xp_to_next_level)
		level_up.emit(current_level)
		if overflow_xp > 0: gain_xp(overflow_xp)
	else:
		xp_updated.emit(current_xp, xp_to_next_level)

func reset_run() -> void:
	get_tree().paused = false
	current_wave = 1
	current_level = 1
	current_xp = 0
	xp_to_next_level = 10
	enemies_killed_in_wave = 0
	enemies_spawned_this_wave = 0
	chests_spawned_this_wave = 0
	is_boss_wave = false
	enemies_defeated = 0
	current_combo = 0
	click_damage = meta_base_damage
	crit_chance = meta_crit_chance
	auto_damage = 0
	has_fire_slice = false
	fire_slice_level = 0
	has_mirror_slice = false
	mirror_slice_level = 0
	has_explosive_slice = false
	has_toxic_compost = false
	has_double_slice = false
	has_lightning_slice = false
	lightning_level = 0
	has_wind_gust = false
	wind_gust_count = 0
	has_black_hole = false
	black_hole_level = 0
	has_fire_wall = false
	has_knockback_aura = false
	aura_level = 0
	turret_level = 0
	shield_level = 0
	shield_damage = 2
	xp_updated.emit(current_xp, xp_to_next_level)
	level_up.emit(current_level)
	wave_updated.emit(current_wave)
	combo_updated.emit(0)
