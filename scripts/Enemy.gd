extends Area2D

# --- VARIABLES DE ESTADÍSTICAS ---
@export var max_health: int = 10
var current_health: int = 0
@export var is_boss: bool = false
var coin_multiplier: int = 1

# --- VARIABLES DE MOVIMIENTO ---
var velocity: Vector2 = Vector2.ZERO
@export var move_speed: float = 50.0
var dispersion_velocity: Vector2 = Vector2.ZERO # Impulso inicial (Caballo de Troya)
var is_invincible: bool = false # Protección temporal al spawnear

# --- NODOS ---
@onready var health_bar: ProgressBar = $HealthBar
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# --- VARIABLES INTERNAS ---
var original_sprite_scale: Vector2
var hit_tween: Tween

# --- PRECARGAS (MAYÚSCULAS PARA ANDROID) ---
var damage_number_scene = preload("res://scenes/damage_number.tscn")
var coin_scene = preload("res://scenes/coin.tscn")
var acid_scene = preload("res://scenes/acid_puddle.tscn")
var toxic_shot_scene = preload("res://scenes/toxic_shot.tscn")

var target_base: Node2D
var attack_timer: Timer
var is_attacking: bool = false
var damage_to_base: int = 1

# --- VARIANTES (NUEVO BESTIARIO) ---
enum EnemyVariant { NORMAL=0, TANK=1, RUNNER=2, KAMIKAZE=3, TROJAN=4, HEALER=5, SNIPER=6 }
var current_variant: EnemyVariant = EnemyVariant.NORMAL
var shot_timer: Timer

# --- ESTADOS (ROGUELITE) ---
var fire_timer: Timer
var fire_ticks: int = 0
var is_frozen: bool = false
var frost_timer: Timer
var original_move_speed: float

func _ready() -> void:
	original_sprite_scale = anim.scale
	original_move_speed = move_speed
	add_to_group("enemies")
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	target_base = get_tree().get_first_node_in_group("BaseRabanito")
	
	attack_timer = Timer.new(); attack_timer.wait_time = 1.0; attack_timer.timeout.connect(_on_attack_timer_timeout); add_child(attack_timer)
	fire_timer = Timer.new(); fire_timer.wait_time = 1.0; fire_timer.timeout.connect(_on_fire_tick); add_child(fire_timer)
	frost_timer = Timer.new(); frost_timer.wait_time = 3.0; frost_timer.one_shot = true; frost_timer.timeout.connect(_on_frost_timeout); add_child(frost_timer)
	
	shot_timer = Timer.new(); shot_timer.wait_time = 3.0; shot_timer.timeout.connect(_on_special_timer_timeout); add_child(shot_timer)
	
	if current_variant == EnemyVariant.SNIPER or current_variant == EnemyVariant.HEALER:
		shot_timer.start()

	anim.play("run")
	input_event.connect(_on_input_event)

func _physics_process(delta: float) -> void:
	if current_health <= 0 or is_attacking: return
	
	# Lógica de Dispersión (Se agota con el tiempo)
	if dispersion_velocity.length() > 10:
		position += dispersion_velocity * delta
		dispersion_velocity = dispersion_velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return 
		
	if is_instance_valid(target_base):
		var dist = global_position.distance_to(target_base.global_position)
		if current_variant == EnemyVariant.SNIPER and dist < 400:
			if anim.animation != "idle": anim.play("idle")
			return
			
		var direction = (target_base.global_position - global_position).normalized()
		var speed = move_speed * (0.5 if is_frozen else 1.0)
		position += direction * speed * delta
		anim.flip_h = direction.x < 0

func _on_special_timer_timeout() -> void:
	if current_health <= 0: return
	if current_variant == EnemyVariant.SNIPER and is_instance_valid(target_base):
		var s = toxic_shot_scene.instantiate()
		get_parent().add_child(s)
		s.global_position = global_position
		if s.has_method("set_target"): s.set_target(target_base.global_position)
		s.add_to_group("enemies")
	elif current_variant == EnemyVariant.HEALER:
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e) and e != self and "current_health" in e:
				if global_position.distance_to(e.global_position) < 200:
					e.current_health = min(e.current_health + 10, e.max_health)
					e.health_bar.value = e.current_health

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var final_damage = int(GameManager.click_damage * GameManager.prestige_multiplier)
		take_damage(final_damage, randf() < GameManager.crit_chance)

func take_damage(amount: int, is_crit: bool = false) -> void:
	if current_health <= 0 or is_invincible: return
	current_health -= amount
	health_bar.value = current_health
	if GameManager.has_fire_slice: apply_fire()
	spawn_damage_number(amount, is_crit)
	
	if not is_boss: anim.play("idle")
	
	if hit_tween and hit_tween.is_valid(): hit_tween.kill()
	hit_tween = create_tween()
	var flash = Color(5, 5, 5, 1) if not is_crit else Color(5, 5, 0, 1)
	hit_tween.tween_property(anim, "modulate", flash, 0.05)
	hit_tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
	hit_tween.finished.connect(func(): if is_instance_valid(self) and current_health > 0 and not is_attacking: anim.play("run"))
	
	if current_health <= 0: die()

func apply_fire() -> void:
	if fire_ticks <= 0: fire_timer.start()
	fire_ticks = 3
	modulate = Color(1.0, 0.5, 0.5)

func _on_fire_tick() -> void:
	if current_health > 0:
		take_damage(int(max_health * 0.05) + (GameManager.fire_slice_level * 2))
		fire_ticks -= 1
		if fire_ticks <= 0:
			fire_timer.stop()
			if not is_frozen: modulate = Color.WHITE

func apply_frost() -> void:
	is_frozen = true
	frost_timer.start()
	modulate = Color(0.5, 0.8, 1.0)

func _on_frost_timeout() -> void:
	is_frozen = false
	if fire_ticks <= 0: modulate = Color.WHITE

func kamikaze_attack() -> void:
	if current_variant == EnemyVariant.KAMIKAZE:
		if is_instance_valid(target_base): target_base.take_damage(30)
		die()
		return
	if not is_attacking and current_health > 0:
		is_attacking = true
		anim.play("idle")
		attack_timer.start()

func _on_attack_timer_timeout() -> void:
	if current_health <= 0: attack_timer.stop(); return
	if is_instance_valid(target_base) and target_base.has_method("take_damage"):
		target_base.take_damage(damage_to_base)
		var t = create_tween()
		var d = (target_base.global_position - global_position).normalized()
		t.tween_property(anim, "position", d * 15, 0.1)
		t.tween_property(anim, "position", Vector2.ZERO, 0.2)
	else:
		attack_timer.stop(); is_attacking = false; anim.play("run")

func die() -> void:
	GameManager.notify_enemy_defeated()
	spawn_loot()
	
	# Caballo de Troya: suelta 6 enemigos diversos con dispersión e invencibilidad
	if current_variant == EnemyVariant.TROJAN:
		var scene = get_tree().current_scene
		if scene.has_method("spawn_variant_at"):
			# Mezcla de enemigos para que sea una sorpresa
			var child_list = [2, 0, 1, 2, 2, 3] # 2:Runner, 0:Normal, 1:Tank, 3:Kamikaze
			for i in range(child_list.size()):
				var angle = (PI * 2 / child_list.size()) * i + randf_range(-0.3, 0.3)
				var launch_dir = Vector2.RIGHT.rotated(angle)
				# Spawn con un pequeño offset para que no se pisen al nacer
				var child = scene.spawn_variant_at(child_list[i], global_position + (launch_dir * 50.0))
				if child:
					child.dispersion_velocity = launch_dir * randf_range(600.0, 800.0)
					child.is_invincible = true
					# Quitar invencibilidad tras 0.5s para dar tiempo a huir del tajo
					get_tree().create_timer(0.5).timeout.connect(func(): if is_instance_valid(child): child.is_invincible = false)
	
	# Abono Tóxico: 20% probabilidad de charco
	if GameManager.has_toxic_compost and randf() < 0.20:
		var a = acid_scene.instantiate()
		a.z_index = 5 # Por encima del mapa (0) pero bajo los enemigos (10)
		get_parent().call_deferred("add_child", a)
		a.global_position = global_position
	queue_free()

func spawn_loot() -> void:
	if AudioManager.has_method("play"): AudioManager.play("drop_xp")
	var count = 50 if is_boss else randi_range(1, 3)
	var val = (1 + int((GameManager.current_wave - 1) / 2)) * coin_multiplier
	for i in count:
		var c = coin_scene.instantiate(); get_parent().call_deferred("add_child", c); c.global_position = global_position; c.value = val

func spawn_damage_number(amount: int, is_crit: bool = false) -> void:
	var l = damage_number_scene.instantiate(); get_tree().current_scene.add_child(l)
	if l.has_method("set_values"): l.set_values(amount, is_crit, global_position + Vector2(randf_range(-20, 20), -40))
