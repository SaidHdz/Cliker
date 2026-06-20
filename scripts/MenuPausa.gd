extends Control

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup Blur
	var blur_bg = ColorRect.new()
	blur_bg.color = Color(0,0,0,0.5)
	blur_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(blur_bg)
	move_child(blur_bg, 0)
	
	var shader = Shader.new()
	shader.code = "shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, 3.0);
		COLOR.rgb *= 0.6;
	}"
	var mat = ShaderMaterial.new(); mat.shader = shader
	blur_bg.material = mat

func _on_btn_resume_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_btn_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/MenuInicio.tscn")

func toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
