extends Node2D

@onready var spawn_timer: Timer = $Spawner/SpawnTimer
@onready var hud: CanvasLayer = $HUD
@onready var menu_pausa: Control = $CanvasPausa/MenuPausa
@onready var level_up_menu: Control = $CanvasPausa/LevelUpMenu

# Pre-cargamos las escenas
var enemy_scene = preload("res://scenes/Enemy.tscn")
var boss_scene = preload("res://scenes/Jefe.tscn")
var bomb_scene = preload("res://scenes/seed_bomb.tscn")
var acid_scene = preload("res://scenes/acid_puddle.tscn")
var toxic_shot_scene = preload("res://scenes/toxic_shot.tscn")
var wind_scene = preload("res://scenes/wind_gust.tscn")
var black_hole_scene = preload("res://scenes/black_hole.tscn")
var fire_wall_scene = preload("res://scenes/fire_wall.tscn")
var chest_scene = preload("res://scenes/Chest.tscn")

func _ready() -> void:
	print("INICIO: Escena Principal cargando...")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	
	if is_instance_valid(spawn_timer) and not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	GameManager.wave_updated.connect(_on_wave_updated)
	GameManager.level_up.connect(_on_level_up)
	if is_instance_valid(hud) and hud.has_signal("pause_requested"):
		hud.pause_requested.connect(_on_pause_requested)
	
	# Limpiar estelas al inicio
	if is_instance_valid(trail): trail.clear_points()
	if is_instance_valid(mirror_trail): mirror_trail.clear_points()
	if is_instance_valid(double_trail): double_trail.clear_points()
	
	await get_tree().create_timer(0.5).timeout
	_on_wave_updated(GameManager.current_wave)
	if is_instance_valid(spawn_timer): spawn_timer.start()

func _on_level_up(_new_level: int) -> void:
	if is_instance_valid(level_up_menu) and level_up_menu.has_method("show_menu"):
		level_up_menu.show_menu()
		AudioManager.play("coin_pickup")
		shake_camera(0.2, 8)

func _on_pause_requested() -> void:
	if is_instance_valid(menu_pausa) and menu_pausa.has_method("toggle_pause"):
		menu_pausa.toggle_pause()

func _on_wave_updated(new_wave: int) -> void:
	var base_time = 1.5
	var new_time = base_time * pow(0.78, new_wave - 1)
	new_time = max(0.2, new_time)
	if is_instance_valid(spawn_timer): spawn_timer.wait_time = new_time

func _on_spawn_timer_timeout() -> void:
	if GameManager.enemies_spawned_this_wave < GameManager.get_total_enemies_for_current_wave():
		spawn_enemy()

@onready var spawn_zone: ReferenceRect = $SpawnZone
@onready var trail: Line2D = $Trail
@onready var mirror_trail: Line2D = get_node_or_null("TrailMirror")
@onready var double_trail: Line2D = get_node_or_null("TrailDouble")

var is_slicing: bool = false
var last_slice_pos: Vector2 = Vector2.ZERO
var slice_start_time: float = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var is_pressed = event.pressed
		is_slicing = is_pressed

		if is_slicing:
			last_slice_pos = get_global_mouse_position()
			slice_start_time = Time.get_ticks_msec() / 1000.0
			_update_trails(last_slice_pos, true)
		else:
			_check_wind_gust(get_global_mouse_position())
			_update_trails(Vector2.ZERO, false)

	if (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_slicing:
		var current_pos = get_global_mouse_position()
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
				else: continue # No dibujar si no está activo
			elif t == double_trail:
				if GameManager.has_double_slice: target_pos = pos + Vector2(40, 40)
				else: continue # No dibujar si no está activo
			
			t.add_point(target_pos)
			if t.points.size() > 8: t.remove_point(0)
		elif not is_slicing:
			t.clear_points()

func _check_wind_gust(end_pos: Vector2) -> void:
	if not GameManager.has_wind_gust or GameManager.wind_gust_count <= 0: return
	var duration = (Time.get_ticks_msec() / 1000.0) - slice_start_time
	var distance = last_slice_pos.distance_to(end_pos)
	var speed = distance / max(0.001, duration)
	
	if speed > 1000.0:
		for i in range(GameManager.wind_gust_count):
			var wind = wind_scene.instantiate()
			get_parent().add_child(wind)
			wind.global_position = last_slice_pos + Vector2(randf_range(-40,40), randf_range(-40,40))
			if "direction" in wind: wind.direction = last_slice_pos.direction_to(end_pos)

func get_mirrored_pos(pos: Vector2) -> Vector2:
	var base = get_tree().get_first_node_in_group("BaseRabanito")
	return base.global_position - (pos - base.global_position) if base else pos

func check_slice_collision(start_pos: Vector2, end_pos: Vector2) -> void:
	_perform_raycast_slice(start_pos, end_pos)
	if GameManager.has_double_slice:
		var dir = (end_pos - start_pos).normalized()
		var ortho = Vector2(-dir.y, dir.x) * 40.0
		_perform_raycast_slice(start_pos + ortho, end_pos + ortho)
		_perform_raycast_slice(start_pos - ortho, end_pos - ortho)
	if GameManager.has_mirror_slice:
		_perform_raycast_slice(get_mirrored_pos(start_pos), get_mirrored_pos(end_pos))

func _perform_raycast_slice(start: Vector2, end: Vector2) -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var hits = 0
	while hits < 10:
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result.collider
			if collider.is_in_group("enemies") or collider.is_in_group("chests"):
				if collider.has_method("take_damage"): _on_enemy_sliced(collider)
			elif collider.is_in_group("orbs") and collider.has_method("magnetize_to"):
				var base = get_tree().get_first_node_in_group("BaseRabanito")
				if base: collider.magnetize_to(base.global_position)
			var new_exclude = query.exclude.duplicate(); new_exclude.append(collider.get_rid()); query.exclude = new_exclude
			hits += 1
		else: break

func _on_enemy_sliced(enemy: Node2D) -> void:
	var is_crit = randf() < GameManager.crit_chance
	var damage = int(GameManager.click_damage * GameManager.prestige_multiplier)
	if is_crit: damage = int(damage * GameManager.crit_multiplier); AudioManager.play("crit"); shake_camera(0.1, 5)
	else: AudioManager.play("pop")
	enemy.take_damage(damage, is_crit)
	GameManager.add_combo()
	if GameManager.has_lightning_slice: _perform_chain_lightning(enemy)
	if GameManager.has_explosive_slice and randf() < 0.05:
		var b = bomb_scene.instantiate(); b.z_index = 6; get_parent().call_deferred("add_child", b); b.global_position = enemy.global_position
	if GameManager.has_black_hole and randf() < 0.01:
		var bh = black_hole_scene.instantiate(); get_parent().call_deferred("add_child", bh); bh.global_position = enemy.global_position
	if GameManager.has_fire_wall and randf() < 0.10:
		var fw = fire_wall_scene.instantiate(); get_parent().call_deferred("add_child", fw); fw.global_position = enemy.global_position

func _perform_chain_lightning(source: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = 0; var last = source
	var max_hits = 2 + GameManager.lightning_level
	var range_dist = 150 + (GameManager.lightning_level * 50)
	for e in enemies:
		if count >= max_hits: break
		if is_instance_valid(e) and e != last and "current_health" in e:
			if last.global_position.distance_to(e.global_position) < range_dist:
				e.take_damage(int(GameManager.click_damage * 0.4)); count += 1; last = e

# --- SPAWNER ---
func spawn_enemy() -> void:
	var is_boss_time = (GameManager.current_wave % 5 == 0) and (GameManager.enemies_spawned_this_wave + 1 >= GameManager.get_total_enemies_for_current_wave())
	var zone_rect = spawn_zone.get_global_rect()
	var spawn_pos = Vector2.ZERO; var side = randi() % 4
	match side:
		0: spawn_pos = Vector2(randf_range(zone_rect.position.x, zone_rect.end.x), zone_rect.position.y)
		1: spawn_pos = Vector2(randf_range(zone_rect.position.x, zone_rect.end.x), zone_rect.end.y)
		2: spawn_pos = Vector2(zone_rect.position.x, randf_range(zone_rect.position.y, zone_rect.end.y))
		3: spawn_pos = Vector2(zone_rect.end.x, randf_range(zone_rect.position.y, zone_rect.end.y))

	if is_boss_time:
		spawn_boss(spawn_pos)
	elif randf() < 0.03 and GameManager.chests_spawned_this_wave < 2: # Máximo 2 por ronda
		GameManager.chests_spawned_this_wave += 1
		spawn_chest()
	else:
		var r = randf(); var v = 0
		if r < 0.05: v = 3 # KAMIKAZE
		elif r < 0.10: v = 4 # TROJAN
		elif r < 0.15: v = 5 # HEALER
		elif r < 0.20: v = 6 # SNIPER
		elif r < 0.35: v = 1 # TANK
		elif r < 0.50: v = 2 # RUNNER
		spawn_variant_at(v, spawn_pos)

func spawn_boss(pos: Vector2) -> void:
	GameManager.enemies_spawned_this_wave += 1
	var boss = boss_scene.instantiate()
	boss.position = pos
	boss.is_boss = true
	var scaled_hp = int(12 * pow(1.25, GameManager.current_wave))
	boss.max_health = scaled_hp * 20
	add_child(boss)
	boss.scale = Vector2(1.6, 1.6); boss.modulate = Color(0.5, 0, 0.5)
	if "anim" in boss: boss.anim.speed_scale = 0.5
	shake_camera(0.5, 10)
	print("¡EL MEGA JEFE HA LLEGADO!")

func spawn_chest() -> void:
	var zone_rect = spawn_zone.get_global_rect()
	var spawn_pos = Vector2(randf_range(zone_rect.position.x + 50, zone_rect.end.x - 50), randf_range(zone_rect.position.y + 50, zone_rect.end.y - 50))
	var chest = chest_scene.instantiate()
	get_parent().call_deferred("add_child", chest); chest.global_position = spawn_pos

func spawn_variant_at(variant: int, pos: Vector2) -> Node2D:
	if not is_instance_valid(self): return null
	GameManager.enemies_spawned_this_wave += 1
	var enemy_instance = enemy_scene.instantiate()
	if "current_variant" in enemy_instance: enemy_instance.current_variant = variant
	enemy_instance.position = pos
	var scaled_hp = int(12 * pow(1.25, GameManager.current_wave))
	match variant:
		1: enemy_instance.max_health = scaled_hp * 2; enemy_instance.move_speed = 30.0
		2: enemy_instance.max_health = int(scaled_hp * 0.3); enemy_instance.move_speed = 180.0
		3: enemy_instance.max_health = 1; enemy_instance.move_speed = 250.0; enemy_instance.modulate = Color.ORANGE_RED
		4: enemy_instance.max_health = scaled_hp * 5; enemy_instance.move_speed = 15.0; enemy_instance.scale = Vector2(1.25, 1.25)
		5: enemy_instance.max_health = scaled_hp; enemy_instance.move_speed = 40.0; enemy_instance.modulate = Color.LAWN_GREEN
		6: enemy_instance.max_health = scaled_hp; enemy_instance.move_speed = 45.0; enemy_instance.modulate = Color.MEDIUM_PURPLE
		0: enemy_instance.max_health = scaled_hp; enemy_instance.move_speed = 60.0
	call_deferred("add_child", enemy_instance)
	return enemy_instance

func shake_camera(duration: float, intensity: float):
	var camera = get_node_or_null("Camera2D")
	if not is_instance_valid(camera): return
	var tween = create_tween()
	for i in range(int(duration * 50)):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", offset, 0.02)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
