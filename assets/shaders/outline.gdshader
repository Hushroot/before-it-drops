// ORIGIN: NEW, written by team. Code only, no art.
// Same dark-purple outline on every sprite, so art from different sources looks like one game.
shader_type canvas_item;
uniform vec4 outline_color : source_color = vec4(0.08, 0.05, 0.10, 1.0);
uniform float width = 1.0;   // in texels (set per sprite so it's ~1.3 screen px)
varying vec4 tint;

void vertex() {
	tint = COLOR;   // keeps modulate (hit flashes, fades) working
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.4) {
		vec2 p = TEXTURE_PIXEL_SIZE * width;
		float a = 0.0;
		a += texture(TEXTURE, UV + vec2(p.x, 0.0)).a;
		a += texture(TEXTURE, UV - vec2(p.x, 0.0)).a;
		a += texture(TEXTURE, UV + vec2(0.0, p.y)).a;
		a += texture(TEXTURE, UV - vec2(0.0, p.y)).a;
		a += texture(TEXTURE, UV + p * 0.7).a;
		a += texture(TEXTURE, UV - p * 0.7).a;
		a += texture(TEXTURE, UV + vec2(p.x, -p.y) * 0.7).a;
		a += texture(TEXTURE, UV + vec2(-p.x, p.y) * 0.7).a;
		if (a > 0.4) {
			c = vec4(outline_color.rgb, outline_color.a * tint.a);
			COLOR = c;
		} else {
			COLOR = c * tint;
		}
	} else {
		COLOR = c * tint;
	}
}
