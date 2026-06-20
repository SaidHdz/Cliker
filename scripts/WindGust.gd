extends Area2D

var direction: Vector2 = Vector2.RIGHT
# 1200.0 es excesivamente rápido para ver la animación de aparición. Prueba con 800.0
@export var speed: float = 800.0 
@export var damage: int = 10
@export var knockback_force: float = 400.0

func _ready() -> void:
	# 1. Forzar que el proyectil se dibuje por encima de todo (Fondo y Enemigos)
	z_index = 10 
	
	# 2. ¡CRÍTICO! Conectar la señal de colisión, si no, no hará daño
	area_entered.connect(_on_area_entered)
	
	# Autodestrucción al salir de pantalla o tras 2 segundos
	get_tree().create_timer(2.0).timeout.connect(queue_free)
	
	# Efecto visual de escala al aparecer
	scale = Vector2.ZERO
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1.5, 0.8), 0.1)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and area.has_method("take_damage"):
		area.take_damage(damage)
		
		# Aplicar Knockback si el enemigo lo soporta
		if "dispersion_velocity" in area:
			area.dispersion_velocity = direction * knockback_force
			
		# Al no poner un queue_free() aquí, el proyectil actúa como perforante infinito
