// ORIGIN: NEW, written by team. Code only, no art.
// One Vice Slime "color grade" over every level: warm pink sunset at the top,
// purple vignette at the edges. Ties the different art styles together.
shader_type canvas_item;
uniform vec4 top_tint : source_color = vec4(1.0, 0.45, 0.65, 1.0);
uniform vec4 edge_tint : source_color = vec4(0.18, 0.04, 0.25, 1.0);
uniform float strength = 1.0;

void fragment() {
	float top = pow(1.0 - UV.y, 3.0) * 0.12;
	vec2 d = UV - vec2(0.5);
	float vig = smoothstep(0.35, 0.78, length(d * vec2(1.1, 1.0))) * 0.42;
	vec3 col = mix(top_tint.rgb, edge_tint.rgb, vig / max(vig + top, 0.001));
	COLOR = vec4(col, (top + vig) * strength);
}
