extends RigidBody2D

var value: int = 1
var collected: bool = false
var is_magnetized: bool = false
var target_pos: Vector2 = Vector2.ZERO
var magnet_speed: float = 800.0

func _ready() -> void:
	scale = Vector2(1.0, 1.0)
	add_to_group("orbs")
	add_to_group("coins")
	# Impulso aleatorio inicial hacia arriba (caída)
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, -1.5)).normalized()
	apply_central_impulse(direction * randf_range(300, 600))
	
	# Damping para que no reboten/rueden infinitamente
	linear_damp = 1.0
	angular_damp = 1.0
	
	# Crecer a tamaño 1.5 tras 0.6 segundos (cuando ya está cerca del suelo)
	get_tree().create_timer(0.6).timeout.connect(func():
		if not collected and not is_magnetized:
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
	)

func _physics_process(delta: float) -> void:
	if is_magnetized:
		# Vuelo directo hacia la base (Ignoramos físicas)
		global_position = global_position.move_toward(target_pos, magnet_speed * delta)
		
		# Si llega al objetivo, lo recolectamos
		if global_position.distance_to(target_pos) < 20.0:
			collect()

func magnetize_to(pos: Vector2) -> void:
	if collected or is_magnetized: return
	is_magnetized = true
	target_pos = pos
	
	# Congelamos las físicas de caída
	freeze = true
	
	# Pequeña animación de que fue tocado (escala relativa al tamaño actual)
	var tween = create_tween()
	var base_scale = scale
	tween.tween_property(self, "scale", base_scale * 1.5, 0.1)
	tween.tween_property(self, "scale", base_scale, 0.1)

func collect() -> void:
	if collected: return
	collected = true
	
	if AudioManager.has_method("play"):
		AudioManager.play("take_xp") # Sonido de recolección de XP
	
	# Damos la experiencia (Pronto crearemos gain_xp en GameManager)
	if GameManager.has_method("gain_xp"):
		GameManager.gain_xp(value)
	else:
		# Temporal hasta actualizar el GameManager
		GameManager.add_coins(value)
		
	queue_free()
