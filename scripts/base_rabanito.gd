extends Area2D

signal damaged(amount)

var max_health: int = 100
var current_health: int = 100

@onready var health_bar: ProgressBar = $ProgressBar
@onready var estados_container: HBoxContainer = get_node_or_null("estados")

# --- HABILIDADES (ESCENAS) ---
var shield_scene = preload("res://scenes/orbital_shield.tscn")

var active_shield: Node2D
var shield_shader_overlay: TextureRect

func _ready() -> void:
	z_index = 4
	max_health = GameManager.meta_base_health
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	add_to_group("BaseRabanito")
	
	# Setup Energy Shield Shader Overlay
	shield_shader_overlay = TextureRect.new()
	shield_shader_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shield_shader_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	shield_shader_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield_shader_overlay.visible = false
	add_child(shield_shader_overlay)
	
	shield_shader_overlay.size = Vector2(250, 250)
	shield_shader_overlay.position = -shield_shader_overlay.size / 2.0
	
	# Ocultar estados al inicio
	if estados_container:
		for child in estados_container.get_children():
			child.visible = false
			
	# Timer para actualizar componentes periódicamente (evita physics process sobrecargado)
	var update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(update_components)
	add_child(update_timer)
	update_timer.start()
	
	# Conexión tradicional de señales
	area_entered.connect(_on_area_entered)
	
	# Primera actualización inicial
	update_components()

func update_components() -> void:
	# 1. Escudo de Hojas (Shield)
	var shield_lvl = GameManager.get_skill_level("shield")
	if shield_lvl > 0 and active_shield == null:
		active_shield = shield_scene.instantiate()
		active_shield.z_index = 5
		call_deferred("add_child", active_shield)
		
	# Actualizar visibilidad del overlay del escudo
	shield_shader_overlay.visible = GameManager.shield_energy_hits > 0 or (active_shield != null)
	if shield_shader_overlay.visible:
		if GameManager.shaders_enabled:
			var sh = preload("res://shaders/shield_overlay.gdshader")
			if not shield_shader_overlay.material or (shield_shader_overlay.material as ShaderMaterial).shader != sh:
				var mat = ShaderMaterial.new()
				mat.shader = sh
				shield_shader_overlay.material = mat
			shield_shader_overlay.texture = null
			shield_shader_overlay.modulate = Color.WHITE
		else:
			shield_shader_overlay.material = null
			shield_shader_overlay.texture = preload("res://assets/img/shield.png")
			shield_shader_overlay.modulate = Color(1.0, 1.0, 1.0, 0.4)
	
	# 2. Actualizar estados visuales de la interfaz
	_update_states_visibility()
	
	# 3. Propagar actualizaciones a los componentes hijos
	if has_node("CosmicMagnetComponent"): get_node("CosmicMagnetComponent").update_component()
	if has_node("ToxicAuraComponent"): get_node("ToxicAuraComponent").update_component()
	if has_node("TurretComponent"): get_node("TurretComponent").update_component()
	if has_node("AuraRabanescaComponent"): get_node("AuraRabanescaComponent").update_component()
	if has_node("ConquerorAuraComponent"): get_node("ConquerorAuraComponent").update_component()
	if has_node("AlliesManagerComponent"): get_node("AlliesManagerComponent").update_component()

func _update_states_visibility() -> void:
	if not estados_container: return
	if estados_container.has_node("escudo"):
		estados_container.get_node("escudo").visible = GameManager.shield_energy_hits > 0 or (active_shield != null)

func take_damage(amount: int, type: String = "normal") -> void:
	if not GameManager.tutorial_completed:
		return
	# Emitir señal de daño para que componentes como ThornsComponent actúen
	damaged.emit(amount)

	# Absorción de impactos por Escudo de Energía
	if GameManager.shield_energy_hits > 0:
		GameManager.shield_energy_hits -= 1
		if has_node("Sprite2D"):
			var t = create_tween()
			t.tween_property($Sprite2D, "modulate", Color.CYAN, 0.1)
			t.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
		return
		
	current_health -= amount
	health_bar.value = current_health
	spawn_damage_number(amount, false, type)
	
	if current_health <= 0:
		game_over()

func spawn_damage_number(amount: int, is_crit: bool, type: String) -> void:
	if not GameManager.damage_numbers_enabled:
		return
	if not is_crit and GameManager.active_damage_numbers > 40:
		return
		
	var damage_number_scene = preload("res://scenes/damage_number.tscn")
	var l = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(l)
	if l.has_method("set_values"):
		l.set_values(amount, is_crit, global_position + Vector2(randf_range(-20, 20), -40), type)

func game_over() -> void:
	var main_scene = get_tree().current_scene
	if main_scene.has_node("CanvasPausa/GameOver"):
		var go = main_scene.get_node("CanvasPausa/GameOver")
		if go.has_method("show_game_over"):
			go.show_game_over()
		else:
			go.visible = true

func shake_camera(d, i):
	var s = get_tree().current_scene
	if s.has_method("shake_camera"):
		s.shake_camera(d, i)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("kamikaze_attack"):
			take_damage(5)
			area.kamikaze_attack()
