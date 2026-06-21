extends Control

@onready var container: HBoxContainer = $HBoxContainer
@onready var cards: Array = [$HBoxContainer/Card1, $HBoxContainer/Card2, $HBoxContainer/Card3]

var label_font = preload("res://scenes/Font.tres")
var button_font = preload("res://assets/fuentes/BoldPixels.ttf")

var tex_comun = preload("res://assets/img/carta_comun.png")
var tex_rara = preload("res://assets/img/carta_rara.png")
var tex_epica = preload("res://assets/img/carta_epica.png")
var tex_legendaria = preload("res://assets/img/carta_legendaria.png")

var modal_bg: ColorRect

# Combinación de habilidades de 5 niveles y mejoras planas
var upgrades_ids = [
	"heal", "damage_boost", "crit_boost", "auto_speed",
	"fire_slice", "lightning_slice", "explosive_slice", "fire_wall",
	"black_hole", "aura", "turret", "seed_nova",
	"mining_cart", "pet_chayanne", "shield",
	"mirror_slice", "double_slice", # "wind_gust",
	"toxic_compost",
	"energy_shield", "sword_craft", "frost_avalanche", "earthquake",
	"pet_minigun", "thorns", "toxic_aura", "cosmic_magnet",
	"tornado", "axe_thrower", "satellite", "scarecrow",
	"boomerang", "tamed_alien", "mitad_agria", "mitad_dulce",
	# Sinergias (filtradas por eligible_synergies)
	"infernal_hole", "orbital_satellite", "radioactive_swamp", "field_squad",
	"living_fortress", "tajo_negativo", "los_compadres", "war_garden", "infected_potato",
	"excalibur_vegetal", "deforesador", "media_toronja"
]

var current_options = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_background()
	_setup_card_styles()
	
	for i in range(cards.size()):
		var btn = cards[i] as Button
		btn.pressed.connect(_on_card_pressed.bind(i))

func _setup_background() -> void:
	modal_bg = ColorRect.new()
	modal_bg.color = Color(0.05, 0.05, 0.05, 0.7)
	modal_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_bg)
	move_child(modal_bg, 0)
	
	var shader = Shader.new()
	shader.code = "shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, 3.0);
		COLOR.rgb *= 0.4;
	}"
	var mat = ShaderMaterial.new(); mat.shader = shader
	modal_bg.material = mat

func _setup_card_styles() -> void:
	for btn in cards:
		btn.add_theme_font_override("font", button_font)
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(300, 480)

func show_menu() -> void:
	if visible: return
	get_tree().paused = true
	show()
	generate_options()
	
	container.scale = Vector2(0.5, 0.5)
	container.pivot_offset = container.size / 2.0
	var t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(container, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)

func generate_options() -> void:
	current_options.clear()
	var pool = []
	
	# Detectar sinergias elegibles
	var eligible_synergies = []
	if GameManager.get_skill_level("black_hole") >= 1 and GameManager.get_skill_level("fire_slice") >= 1 and not GameManager.has_infernal_hole:
		eligible_synergies.append("infernal_hole")
	if GameManager.get_skill_level("satellite") >= 1 and GameManager.get_skill_level("turret") >= 1 and not GameManager.has_orbital_satellite:
		eligible_synergies.append("orbital_satellite")
	if GameManager.get_skill_level("toxic_aura") >= 1 and GameManager.has_toxic_compost and not GameManager.has_radioactive_swamp:
		eligible_synergies.append("radioactive_swamp")
	if GameManager.get_skill_level("pet_minigun") >= 1 and GameManager.get_skill_level("pet_chayanne") >= 1 and GameManager.get_skill_level("tamed_alien") >= 1 and not GameManager.has_field_squad:
		eligible_synergies.append("field_squad")
	if GameManager.get_skill_level("scarecrow") >= 1 and GameManager.get_skill_level("shield") >= 1 and not GameManager.has_living_fortress:
		eligible_synergies.append("living_fortress")
	if GameManager.get_skill_level("fire_slice") >= 1 and GameManager.get_skill_level("lightning_slice") >= 1 and not GameManager.has_tajo_negativo:
		eligible_synergies.append("tajo_negativo")
	if GameManager.get_skill_level("pet_chayanne") >= 1 and GameManager.get_skill_level("pet_minigun") >= 1 and not GameManager.has_los_compadres:
		eligible_synergies.append("los_compadres")
	if GameManager.get_skill_level("seed_nova") >= 1 and GameManager.get_skill_level("turret") >= 1 and not GameManager.has_war_garden:
		eligible_synergies.append("war_garden")
	if GameManager.get_skill_level("scarecrow") >= 1 and GameManager.get_skill_level("toxic_aura") >= 1 and not GameManager.has_infected_potato:
		eligible_synergies.append("infected_potato")
	if GameManager.has_sword_craft and GameManager.get_skill_level("satellite") >= 1 and not GameManager.has_excalibur_vegetal:
		eligible_synergies.append("excalibur_vegetal")
	if GameManager.get_skill_level("axe_thrower") >= 1 and GameManager.get_skill_level("boomerang") >= 1 and not GameManager.has_deforesador:
		eligible_synergies.append("deforesador")
	if GameManager.has_mitad_agria and GameManager.has_mitad_dulce and not GameManager.has_media_toronja:
		eligible_synergies.append("media_toronja")
		
	for id in upgrades_ids:
		var current_lvl = GameManager.get_skill_level(id)
		
		if GameManager.skills_data.has(id):
			if current_lvl < 5:
				pool.append(id)
		elif GameManager.flat_upgrades.has(id):
			var can_add = true
			if id == "heal" and GameManager.get_skill_level("heal") >= 1: can_add = false
			if id == "damage_boost" and GameManager.get_skill_level("damage_boost") >= 1: can_add = false
			if id == "crit_boost" and GameManager.get_skill_level("crit_boost") >= 1: can_add = false
			if id == "double_slice" and GameManager.has_double_slice: can_add = false
			if id == "wind_gust": can_add = false # Desactivada temporalmente
			if id == "mining_cart" and GameManager.has_mining_cart: can_add = false
			if id == "energy_shield" and GameManager.shield_energy_hits > 0: can_add = false
			if id == "sword_craft" and GameManager.has_sword_craft: can_add = false
			if id == "earthquake" and GameManager.has_earthquake: can_add = false
			if id == "frost_avalanche" and GameManager.has_frost_avalanche: can_add = false
			if id == "mirror_slice" and GameManager.has_mirror_slice: can_add = false
			if id == "toxic_compost" and GameManager.has_toxic_compost: can_add = false
			if id == "mitad_agria" and GameManager.has_mitad_agria: can_add = false
			if id == "mitad_dulce" and GameManager.has_mitad_dulce: can_add = false
			
			# Filtrar sinergias para que solo aparezcan si son elegibles
			var synergy_ids = ["infernal_hole", "orbital_satellite", "radioactive_swamp", "field_squad", "living_fortress", "tajo_negativo", "los_compadres", "war_garden", "infected_potato", "excalibur_vegetal", "deforesador", "media_toronja"]
			if synergy_ids.has(id) and not eligible_synergies.has(id):
				can_add = false
				
			if can_add: pool.append(id)
	
	while pool.size() < 3: pool.append("damage_boost")
	
	pool.shuffle()
	var chosen_this_round = []
	for i in range(3):
		var id = pool.pop_back()
		while chosen_this_round.has(id) and pool.size() > 0:
			id = pool.pop_back()
		if id != null:
			chosen_this_round.append(id)
			
	# Hacer la sinergia más rara de aparecer (35% de probabilidad)
	if eligible_synergies.size() > 0 and randf() < 0.35:
		var forced_synergy = eligible_synergies.pick_random()
		if not chosen_this_round.has(forced_synergy):
			if chosen_this_round.size() > 0:
				chosen_this_round[randi() % chosen_this_round.size()] = forced_synergy
			else:
				chosen_this_round.append(forced_synergy)
				
	# Inyección del +20% para cartas del mazo si deck_level == 1
	if GameManager.deck_level == 1:
		for card in GameManager.deck_equipped_cards:
			if card != "" and pool.has(card) and not chosen_this_round.has(card):
				if randf() < 0.20:
					var replace_idx = -1
					for idx in range(chosen_this_round.size()):
						var chosen_id = chosen_this_round[idx]
						if not eligible_synergies.has(chosen_id) and not GameManager.deck_equipped_cards.has(chosen_id):
							replace_idx = idx
							break
					if replace_idx != -1:
						chosen_this_round[replace_idx] = card

	# Afinidad Tecnológica: +5% de probabilidad de aparición de cartas épicas
	if GameManager.get_deck_affinity() == "Tecnológica":
		for idx in range(chosen_this_round.size()):
			var chosen_id = chosen_this_round[idx]
			var rarity = GameManager.skills_data.get(chosen_id, {}).get("rarity", "comun") if GameManager.skills_data.has(chosen_id) else "comun"
			if rarity != "epica" and rarity != "legendaria" and not eligible_synergies.has(chosen_id):
				if randf() < 0.05:
					var epic_pool = []
					for p_id in pool:
						if GameManager.skills_data.has(p_id) and GameManager.skills_data[p_id].get("rarity") == "epica" and not chosen_this_round.has(p_id):
							epic_pool.append(p_id)
					if epic_pool.size() > 0:
						chosen_this_round[idx] = epic_pool.pick_random()
				
	for i in range(3):
		var id = chosen_this_round[i] if i < chosen_this_round.size() else "damage_boost"
		current_options.append(id)
		
		var current_lvl = GameManager.get_skill_level(id)
		var skill_name = ""
		var desc = ""
		var level_text = ""
		var rarity = "comun"
		
		if GameManager.skills_data.has(id):
			skill_name = GameManager.skills_data[id]["name"]
			rarity = GameManager.skills_data[id].get("rarity", "comun")
			level_text = "Nivel " + str(current_lvl) + " -> " + str(current_lvl + 1)
			desc = GameManager.skills_data[id]["levels"][current_lvl + 1]
		else:
			skill_name = GameManager.flat_upgrades[id]["name"]
			rarity = GameManager.flat_upgrades[id].get("rarity", "comun")
			level_text = "[ MEJORA ]"
			desc = GameManager.flat_upgrades[id]["desc"]
			
		var style = StyleBoxTexture.new()
		if rarity == "legendaria": style.texture = tex_legendaria
		elif rarity == "epica": style.texture = tex_epica
		elif rarity == "rara": style.texture = tex_rara
		else: style.texture = tex_comun
		
		cards[i].add_theme_stylebox_override("normal", style)
		cards[i].add_theme_stylebox_override("hover", style)
		cards[i].add_theme_stylebox_override("pressed", style)
		
		cards[i].text = skill_name.to_upper() + "\n" + level_text + "\n\n" + desc
		cards[i].visible = true

func _on_card_pressed(index: int) -> void:
	if index >= current_options.size(): return
	apply_upgrade(current_options[index])
	
	GameManager.pending_level_ups -= 1
	if GameManager.pending_level_ups > 0:
		generate_options()
	else:
		hide()
		get_tree().paused = false

func apply_upgrade(id: String) -> void:
	# Track card choices and synergies
	if not GameManager.profile_stats.has("card_choices"):
		GameManager.profile_stats["card_choices"] = {}
	var choices = GameManager.profile_stats["card_choices"]
	choices[id] = choices.get(id, 0) + 1
	GameManager.profile_stats["card_choices"] = choices
	
	var syns = ["infernal_hole", "orbital_satellite", "radioactive_swamp", "field_squad", "living_fortress", "tajo_negativo", "los_compadres", "war_garden", "infected_potato", "excalibur_vegetal", "deforesador", "media_toronja"]
	if id in syns:
		if not GameManager.profile_stats.has("sinergias_discovered"):
			GameManager.profile_stats["sinergias_discovered"] = []
		var sd = GameManager.profile_stats["sinergias_discovered"]
		if not sd.has(id):
			sd.append(id)
			GameManager.profile_stats["sinergias_discovered"] = sd
	GameManager.save_game()

	if GameManager.skills_data.has(id) or GameManager.flat_upgrades.has(id):
		GameManager.unlock_skill(id)
		if not GameManager.skill_levels.has(id): GameManager.skill_levels[id] = 0
		GameManager.skill_levels[id] += 1
	
	match id:
		"auto_speed":
			if GameManager.auto_damage == 0:
				GameManager.auto_damage = 1; GameManager.auto_timer.wait_time = 1.0
			else:
				GameManager.auto_damage += 1; GameManager.auto_timer.wait_time = max(0.2, GameManager.auto_timer.wait_time - 0.1)
		
		"fire_slice": GameManager.has_fire_slice = true
		"lightning_slice": GameManager.has_lightning_slice = true
		"explosive_slice": GameManager.has_explosive_slice = true
		"fire_wall": GameManager.has_fire_wall = true
		"black_hole": GameManager.has_black_hole = true
		"aura": GameManager.has_knockback_aura = true
		"mining_cart": GameManager.has_mining_cart = true
		"mirror_slice": GameManager.has_mirror_slice = true
		"double_slice": GameManager.has_double_slice = true
		"wind_gust": GameManager.has_wind_gust = true; GameManager.wind_gust_count += 1
		"toxic_compost": GameManager.has_toxic_compost = true
		"energy_shield": GameManager.shield_energy_hits = 3
		"sword_craft": GameManager.has_sword_craft = true
		"frost_avalanche":
			GameManager.has_frost_avalanche = true
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(enemy) and enemy.has_method("apply_frost"): enemy.apply_frost()
		"earthquake": GameManager.has_earthquake = true
		"infernal_hole": GameManager.has_infernal_hole = true
		"orbital_satellite": GameManager.has_orbital_satellite = true
		"radioactive_swamp": GameManager.has_radioactive_swamp = true
		"field_squad":
			GameManager.has_field_squad = true
			for ally in get_tree().get_nodes_in_group("allies"):
				if ally.has_method("setup_level") and "current_level_val" in ally:
					ally.setup_level(ally.current_level_val)
		"living_fortress":
			GameManager.has_living_fortress = true
			# Re-aplicar a espantapájaros existentes
			for sc in get_tree().get_nodes_in_group("BaseRabanito"):
				if sc.name.begins_with("Scarecrow") and sc.has_method("setup_level"):
					sc.setup_level(sc.current_level_val)
		"tajo_negativo": GameManager.has_tajo_negativo = true
		"los_compadres": GameManager.has_los_compadres = true
		"war_garden": GameManager.has_war_garden = true
		"infected_potato":
			GameManager.has_infected_potato = true
			# Re-aplicar a espantapájaros existentes
			for sc in get_tree().get_nodes_in_group("BaseRabanito"):
				if sc.name.begins_with("Scarecrow") and sc.has_method("setup_level"):
					sc.setup_level(sc.current_level_val)
		"excalibur_vegetal": GameManager.has_excalibur_vegetal = true
		"deforesador": GameManager.has_deforesador = true
		"mitad_agria": GameManager.has_mitad_agria = true
		"mitad_dulce": GameManager.has_mitad_dulce = true
		"media_toronja":
			GameManager.has_media_toronja = true
			var main_scene = get_tree().current_scene
			if main_scene and not main_scene.has_node("MediaToronjaSynergy"):
				var synergy_node = Node.new()
				synergy_node.name = "MediaToronjaSynergy"
				synergy_node.set_script(preload("res://scripts/MediaToronjaSynergy.gd"))
				main_scene.add_child(synergy_node)
