extends Node

var hit_counter: int = 0
var buff_active: bool = false
var original_damage_multiplier: float = 1.0

@onready var toronja_scene = preload("res://scenes/toronja_rodante.tscn")
var spawn_timer: Timer
var buff_timer: Timer

func _ready() -> void:
	# 1. Configurar el Timer de 6 segundos para la Toronja
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 6.0
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_toronja)
	add_child(spawn_timer)
	
	# 2. Configurar el Timer poético del Buff (16.01s)
	buff_timer = Timer.new()
	buff_timer.wait_time = 16.01
	buff_timer.one_shot = true
	buff_timer.timeout.connect(_on_buff_ended)
	add_child(buff_timer)
	
	# 3. Aplicar los cambios estéticos y desbloqueos
	_cambiar_color_estela()
	_desbloquear_recompensas()

# ----------------- MECÁNICAS VISUALES Y RECOMPENSAS -----------------

func _cambiar_color_estela() -> void:
	# Busca tu estela (asumiendo que es un Line2D o Trail)
	var swipe_trail = get_tree().get_first_node_in_group("swipe_trail")
	if swipe_trail and swipe_trail is Line2D:
		var nuevo_gradiente = Gradient.new()
		# Amarillo brillante (0.0) a Morado claro (1.0)
		nuevo_gradiente.add_point(0.0, Color("ffff00")) 
		nuevo_gradiente.add_point(1.0, Color("dca3ff"))
		swipe_trail.gradient = nuevo_gradiente

func _desbloquear_recompensas() -> void:
	if not GameManager.unlocked_titles.has("Media Toronja"):
		GameManager.unlocked_titles.append("Media Toronja")
		GameManager.unlocked_pfps.append("pf_toronja_neon")
		GameManager.save_game()
		print("¡Título y PFP ocultos desbloqueados!")

# ----------------- EL SISTEMA DE BUFF (2011 Golpes) -----------------

# **IMPORTANTE:** Llama a esta función desde tu script de Tajos 
# cada vez que cortes a un alien.
func registrar_golpe() -> void:
	hit_counter += 1
	if hit_counter >= 2011 and not buff_active:
		_activar_buff()

func _activar_buff() -> void:
	buff_active = true
	hit_counter = 0 # Reiniciamos para volver a ciclarlo
	
	# +200% de Daño (x3 total)
	original_damage_multiplier = GameManager.damage_multiplier
	GameManager.damage_multiplier = original_damage_multiplier + 2.0
	
	# Efecto visual en la Base Rabanito para saber que está en "Modo Dios"
	var base = get_tree().get_first_node_in_group("base_rabanito")
	if base: 
		base.modulate = Color("dca3ff") # Se tiñe de morado claro
		
	buff_timer.start()

func _on_buff_ended() -> void:
	buff_active = false
	GameManager.damage_multiplier = original_damage_multiplier
	
	var base = get_tree().get_first_node_in_group("base_rabanito")
	if base: 
		base.modulate = Color.WHITE # Vuelve a la normalidad

# ----------------- EL GENERADOR DE TORONJAS -----------------

func _spawn_toronja() -> void:
	var toronja = toronja_scene.instantiate()
	var viewport_rect = get_viewport().get_visible_rect()
	
	# Alternar si sale de la izquierda o de la derecha aleatoriamente
	var sale_izquierda = randf() > 0.5
	var start_y = randf_range(150, viewport_rect.size.y - 150)
	
	if sale_izquierda:
		toronja.position = Vector2(-100, start_y)
		toronja.direction = Vector2.RIGHT
	else:
		toronja.position = Vector2(viewport_rect.size.x + 100, start_y)
		toronja.direction = Vector2.LEFT
		
	get_tree().current_scene.add_child(toronja)
