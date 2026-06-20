extends Area2D

@export var max_health: float = 100.0
var current_health: float = 100.0
var original_scale: Vector2 = Vector2.ONE
var regen_timer: Timer
var hit_tween: Tween # Guardamos el Tween para evitar conflictos

func _ready() -> void:
	add_to_group("chests")
	original_scale = scale
	
	# Vida escala con la oleada (100 base + 25 por ronda)
	max_health = 100.0 + (GameManager.current_wave * 25.0)
	current_health = max_health
	
	# Conexión tradicional para evitar errores en consola
	GameManager.wave_updated.connect(_on_wave_updated)
	
	regen_timer = Timer.new()
	regen_timer.wait_time = 1.0
	regen_timer.one_shot = true
	add_child(regen_timer)

func _physics_process(delta: float) -> void:
	# 1. Lógica de Regeneración
	if regen_timer.is_stopped() and current_health < max_health:
		current_health = min(max_health, current_health + (max_health * 0.15 * delta))

	# 2. Lógica Visual (Se calcula SIEMPRE para que sea suave y fluido)
	var damage_percent = 1.0 - (current_health / max_health)
	var target_scale = original_scale * (1.0 + (damage_percent * 1.5))
	
	# Lerp multiplicado por delta para ser independiente del framerate
	scale = scale.lerp(target_scale, 10.0 * delta)

func take_damage(amount: int, is_crit: bool = false, type: String = "normal") -> void:
	current_health -= float(amount)
	regen_timer.start()
	
	# --- SISTEMA ANTI-GLITCH PARA DAÑO CONTINUO ---
	if hit_tween and hit_tween.is_running():
		hit_tween.kill()
		
	hit_tween = create_tween()
	hit_tween.tween_property(self, "rotation_degrees", randf_range(-15, 15), 0.05)
	hit_tween.tween_property(self, "rotation_degrees", 0.0, 0.05)
	
	if current_health <= 0:
		explode()

func explode() -> void:
	if AudioManager.has_method("play"): AudioManager.play("drop_xp")
	
	GameManager.chest_opened.emit()
	queue_free()

func _on_wave_updated(_new_wave: int) -> void:
	# Si la oleada cambia y no lo abriste, desaparece limpiamente
	queue_free()
