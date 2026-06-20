extends Node2D

@export_group("Debug Settings")
@export var debug_mode: bool = false
@export_enum(
	"fire_slice", "explosive_slice", "fire_wall", "lightning_slice", "shield", 
	"seed_nova", "mining_cart", "thorns", "toxic_aura", "pet_chayanne", 
	"black_hole", "aura", "turret", "pet_minigun", "tornado", "axe_thrower", 
	"satellite", "tamed_alien", "scarecrow", "cosmic_magnet", "boomerang",
	"mirror_slice", "double_slice", "wind_gust", "toxic_compost", 
	"energy_shield", "sword_craft", "earthquake", "auto_speed", 
	"damage_boost", "crit_boost", "infernal_hole"
) var debug_skill_id: String = "fire_slice"
@export_range(1, 5) var debug_skill_level: int = 1
@export var debug_start_wave: int = 1

@onready var spawn_timer: Timer = $Spawner/SpawnTimer
@onready var hud: CanvasLayer = $HUD
@onready var menu_pausa: Control = $CanvasPausa/MenuPausa
@onready var level_up_menu: Control = $CanvasPausa/LevelUpMenu
@onready var chest_menu: Control = $CanvasPausa/ChestSelectionMenu

# Pre-cargamos las escenas
var variant_scenes = {
	0: preload("res://scenes/enemies/AlienNormal.tscn"),
	1: preload("res://scenes/enemies/AlienTanque.tscn"),
	2: preload("res://scenes/enemies/AlienRapido.tscn"),
	3: preload("res://scenes/enemies/AlienKamikaze.tscn"),
	4: preload("res://scenes/enemies/AlienTroya.tscn"),
	5: preload("res://scenes/enemies/AlienCurador.tscn"),
	6: preload("res://scenes/enemies/AlienSniper.tscn"),
	7: preload("res://scenes/enemies/AlienMinero.tscn")
}
var boss_scene = preload("res://scenes/enemies/AlienBoss.tscn")
var bomb_scene = preload("res://scenes/seed_bomb.tscn")
var acid_scene = preload("res://scenes/acid_puddle.tscn")
var toxic_shot_scene = preload("res://scenes/toxic_shot.tscn")
var wind_scene = preload("res://scenes/wind_gust.tscn")
var black_hole_scene = preload("res://scenes/black_hole.tscn")
var fire_wall_scene = preload("res://scenes/fire_wall.tscn")
var chest_scene = preload("res://scenes/chest.tscn")
var mining_cart_scene = preload("res://scenes/mining_cart.tscn")

var steroid_timer: Timer
var steroid_cooldown_timer: Timer
var nuclear_timer: float = 0.0

var active_touches: Dictionary = {}
var barda_line: Line2D
var barda_damage_timer: float = 0.0
var pirate_timer: float = 0.0
var radish_rain_timer: float = 0.0

func _ready() -> void:
	print("Escena Principal: Iniciando...")
	GameManager.increment_stat("matches_played", 1)
	
	barda_line = Line2D.new()
	barda_line.width = 12.0
	barda_line.default_color = Color(0.1, 0.8, 1.0, 0.7) # Celeste brillante semi-transparente
	barda_line.z_index = 10
	barda_line.visible = false
	add_child(barda_line)
	GameManager.save_game()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	
	# Inicializar timers de esteroides
	steroid_timer = Timer.new(); steroid_timer.wait_time = 5.0; steroid_timer.one_shot = true; steroid_timer.timeout.connect(_on_steroid_duration_timeout); add_child(steroid_timer)
	steroid_cooldown_timer = Timer.new(); steroid_cooldown_timer.wait_time = 12.0; steroid_cooldown_timer.one_shot = true; steroid_cooldown_timer.timeout.connect(_on_steroid_cooldown_timeout); add_child(steroid_cooldown_timer)
	
	# Reconexión segura de señales
	if GameManager.wave_updated.is_connected(_on_wave_updated): GameManager.wave_updated.disconnect(_on_wave_updated)
	GameManager.wave_updated.connect(_on_wave_updated)
	
	if GameManager.level_up.is_connected(_on_level_up): GameManager.level_up.disconnect(_on_level_up)
	GameManager.level_up.connect(_on_level_up)
	
	if GameManager.chest_opened.is_connected(_on_chest_opened): GameManager.chest_opened.disconnect(_on_chest_opened)
	GameManager.chest_opened.connect(_on_chest_opened)
	
	if is_instance_valid(hud) and hud.has_signal("pause_requested"):
		if hud.pause_requested.is_connected(_on_pause_requested): hud.pause_requested.disconnect(_on_pause_requested)
		hud.pause_requested.connect(_on_pause_requested)
		
	if is_instance_valid(spawn_timer):
		if spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
			spawn_timer.timeout.disconnect(_on_spawn_timer_timeout)
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		
	# Limpiar estelas
	if is_instance_valid(trail): trail.clear_points()
	
	# Lógica del modo Debug para forzar niveles de habilidad
	if debug_mode and debug_skill_id != "":
		GameManager.skill_levels.clear()
		GameManager.skill_levels[debug_skill_id] = debug_skill_level
		GameManager._apply_skill_instantly(debug_skill_id)
		GameManager.skill_levels[debug_skill_id] = debug_skill_level
		print("--- DEBUG MODE ACTIVE --- Forzando habilidad: ", debug_skill_id, " a Nivel: ", debug_skill_level)
	
	if debug_mode and debug_start_wave > 1:
		GameManager.current_wave = debug_start_wave
		GameManager.enemies_killed_in_wave = 0
		GameManager.enemies_spawned_this_wave = 0
		GameManager.chests_spawned_this_wave = 0
		GameManager.is_boss_wave = (GameManager.current_wave % 5 == 0)
		GameManager.wave_updated.emit(GameManager.current_wave)
		print("--- DEBUG MODE ACTIVE --- Iniciando en Oleada: ", debug_start_wave)
	
	await get_tree().create_timer(0.5).timeout
	_on_wave_updated(GameManager.current_wave)
	
	if GameManager.pending_level_ups > 0:
		_on_level_up(GameManager.current_level)
		
	if GameManager.has_mining_cart or GameManager.campesino_extremo_rounds > 0:
		_spawn_mining_cart()
		
	if GameManager.steroids_rounds > 0:
		activate_steroids()
		
	if GameManager.get_skill_level("sayonara") >= 1:
		activate_sayonara()
		
	if not GameManager.tutorial_completed:
		start_tutorial()
	else:
		if is_instance_valid(spawn_timer): 
			spawn_timer.start()
			print("DEBUG: SpawnTimer encendido. Oleada: ", GameManager.current_wave)

func _spawn_mining_cart() -> void:
	if has_node("MiningPath") and is_instance_valid(mining_cart_scene):
		var cart = mining_cart_scene.instantiate()
		$MiningPath/PathFollow2D.add_child(cart)

func _on_level_up(_new_level: int) -> void:
	if is_instance_valid(level_up_menu) and level_up_menu.has_method("show_menu"):
		level_up_menu.show_menu()
		AudioManager.play("coin_pickup")
		shake_camera(0.2, 8)

func _on_chest_opened() -> void:
	GameManager.increment_stat("chests_opened", 1)
	GameManager.save_game()
	if is_instance_valid(chest_menu) and chest_menu.has_method("show_menu"):
		chest_menu.show_menu()

func _on_pause_requested() -> void:
	if is_instance_valid(menu_pausa) and menu_pausa.has_method("toggle_pause"):
		menu_pausa.toggle_pause()

func _on_wave_updated(new_wave: int) -> void:
	var base_time = 1.5
	var new_time = base_time * pow(0.78, new_wave - 1)
	if is_instance_valid(spawn_timer): 
		spawn_timer.wait_time = max(0.2, new_time)
	
	# --- RE-INSTANCIAR ACTIVOS AL INICIO DE OLEADA (OPCIONAL) ---
	_check_active_skills()

func _check_active_skills() -> void:
	# Spawns por oleada
	if GameManager.get_skill_level("tornado") >= 1: _spawn_tornado()
	
	# Spawns que no deben duplicarse si ya existen
	var sc = get_tree().get_nodes_in_group("BaseRabanito")
	var has_scarecrow = false
	for n in sc: if n.name.begins_with("Scarecrow"): has_scarecrow = true
	if GameManager.get_skill_level("scarecrow") >= 1 and not has_scarecrow: _spawn_scarecrow()
	
	var allies = get_tree().get_nodes_in_group("allies")
	var has_alien = false
	for n in allies: if n.name.begins_with("TamedAlien"): has_alien = true
	if GameManager.get_skill_level("tamed_alien") >= 1 and not has_alien: _spawn_ally_alien()
	
	if GameManager.get_skill_level("axe_thrower") >= 1 and not has_node("AxeThrower"): _spawn_axe_thrower()
	if GameManager.get_skill_level("satellite") >= 1 and not has_node("Satellite"): _spawn_satellite()
	if GameManager.get_skill_level("boomerang") >= 1 and not has_node("Boomerang"): _spawn_boomerang()
	if GameManager.get_skill_level("mining_cart") >= 1 or GameManager.campesino_extremo_rounds > 0:
		if has_node("MiningPath/PathFollow2D"):
			# Si el PathFollow2D no tiene hijos, significa que no hay carrito. ¡Invocalo!
			if $MiningPath/PathFollow2D.get_child_count() == 0:
				_spawn_mining_cart()
	else:
		if has_node("MiningPath/PathFollow2D") and $MiningPath/PathFollow2D.get_child_count() > 0:
			for child in $MiningPath/PathFollow2D.get_children():
				child.queue_free()

func _spawn_tornado() -> void:
	var lvl = GameManager.get_skill_level("tornado")
	var count = 2 if lvl >= 5 else 1
	
	var active_count = 0
	for child in get_children():
		if child.name.begins_with("Tornado"):
			active_count += 1
			
	var to_spawn = count - active_count
	for i in range(to_spawn):
		var t = load("res://scenes/tornado.tscn").instantiate()
		t.name = "Tornado_" + str(Time.get_ticks_msec()) + "_" + str(i)
		add_child(t)
		t.global_position = get_viewport_rect().size / 2.0 + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		if t.has_method("setup_level"): t.setup_level(lvl)

func _spawn_scarecrow() -> void:
	var lvl = GameManager.get_skill_level("scarecrow")
	var s = load("res://scenes/scarecrow.tscn").instantiate()
	s.name = "Scarecrow" + str(Time.get_ticks_msec())
	add_child(s)
	s.global_position = get_viewport_rect().size / 2.0 + Vector2(randf_range(-200, 200), randf_range(100, 200))
	if s.has_method("setup_level"): s.setup_level(lvl)

func _spawn_ally_alien() -> void:
	var lvl = GameManager.get_skill_level("tamed_alien")
	var a = load("res://scenes/allies/tamed_alien.tscn").instantiate()
	a.name = "TamedAlien" + str(Time.get_ticks_msec())
	add_child(a)
	a.global_position = get_viewport_rect().size / 2.0
	if a.has_method("setup_level"): a.setup_level(lvl)

func _spawn_axe_thrower() -> void:
	var lvl = GameManager.get_skill_level("axe_thrower")
	var script_node = Node2D.new()
	script_node.name = "AxeThrower"
	script_node.set_script(load("res://scripts/AxeThrower.gd"))
	add_child(script_node)
	script_node.setup_level(lvl)

func _spawn_satellite() -> void:
	var lvl = GameManager.get_skill_level("satellite")
	var script_node = Node2D.new()
	script_node.name = "Satellite"
	script_node.set_script(load("res://scripts/Satellite.gd"))
	add_child(script_node)
	script_node.setup_level(lvl)

func _spawn_boomerang() -> void:
	var lvl = GameManager.get_skill_level("boomerang")
	var script_node = Node2D.new()
	script_node.name = "Boomerang"
	script_node.set_script(load("res://scripts/Boomerang.gd"))
	add_child(script_node)
	script_node.setup_level(lvl)

func _on_spawn_timer_timeout() -> void:
	var total = GameManager.get_total_enemies_for_current_wave()
	if GameManager.enemies_spawned_this_wave < total:
		spawn_enemy()
		_check_active_skills()

@onready var spawn_zone: ReferenceRect = $SpawnZone
@onready var trail: Line2D = $Trail
@onready var mirror_trail: Line2D = get_node_or_null("TrailMirror")
@onready var double_trail: Line2D = get_node_or_null("TrailDouble")

var is_slicing: bool = false
var last_slice_pos: Vector2 = Vector2.ZERO
var slice_start_time: float = 0.0
var tutorial_step: int = 0
var tutorial_overlay: ColorRect = null
var tutorial_label: Label = null

func _get_event_global_pos(event: InputEvent) -> Vector2:
	# On mobile, touch/drag events store the actual finger position in event.position.
	# get_global_mouse_position() does NOT update during a touch drag on Android/iOS,
	# so we must convert event.position through the canvas transform ourselves.
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		return get_canvas_transform().affine_inverse() * event.position
	return get_global_mouse_position()

func _input(event: InputEvent) -> void:
	# Registro multitáctil y mouse
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = _get_event_global_pos(event)
		else:
			active_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		active_touches[event.index] = _get_event_global_pos(event)
	elif event is InputEventMouseButton:
		if event.pressed:
			active_touches[0] = _get_event_global_pos(event)
		else:
			active_touches.erase(0)
	elif event is InputEventMouseMotion:
		if is_slicing:
			active_touches[0] = _get_event_global_pos(event)
		else:
			active_touches.erase(0)

	if event is InputEventMouseButton or event is InputEventScreenTouch:
		is_slicing = event.pressed
		if is_slicing:
			last_slice_pos = _get_event_global_pos(event)
			slice_start_time = Time.get_ticks_msec() / 1000.0
			_update_trails(last_slice_pos, true)
		else:
			_check_wind_gust(_get_event_global_pos(event))
			_update_trails(Vector2.ZERO, false)

	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_slicing:
		var current_pos = _get_event_global_pos(event)
		_update_trails(current_pos, false)
		check_slice_collision(last_slice_pos, current_pos)
		last_slice_pos = current_pos

func _update_trails(pos: Vector2, clear: bool) -> void:
	var trails = [trail, mirror_trail, double_trail]
	for t in trails:
		if not is_instance_valid(t): continue
		if clear: t.clear_points()
		if pos != Vector2.ZERO:
			var target_pos = pos
			if t == mirror_trail: 
				if GameManager.has_mirror_slice: target_pos = get_mirrored_pos(pos)
				else: continue
			elif t == double_trail:
				if GameManager.has_double_slice: target_pos = pos + Vector2(40, 40)
				else: continue
			t.add_point(target_pos)
			if t.points.size() > 8: t.remove_point(0)
		elif not is_slicing: t.clear_points()

func _check_wind_gust(end_pos: Vector2) -> void:
	if not GameManager.has_wind_gust or GameManager.wind_gust_count <= 0: return
	var duration = (Time.get_ticks_msec() / 1000.0) - slice_start_time
	var distance = last_slice_pos.distance_to(end_pos)
	var speed = distance / max(0.001, duration)
	if speed > 1000.0:
		for i in range(GameManager.wind_gust_count):
			var wind = wind_scene.instantiate()
			get_parent().add_child(wind); wind.global_position = last_slice_pos + Vector2(randf_range(-40,40), randf_range(-40,40))
			if "direction" in wind: wind.direction = last_slice_pos.direction_to(end_pos)

func get_mirrored_pos(pos: Vector2) -> Vector2:
	var base = get_tree().get_first_node_in_group("BaseRabanito")
	return base.global_position - (pos - base.global_position) if base else pos

func check_slice_collision(start_pos: Vector2, end_pos: Vector2) -> void:
	_perform_raycast_slice(start_pos, end_pos)
	if GameManager.has_double_slice:
		var dir = (end_pos - start_pos).normalized(); var ortho = Vector2(-dir.y, dir.x) * 40.0
		_perform_raycast_slice(start_pos + ortho, end_pos + ortho)
		_perform_raycast_slice(start_pos - ortho, end_pos - ortho)
	if GameManager.has_mirror_slice:
		_perform_raycast_slice(get_mirrored_pos(start_pos), get_mirrored_pos(end_pos))

func _perform_raycast_slice(start: Vector2, end: Vector2) -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start, end)
	query.collide_with_areas = true; query.collide_with_bodies = true
	var hits = 0        # Sólo cuenta colisiones útiles (enemigos/cofres/orbs)
	var traversals = 0  # Total de colisiones procesadas (para evitar bucle infinito)
	
	while hits < 10 and traversals < 40:
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result.collider
			traversals += 1
			
			var is_relevant = false
			if collider.is_in_group("enemies"):
				if collider.has_method("take_damage"): _on_enemy_sliced(collider)
				is_relevant = true
			elif collider.is_in_group("chests"):
				# Los cofres reciben daño limpio, sin desencadenar agujeros negros ni combos
				if collider.has_method("take_damage"): 
					var dmg = int(GameManager.click_damage * GameManager.prestige_multiplier)
					collider.take_damage(dmg)
				is_relevant = true
			elif collider.is_in_group("orbs") and collider.has_method("magnetize_to"):
				var base = get_tree().get_first_node_in_group("BaseRabanito")
				if base: collider.magnetize_to(base.global_position)
				is_relevant = true
			# Si no es relevante (auras, hojas del escudo, etc.) lo ignoramos
			# pero igual lo excluimos para evitar bucle infinito
				
			var new_exclude = query.exclude.duplicate()
			new_exclude.append(collider.get_rid())
			query.exclude = new_exclude
			if is_relevant:
				hits += 1
		else: 
			break

func _on_enemy_sliced(enemy: Node2D) -> void:
	# 1. BLINDAJE: Evita acribillar cadáveres por el drag de la pantalla táctil
	if "current_health" in enemy and enemy.current_health <= 0:
		return
		
	GameManager.increment_stat("finger_cuts", 1)
	GameManager.increment_stat("kilometers_cut", 0.001)

	var final_crit_chance = GameManager.crit_chance
	var crit_boost_lvl = GameManager.get_skill_level("crit_boost")
	if crit_boost_lvl > 0:
		var enemy_count = get_tree().get_nodes_in_group("enemies").size()
		var meta_lvl = GameManager.get_card_upgrade_int_level("crit_boost")
		var crit_boost_meta = GameManager.card_upgrade_levels.get("crit_boost", 0)
		var is_spec = (typeof(crit_boost_meta) == TYPE_STRING and crit_boost_meta == "4_spec")
		
		var percent_per_enemy = 0.01 + (crit_boost_lvl - 1) * 0.002 + meta_lvl * 0.002
		var max_boost = 0.40 + meta_lvl * 0.05
		if is_spec:
			percent_per_enemy += 0.004
			max_boost += 0.10
			
		var boost = min(enemy_count * percent_per_enemy, max_boost)
		final_crit_chance += boost

	var is_crit = randf() < final_crit_chance
	var damage = int(GameManager.click_damage * GameManager.prestige_multiplier * GameManager.steroid_multiplier)
	var damage_type = "normal"
	
	if GameManager.has_fire_slice: damage_type = "fire"
	if GameManager.has_lightning_slice: damage_type = "electric"
	
	var enemy_pos = enemy.global_position 
	
	if is_crit: 
		var crit_mult = GameManager.crit_multiplier
		var crit_boost_meta = GameManager.card_upgrade_levels.get("crit_boost", 0)
		var is_crit_spec = (GameManager.get_skill_level("crit_boost") > 0 and typeof(crit_boost_meta) == TYPE_STRING and crit_boost_meta == "4_spec")
		if is_crit_spec:
			crit_mult = 3.0
		damage = int(damage * crit_mult)
		AudioManager.play("crit")
		shake_camera(0.1, 5)
	else: 
		AudioManager.play("pop")
		
	# 2. APLICAMOS EL DAÑO
	enemy.take_damage(damage, is_crit, damage_type)
	if GameManager.get_skill_level("damage_boost") > 0 and enemy.has_method("apply_bleed"):
		enemy.apply_bleed()
	GameManager.add_combo()
	
	if not GameManager.tutorial_completed and tutorial_step == 1:
		advance_tutorial()
	
	# 3. EFECTOS ESPECIALES (Usando add_child directo para evitar fugas al root)
	if GameManager.has_lightning_slice and GameManager.get_skill_level("lightning_slice") != 0: 
		_perform_chain_lightning(enemy)
		
		# ¡Gatillo para el Nivel 5: Tormenta de Rayos del Cielo!
		var lightning_lvl_val = GameManager.get_skill_level("lightning_slice")
		var lightning_lvl = 4 if typeof(lightning_lvl_val) == TYPE_STRING else lightning_lvl_val
		if lightning_lvl >= 5:
			_trigger_random_storm(enemy_pos) # Le pasamos la posición donde cortaste
	
	var explosive_lvl = GameManager.get_skill_level("explosive_slice")
	if explosive_lvl >= 1:
		var prob = 0.05
		if explosive_lvl >= 5: prob = 0.08 
		
		if randf() < prob:
			var b = bomb_scene.instantiate()
			b.z_index = 3
			call_deferred("add_child", b) # Corregido
			b.global_position = enemy_pos
			if b.has_method("setup_level"): b.setup_level(explosive_lvl)

	if GameManager.has_black_hole and randf() < 0.01:
		var bh = black_hole_scene.instantiate()
		call_deferred("add_child", bh) # Corregido
		bh.global_position = enemy_pos
		
	if GameManager.has_fire_wall and randf() < 0.10:
		var fw = fire_wall_scene.instantiate()
		call_deferred("add_child", fw) # Corregido
		fw.global_position = enemy_pos
		
func _perform_chain_lightning(source: Node2D) -> void:
	var current_lvl_val = GameManager.get_skill_level("lightning_slice")
	var lvl = 4 if typeof(current_lvl_val) == TYPE_STRING else current_lvl_val
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = 0; var last = source
	
	var max_hits = 2 # Nivel 1: 2 rebotes
	if lvl >= 3: max_hits += 1 # Nivel 3: Velocidad de rebote (Simulamos un hit extra o más rápido visualmente, pondremos hit extra)
	
	var range_dist = 150
	if lvl >= 2: range_dist = 250 # Nivel 2: Busca más lejos
	
	# Nivel 4 Especial: Conductor Perfecto (Prioriza enemigos especiales)
	var prioritize_special = (typeof(current_lvl_val) == TYPE_STRING and current_lvl_val == "4_spec")
	
	var valid_targets = []
	for e in enemies:
		if is_instance_valid(e) and e != last and "current_health" in e and not e.get("is_underground"):
			if last.global_position.distance_to(e.global_position) < range_dist:
				valid_targets.append(e)
				
	if prioritize_special:
		valid_targets.sort_custom(func(a, b):
			var a_spec = a.current_variant != 0 or a.is_boss
			var b_spec = b.current_variant != 0 or b.is_boss
			if a_spec and not b_spec: return true
			return false
		)
	else:
		# Si no prioriza especial, ordenamos por distancia al último hit
		valid_targets.sort_custom(func(a, b): return last.global_position.distance_to(a.global_position) < last.global_position.distance_to(b.global_position))
	
	var damage_mult = 1.0
	for e in valid_targets:
		if count >= max_hits: break
		
		var meta_bonus = GameManager.get_card_upgrade_int_level("lightning_slice") * 1
		var base_damage = int(GameManager.click_damage * 0.4) + meta_bonus
		
		e.take_damage(int(base_damage * damage_mult))
		_draw_lightning_bolt(last.global_position, e.global_position)
		if e.has_method("apply_lightning_effect"): e.apply_lightning_effect()
		count += 1; last = e

func _trigger_random_storm(origin_pos: Vector2) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_targets = []
	var radius_sq = 250.0 * 250.0 # Radio de búsqueda alrededor del tajo
	
	# 1. Filtrar enemigos vivos y cercanos
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			if origin_pos.distance_squared_to(e.global_position) < radius_sq:
				valid_targets.append(e)
				
	# 2. Si hay pocos enemigos cerca, reclutamos del resto del mapa para no perder potencia
	if valid_targets.size() < 3:
		for e in enemies:
			if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
				if e not in valid_targets:
					valid_targets.append(e)
					
	# Mezclamos la lista para que la selección sea orgánica
	valid_targets.shuffle()
	var max_rays = min(valid_targets.size(), 3) # Caerán hasta 3 rayos del cielo por tajo
	
	for i in range(max_rays):
		var target = valid_targets[i]
		# Metemos un pequeño delay consecutivo (0s, 0.15s, 0.3s) para un efecto visual letal
		var delay = i * 0.15
		get_tree().create_timer(delay).timeout.connect(_execute_sky_strike.bind(target))

func _execute_sky_strike(target: Node2D) -> void:
	# Verificación de seguridad por si el enemigo murió o se sumergió
	if is_instance_valid(target) and "current_health" in target and target.current_health > 0 and not target.get("is_underground"):
		# Igual que el satélite: Calculamos un punto de inicio a -600 píxeles en Y (fuera de pantalla)
		var sky_start = target.global_position + Vector2(randf_range(-30, 30), -600)
		
		# Dibujamos el rayo usando tu sistema de Line2D existente
		_draw_lightning_bolt(sky_start, target.global_position)
		
		# Aplicamos daño masivo de rayo celestial (x2 del daño de click)
		if target.has_method("take_damage"):
			target.take_damage(int(GameManager.click_damage * 2.0), false, "electric")
			
		if target.has_method("apply_lightning_effect"):
			target.apply_lightning_effect()
			
		# Cada impacto sacude la pantalla de forma independiente
		shake_camera(0.1, 6)

func _draw_lightning_bolt(pos1: Vector2, pos2: Vector2) -> void:
	var main_line = Line2D.new()
	main_line.width = 6.0
	main_line.default_color = Color(0.2, 0.7, 1.0, 0.8) # Cian resplandeciente
	main_line.z_index = 15
	add_child(main_line)

	var core_line = Line2D.new()
	core_line.width = 1.8
	core_line.default_color = Color(1.0, 1.0, 1.0, 1.0) # Núcleo blanco puro
	core_line.z_index = 16
	add_child(core_line)

	var segments = 6
	var points = []
	points.append(pos1)
	for i in range(1, segments):
		var t_ratio = float(i) / segments
		var base_pos = pos1.lerp(pos2, t_ratio)
		var offset = (pos2 - pos1).orthogonal().normalized() * randf_range(-15, 15)
		points.append(base_pos + offset)
	points.append(pos2)

	for p in points:
		main_line.add_point(p)
		core_line.add_point(p)

	if randf() < 0.7:
		var branch_idx = randi_range(2, 4)
		var branch_start = points[branch_idx]
		var branch_dir = (pos2 - pos1).rotated(randf_range(-0.5, 0.5)).normalized()
		var branch_end = branch_start + branch_dir * randf_range(40, 100)
		
		var branch_line = Line2D.new()
		branch_line.width = 2.0
		branch_line.default_color = Color(0.4, 0.8, 1.0, 0.8)
		branch_line.z_index = 14
		add_child(branch_line)
		
		branch_line.add_point(branch_start)
		branch_line.add_point((branch_start + branch_end)/2.0 + branch_dir.orthogonal() * randf_range(-10, 10))
		branch_line.add_point(branch_end)
		
		var bt = create_tween()
		bt.parallel().tween_property(branch_line, "width", 0.0, 0.25)
		bt.parallel().tween_property(branch_line, "modulate:a", 0.0, 0.25)
		bt.finished.connect(branch_line.queue_free)

	var t = create_tween()
	t.parallel().tween_property(main_line, "width", 0.0, 0.25)
	t.parallel().tween_property(main_line, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(core_line, "width", 0.0, 0.2)
	t.parallel().tween_property(core_line, "modulate:a", 0.0, 0.2)
	t.finished.connect(func():
		main_line.queue_free()
		core_line.queue_free()
	)

# --- SPAWNER ---
func spawn_enemy() -> void:
	var total = GameManager.get_total_enemies_for_current_wave()
	var is_boss_time = (GameManager.current_wave % 5 == 0) and (GameManager.enemies_spawned_this_wave + 1 >= total)
	
	# Usar SpawnZone si es válido, si no, Viewport
	var zone_rect: Rect2
	if is_instance_valid(spawn_zone) and spawn_zone.size.x > 10:
		zone_rect = spawn_zone.get_global_rect()
	else:
		var view = get_viewport_rect().size
		zone_rect = Rect2(Vector2.ZERO, view)

	var spawn_pos = Vector2.ZERO; var side = randi() % 4
	match side:
		0: spawn_pos = Vector2(randf_range(zone_rect.position.x, zone_rect.end.x), zone_rect.position.y)
		1: spawn_pos = Vector2(randf_range(zone_rect.position.x, zone_rect.end.x), zone_rect.end.y)
		2: spawn_pos = Vector2(zone_rect.position.x, randf_range(zone_rect.position.y, zone_rect.end.y))
		3: spawn_pos = Vector2(zone_rect.end.x, randf_range(zone_rect.position.y, zone_rect.end.y))

	if is_boss_time:
		print("DEBUG Spawner: Spawneando BOSS")
		spawn_boss(spawn_pos)
	# Cofres: 20% de probabilidad cada 4 niveles (oleadas)
	elif GameManager.current_wave % 4 == 0 and randf() < 0.20 and GameManager.chests_spawned_this_wave < 1:
		GameManager.chests_spawned_this_wave += 1
		print("DEBUG Spawner: Spawneando COFRE")
		spawn_chest()
	else:
		var r = randf(); var v = 0
		var wave = GameManager.current_wave
		
		if wave <= 5:
			# Tier 1: Normal, Rapido, Kamikaze, Sniper
			if r < 0.10: v = 3 # KAMIKAZE
			elif r < 0.25: v = 6 # SNIPER
			elif r < 0.60: v = 2 # RUNNER
			else: v = 0 # NORMAL
		elif wave <= 10:
			# Tier 2: Se suman Troya, Curador, Tanque
			if r < 0.05: v = 3 # KAMIKAZE
			elif r < 0.15: v = 4 # TROJAN
			elif r < 0.25: v = 5 # HEALER
			elif r < 0.35: v = 6 # SNIPER
			elif r < 0.55: v = 1 # TANK
			elif r < 0.75: v = 2 # RUNNER
			else: v = 0 # NORMAL
		else:
			# Tier 3: Llegan todos (se suma Minero)
			if r < 0.05: v = 3 # KAMIKAZE
			elif r < 0.10: v = 4 # TROJAN
			elif r < 0.15: v = 5 # HEALER
			elif r < 0.25: v = 6 # SNIPER
			elif r < 0.35: v = 7 # MINER
			elif r < 0.55: v = 1 # TANK
			elif r < 0.75: v = 2 # RUNNER
			else: v = 0 # NORMAL

		spawn_variant_at(v, spawn_pos)

func spawn_boss(pos: Vector2) -> void:
	GameManager.enemies_spawned_this_wave += 1
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = pos
	
	if "anim" in boss: boss.anim.speed_scale = 0.6
	shake_camera(0.8, 20)
	print("¡ALERTA! JEFE SPAWNEADO EN OLEADA ", GameManager.current_wave)

func spawn_chest() -> void:
	var zone_rect: Rect2
	if is_instance_valid(spawn_zone) and spawn_zone.size.x > 10: zone_rect = spawn_zone.get_global_rect()
	else: zone_rect = Rect2(Vector2.ZERO, get_viewport_rect().size)
	
	var spawn_pos = Vector2(randf_range(zone_rect.position.x + 50, zone_rect.end.x - 50), randf_range(zone_rect.position.y + 50, zone_rect.end.y - 50))
	var chest = chest_scene.instantiate()
	add_child(chest)
	chest.global_position = spawn_pos

func spawn_variant_at(variant: int, pos: Vector2) -> Node2D:
	if not is_instance_valid(self): return null
	if not variant_scenes.has(variant): return null
	
	GameManager.enemies_spawned_this_wave += 1
	var enemy_instance = variant_scenes[variant].instantiate()
	add_child(enemy_instance)
	enemy_instance.global_position = pos
	
	return enemy_instance

func shake_camera(duration: float, intensity: float):
	if not GameManager.screen_shake_enabled: return
	GameManager.increment_stat("screens_shaken", 1)
	var camera = get_node_or_null("Camera2D")
	if not is_instance_valid(camera): return
	var tween = create_tween()
	for i in range(int(duration * 50)):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, 0.02)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

# --- RECOMPENSAS DE COFRE ---

func activate_sayonara() -> void:
	print("¡SAYONARA!")
	# Detener el tiempo visualmente (opcional) y explotar todo
	shake_camera(1.0, 20)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("die") and not enemy.is_in_group("bosses"):
			enemy.die()

func activate_steroids() -> void:
	if steroid_cooldown_timer.is_stopped():
		print("¡ESTEROIDES ACTIVADOS!")
		GameManager.is_steroid_mode = true
		GameManager.steroid_multiplier = 3.0
		var base = get_tree().get_first_node_in_group("BaseRabanito")
		if base:
			var t = create_tween()
			t.set_parallel(true)
			t.tween_property(base, "scale", Vector2(2, 2), 0.5)
			t.tween_property(base, "modulate", Color.ORANGE, 0.5)
		steroid_timer.start()

func _on_steroid_duration_timeout() -> void:
	print("Efecto de esteroides terminado. Enfriamiento iniciado...")
	GameManager.is_steroid_mode = false
	GameManager.steroid_multiplier = 1.0
	var base = get_tree().get_first_node_in_group("BaseRabanito")
	if base:
		var t = create_tween()
		t.set_parallel(true)
		t.tween_property(base, "scale", Vector2(1, 1), 0.5)
		t.tween_property(base, "modulate", Color.WHITE, 0.5)
	steroid_cooldown_timer.start()

func _on_steroid_cooldown_timeout() -> void:
	print("Esteroides listos para usarse de nuevo.")
	# Si todavía quedan rondas de la recompensa, se podrían reactivar automáticamente aquí 
	# si el jugador está en medio de una oleada. Pero según el GameManager, steroids_rounds 
	# solo baja al final de la oleada.
	if GameManager.steroids_rounds > 0:
		activate_steroids()

func activate_conqueror_aura() -> void:
	print("¡PULSO DE CONQUISTADOR!")
	shake_camera(0.5, 15)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage") and not enemy.is_in_group("bosses"):
			enemy.take_damage(100, true) # Daño masivo de limpieza

func force_update_skills() -> void:
	_check_active_skills()
	var base = get_tree().get_first_node_in_group("BaseRabanito")
	if base and base.has_method("update_components"):
		base.update_components()
	for ally in get_tree().get_nodes_in_group("allies"):
		if is_instance_valid(ally):
			if ally.has_method("_apply_stats"):
				ally._apply_stats()
			elif ally.has_method("setup_level"):
				var skill_id = ""
				if ally.name.begins_with("TamedAlien"):
					skill_id = "tamed_alien"
				elif ally.name.begins_with("MiningCart") or "speed_mult" in ally:
					skill_id = "mining_cart"
				elif ally.name.begins_with("AxeThrower"):
					skill_id = "axe_thrower"
				elif ally.name.begins_with("Satellite"):
					skill_id = "satellite"
				elif ally.name.begins_with("Boomerang"):
					skill_id = "boomerang"
				
				if skill_id != "":
					var lvl = GameManager.get_skill_level(skill_id)
					if skill_id == "tamed_alien" and ally.scale.x < 0.8:
						ally.setup_level(1)
					else:
						ally.setup_level(lvl)

# --- TUTORIAL DE INICIO ---

func start_tutorial() -> void:
	tutorial_step = 1
	
	var center = Vector2(480, 270)
	var view_size = get_viewport_rect().size
	if view_size.x > 0:
		center = view_size / 2.0
		
	var enemy = spawn_variant_at(0, center)
	if enemy:
		enemy.move_speed = 0.0
		
	# Crear panel de diálogo
	tutorial_overlay = ColorRect.new()
	tutorial_overlay.color = Color(0, 0, 0, 0) # Transparente para permitir los tajos
	tutorial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if is_instance_valid(hud):
		hud.add_child(tutorial_overlay)
	else:
		add_child(tutorial_overlay)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 130)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -150
	panel.offset_bottom = -20
	panel.offset_left = 30
	panel.offset_right = -30
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.5, 0.8, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	tutorial_overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var label = Label.new()
	label.name = "DialogueLabel"
	tutorial_label = label
	label.text = "jej, hola tonto, corta a los aliens con tus dedos, anda, es divertido"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var label_font = preload("res://scenes/Font.tres")
	label.label_settings = label_font
	label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(label)

func advance_tutorial() -> void:
	tutorial_step = 2
	if not is_instance_valid(tutorial_overlay) or not is_instance_valid(tutorial_label): return
	
	tutorial_label.text = "ves? ahora matalos a todos"
	
	var vbox = tutorial_label.get_parent() as VBoxContainer
	if vbox:
		if vbox.has_node("BtnFinishTutorial"): return
		var btn = Button.new()
		btn.name = "BtnFinishTutorial"
		btn.text = "FIN DEL TUTORIAL"
		btn.custom_minimum_size = Vector2(180, 36)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var button_font = preload("res://assets/fuentes/BoldPixels.ttf")
		btn.add_theme_font_override("font", button_font)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func():
			finish_tutorial()
		)
		vbox.add_child(btn)

func finish_tutorial() -> void:
	if is_instance_valid(tutorial_overlay):
		tutorial_overlay.queue_free()
	GameManager.tutorial_completed = true
	GameManager.save_game()
	
	# Matar los aliens del tutorial que sigan inmóviles
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and "move_speed" in enemy and enemy.move_speed == 0.0:
			enemy.die()
			
	if is_instance_valid(spawn_timer):
		spawn_timer.start()
		print("DEBUG: SpawnTimer encendido post-tutorial. Oleada: ", GameManager.current_wave)

func _physics_process(delta: float) -> void:
	# Lógica de "barda" o tajo continuo con dos dedos
	if active_touches.size() >= 2:
		var keys = active_touches.keys()
		var p1 = active_touches[keys[0]]
		var p2 = active_touches[keys[1]]
		
		# Actualizar línea visual
		if is_instance_valid(barda_line):
			barda_line.clear_points()
			barda_line.add_point(p1)
			barda_line.add_point(p2)
			barda_line.visible = true
			
		# Aplicar daño periódico
		barda_damage_timer += delta
		if barda_damage_timer >= 0.15:
			barda_damage_timer = 0.0
			var enemies = get_tree().get_nodes_in_group("enemies")
			for enemy in enemies:
				if is_instance_valid(enemy) and "current_health" in enemy and enemy.current_health > 0:
					var dist = _distance_to_segment(enemy.global_position, p1, p2)
					if dist < 45.0: # Rango de la barda
						if enemy.has_method("take_damage"):
							var dmg = int(GameManager.click_damage * GameManager.prestige_multiplier * GameManager.steroid_multiplier)
							enemy.take_damage(dmg, false, "normal")
	else:
		if is_instance_valid(barda_line) and barda_line.visible:
			barda_line.visible = false
			barda_line.clear_points()

	# 1. Campesino Extremo (Recogida automática de monedas, orbes y cofres)
	if GameManager.campesino_extremo_rounds > 0:
		var base = get_tree().get_first_node_in_group("BaseRabanito")
		if base:
			for coin in get_tree().get_nodes_in_group("coins"):
				if is_instance_valid(coin) and coin.has_method("magnetize_to") and not coin.get("is_magnetized"):
					coin.magnetize_to(base.global_position)
			for orb in get_tree().get_nodes_in_group("orbs"):
				if is_instance_valid(orb) and orb.has_method("magnetize_to") and not orb.get("is_magnetized"):
					orb.magnetize_to(base.global_position)
			for chest in get_tree().get_nodes_in_group("chests"):
				if is_instance_valid(chest) and chest.has_method("explode"):
					chest.explode()

	# 2. Reactor Nuclear (Explosión nuclear aleatoria cada 8s)
	if GameManager.reactor_nuclear_rounds > 0:
		nuclear_timer += delta
		if nuclear_timer >= 8.0:
			nuclear_timer = 0.0
			_execute_nuclear_explosion()

	# 3. Señal Pirata (Láser orbital pirata cada 6s)
	if GameManager.senal_pirata_rounds > 0:
		pirate_timer += delta
		if pirate_timer >= 6.0:
			pirate_timer = 0.0
			_trigger_pirate_laser()

	# 4. Lluvia de Rábanos (Rábanos gigantes cayendo del cielo cada 1s)
	if GameManager.lluvia_rabanos_rounds > 0:
		radish_rain_timer += delta
		if radish_rain_timer >= 1.0:
			radish_rain_timer = 0.0
			_trigger_radish_rain()

func _execute_nuclear_explosion() -> void:
	shake_camera(1.2, 30)
	AudioManager.play("crit")
	GameManager.increment_stat("explosions_caused", 1)
	
	var flash = ColorRect.new()
	flash.color = Color(1.0, 0.7, 0.3, 0.7)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 20
	if is_instance_valid(hud):
		hud.add_child(flash)
	else:
		add_child(flash)
		
	var t = create_tween()
	t.tween_property(flash, "color:a", 0.0, 1.0)
	t.finished.connect(flash.queue_free)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
			if e.has_method("take_damage"):
				e.take_damage(GameManager.click_damage * 35)

func _trigger_pirate_laser() -> void:
	var target = null
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			valid_enemies.append(e)
	
	if valid_enemies.size() > 0:
		target = valid_enemies.pick_random()
	
	var target_pos = Vector2.ZERO
	if target:
		target_pos = target.global_position
	else:
		var view_size = get_viewport_rect().size
		target_pos = Vector2(randf_range(100, view_size.x - 100), randf_range(150, view_size.y - 100))
		
	var ship_pos = Vector2(target_pos.x, 60)
	
	var ufo = Node2D.new()
	ufo.global_position = ship_pos
	ufo.z_index = 12
	add_child(ufo)
	
	var ufo_draw_script = """
extends Node2D
var alpha: float = 1.0
func _draw() -> void:
	draw_colored_polygon(
		[
			Vector2(-40, 0), Vector2(-20, -10), Vector2(20, -10), Vector2(40, 0),
			Vector2(20, 10), Vector2(-20, 10)
		],
		Color(0.8, 0.0, 0.8, alpha)
	)
	draw_colored_polygon(
		[
			Vector2(-15, -8), Vector2(-5, -20), Vector2(5, -20), Vector2(15, -8)
		],
		Color(0.2, 0.9, 1.0, alpha * 0.7)
	)
	draw_circle(Vector2(-20, 2), 3, Color(1.0, 1.0, 0.0, alpha))
	draw_circle(Vector2(0, 4), 3, Color(1.0, 1.0, 0.0, alpha))
	draw_circle(Vector2(20, 2), 3, Color(1.0, 1.0, 0.0, alpha))
"""
	var script = GDScript.new()
	script.source_code = ufo_draw_script
	script.reload()
	ufo.set_script(script)
	ufo.queue_redraw()
	
	ufo.scale = Vector2.ZERO
	var t_ufo = create_tween()
	t_ufo.tween_property(ufo, "scale", Vector2.ONE, 0.3)
	
	var reticle = Line2D.new()
	reticle.default_color = Color(1.0, 0.0, 0.8, 1.0)
	reticle.width = 2.0
	reticle.z_index = 10
	add_child(reticle)
	var steps = 16
	for i in range(steps + 1):
		var angle = (PI * 2 / steps) * i
		reticle.add_point(target_pos + Vector2.RIGHT.rotated(angle) * 40.0)
		
	reticle.scale = Vector2(2.0, 2.0)
	var t_ret = create_tween()
	t_ret.tween_property(reticle, "scale", Vector2(1.0, 1.0), 0.7)
	t_ret.parallel().tween_property(reticle, "modulate:a", 0.5, 0.7)
	
	await get_tree().create_timer(0.8).timeout
	
	var laser = Line2D.new()
	laser.default_color = Color(1.0, 0.0, 0.8, 0.5)
	laser.width = 60.0
	laser.z_index = 11
	add_child(laser)
	laser.add_point(ship_pos)
	laser.add_point(target_pos)

	var laser_core = Line2D.new()
	laser_core.default_color = Color(1.0, 1.0, 1.0, 1.0)
	laser_core.width = 12.0
	laser_core.z_index = 12
	add_child(laser_core)
	laser_core.add_point(ship_pos)
	laser_core.add_point(target_pos)

	var t_flicker = create_tween().set_loops(4)
	t_flicker.tween_property(laser, "width", 45.0, 0.05)
	t_flicker.tween_property(laser, "width", 60.0, 0.05)
	
	AudioManager.play("crit")
	shake_camera(0.6, 12)
	
	var sq_radius = 150.0 * 150.0
	var hit_enemies = get_tree().get_nodes_in_group("enemies")
	for e in hit_enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
			if e.global_position.distance_squared_to(target_pos) < sq_radius:
				if e.has_method("take_damage"):
					e.take_damage(200, false, "electric")
	
	var t_fade = create_tween()
	t_fade.set_parallel(true)
	t_fade.tween_property(laser, "width", 0.0, 0.4)
	t_fade.tween_property(laser, "modulate:a", 0.0, 0.4)
	t_fade.tween_property(laser_core, "width", 0.0, 0.3)
	t_fade.tween_property(laser_core, "modulate:a", 0.0, 0.3)
	t_fade.tween_property(reticle, "modulate:a", 0.0, 0.4)
	if is_instance_valid(ufo):
		t_fade.tween_property(ufo, "scale", Vector2.ZERO, 0.4)
		t_fade.tween_property(ufo, "modulate:a", 0.0, 0.4)
		
	await t_fade.finished
	laser.queue_free()
	laser_core.queue_free()
	reticle.queue_free()
	if is_instance_valid(ufo):
		ufo.queue_free()

func _trigger_radish_rain() -> void:
	var target_pos = Vector2.ZERO
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
			valid_enemies.append(e)
			
	if valid_enemies.size() > 0:
		target_pos = valid_enemies.pick_random().global_position
	else:
		var view_size = get_viewport_rect().size
		target_pos = Vector2(randf_range(100, view_size.x - 100), randf_range(150, view_size.y - 100))
		
	var radish = Sprite2D.new()
	radish.texture = load("res://assets/img/rabanito.png")
	radish.global_position = Vector2(target_pos.x, -100)
	radish.z_index = 10
	radish.scale = Vector2(2.5, 2.5)
	add_child(radish)
	
	var fall_time = 0.6
	var t = create_tween()
	t.tween_property(radish, "global_position:y", target_pos.y, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(radish, "rotation_degrees", 360.0, fall_time)
	
	await t.finished
	
	shake_camera(0.5, 15)
	AudioManager.play("crit")
	
	var ring = Line2D.new()
	ring.default_color = Color(1.0, 0.3, 0.3, 1.0)
	ring.width = 4.0
	ring.z_index = 9
	add_child(ring)
	for i in range(17):
		var angle = (PI * 2 / 16) * i
		ring.add_point(target_pos + Vector2.RIGHT.rotated(angle) * 60.0)
	
	var ring_t = create_tween()
	ring_t.set_parallel(true)
	ring_t.tween_property(ring, "scale", Vector2(1.8, 1.8), 0.3)
	ring_t.tween_property(ring, "modulate:a", 0.0, 0.3)
	ring_t.finished.connect(ring.queue_free)
	
	var dmg_radius = 100.0
	var sq_radius = dmg_radius * dmg_radius
	var hit_enemies = get_tree().get_nodes_in_group("enemies")
	for e in hit_enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
			if e.global_position.distance_squared_to(target_pos) < sq_radius:
				if e.has_method("take_damage"):
					e.take_damage(150)
					
	var coin_scene = preload("res://scenes/coin.tscn")
	for i in range(3):
		var coin = coin_scene.instantiate()
		get_parent().call_deferred("add_child", coin)
		coin.global_position = target_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
	var fade_t = create_tween()
	fade_t.set_parallel(true)
	fade_t.tween_property(radish, "scale", Vector2(3.0, 0.2), 0.1)
	fade_t.tween_property(radish, "modulate:a", 0.0, 0.3)
	await fade_t.finished
	radish.queue_free()

func create_micro_explosion(pos: Vector2) -> void:
	GameManager.increment_stat("explosions_caused", 1)
	var ring = Line2D.new()
	ring.default_color = Color(1.0, 1.0, 1.0, 0.4)
	ring.width = 2.0
	ring.z_index = 8
	add_child(ring)
	for i in range(9):
		var angle = (PI * 2 / 8) * i
		ring.add_point(pos + Vector2.RIGHT.rotated(angle) * 30.0)
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.2)
	t.tween_property(ring, "modulate:a", 0.0, 0.2)
	t.finished.connect(ring.queue_free)

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = p - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq == 0.0:
		return p.distance_to(a)
	var t = clamp(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var projection = a + t * ab
	return p.distance_to(projection)
