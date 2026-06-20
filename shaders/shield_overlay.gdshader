shader_type canvas_item;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float ring = smoothstep(0.35, 0.45, dist) * smoothstep(0.55, 0.45, dist);
	COLOR = vec4(0.0, 0.7, 1.0, ring * (0.6 + 0.4 * sin(TIME * 4.0)));
}
