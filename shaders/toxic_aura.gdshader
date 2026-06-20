shader_type canvas_item;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float aura = smoothstep(0.5, 0.0, dist);
	COLOR = vec4(0.2, 0.8, 0.2, aura * 0.3 * (0.8 + 0.2 * sin(TIME * 3.0)));
}
