extends Node2D

@export var orbit_radius: float = 120.0
@export var orbit_speed: float = 4.0
@export var damage: int = 15

var time_passed: float = 0.0
var is_excalibur: bool = false
var strike_timer: float = 0.0

func _ready() -> void:
	add_to_group("allies")

func _physics_process(delta: float) -> void:
	var has_synergy = GameManager.has_excalibur_vegetal
	
	if has_synergy:
		if not is_excalibur:
			is_excalibur = true
			scale = Vector2(3.0, 3.0)
			modulate = Color(2.0, 0.8, 0.1) # Bañado en energía orbital naranja brillante
			if "monitoring" in self:
				self.monitoring = false
				
		strike_timer += delta
		if strike_timer >= 2.5:
			strike_timer = 0.0
			_execute_excalibur_strike()
	else:
		is_excalibur = false
		scale = Vector2.ONE
		modulate = Color.WHITE
		modulate.a = 1.0
		if "monitoring" in self:
			self.monitoring = true
			
		time_passed += delta * orbit_speed
		# Movimiento orbital circular
		var offset = Vector2(cos(time_passed), sin(time_passed)) * orbit_radius
		position = offset
		rotation = time_passed + PI/2

func _execute_excalibur_strike() -> void:
	var target = _get_strongest_enemy()
	if not target: return
	
	var target_pos = target.global_position
	
	# 1. Teletransportar arriba del objetivo
	global_position = target_pos + Vector2(0, -400)
	rotation = PI # Apuntar hacia abajo
	modulate.a = 1.0
	
	# 2. Caer como un meteoro
	var fall_tween = create_tween()
	fall_tween.tween_property(self, "global_position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await fall_tween.finished
	
	# 3. Impacto
	var scene = get_tree().current_scene
	if scene and scene.has_method("shake_camera"):
		scene.shake_camera(0.4, 15)
		
	if AudioManager.has_method("play"):
		AudioManager.play("crit")
		
	var crater_radius = 120.0
	var sq_radius = crater_radius * crater_radius
	var dmg = damage * 4
	
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0:
			if global_position.distance_squared_to(e.global_position) < sq_radius:
				if e.has_method("take_damage"):
					e.take_damage(dmg)
					
	# Onda de choque naranja
	var ring = Line2D.new()
	ring.default_color = Color(1.0, 0.5, 0.0, 1.0)
	ring.width = 6.0
	ring.z_index = 8
	get_parent().add_child(ring)
	for i in range(17):
		var angle = (PI * 2 / 16) * i
		ring.add_point(target_pos + Vector2.RIGHT.rotated(angle) * 75.0)
		
	var t_ring = create_tween()
	t_ring.set_parallel(true)
	t_ring.tween_property(ring, "scale", Vector2(1.6, 1.6), 0.3)
	t_ring.tween_property(ring, "modulate:a", 0.0, 0.3)
	t_ring.finished.connect(ring.queue_free)
	
	# 4. Quedarse un momento y desvanecerse
	await get_tree().create_timer(0.5).timeout
	if is_excalibur:
		var fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)

func _get_strongest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var strongest = null
	var max_hp = -1
	for e in enemies:
		if is_instance_valid(e) and "current_health" in e and e.current_health > 0 and not e.get("is_underground"):
			var hp = e.current_health
			if e.get("is_boss"):
				hp += 1000000
			if hp > max_hp:
				max_hp = hp
				strongest = e
	return strongest

func _on_area_entered(area: Area2D) -> void:
	if is_excalibur: return
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
		var t = create_tween()
		t.tween_property(self, "scale", Vector2(1.5, 1.5), 0.05)
		t.tween_property(self, "scale", Vector2(1, 1), 0.1)
