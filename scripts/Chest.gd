extends Area2D

@export var max_health: float = 50.0
var current_health: float = 50.0

var original_scale: Vector2 = Vector2.ONE
var regen_timer: Timer
func _ready() -> void:
	add_to_group("chests")
	original_scale = scale

	# Vida escala con la oleada
	max_health = 100.0 + (GameManager.current_wave * 25.0)
	current_health = max_health

	# Desaparecer si cambia la oleada y no ha sido abierto
	GameManager.wave_updated.connect(func(_new_wave): queue_free())

	# Temporizador de regeneración
...
	regen_timer = Timer.new()
	regen_timer.wait_time = 1.0 # 1 segundo de calma para empezar a regenerar
	regen_timer.one_shot = true
	regen_timer.timeout.connect(_start_regeneration)
	add_child(regen_timer)

func _physics_process(delta: float) -> void:
	# Regeneración pasiva si el timer no está corriendo (calma)
	if regen_timer.is_stopped() and current_health < max_health:
		current_health = min(max_health, current_health + (5.0 * delta))
		update_visuals()

func take_damage(amount: int, _is_crit: bool = false) -> void:
	current_health -= amount
	
	# Reiniciar el tiempo de calma
	regen_timer.start()
	
	update_visuals()
	
	# Animación de golpe elástico
	var t = create_tween()
	t.tween_property(self, "rotation_degrees", randf_range(-10, 10), 0.05)
	t.tween_property(self, "rotation_degrees", 0, 0.05)
	
	if current_health <= 0:
		explode()

func update_visuals() -> void:
	# Calcular cuánto ha crecido según el daño (Inflatable)
	# A menos vida, más grande
	var damage_percent = 1.0 - (current_health / max_health)
	var target_scale = original_scale * (1.0 + (damage_percent * 1.5)) # Hasta 2.5x más grande
	
	scale = scale.lerp(target_scale, 0.1)

func _start_regeneration() -> void:
	# El timer solo sirve para marcar el inicio de la calma en _physics_process
	pass

func explode() -> void:
	# Soltar muchísima recompensa
	if AudioManager.has_method("play"):
		AudioManager.play("drop_xp")
	
	var orb_scene = preload("res://scenes/coin.tscn")
	for i in range(15):
		var orb = orb_scene.instantiate()
		get_parent().call_deferred("add_child", orb)
		orb.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		orb.value = 5 # Orbes valiosos
	
	queue_free()
