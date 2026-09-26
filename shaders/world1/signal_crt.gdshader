shader_type canvas_item;
render_mode unshaded;

// WHITE SIGNAL, World 1 post pass: a soft bloom on white only, scanlines at
// the game's own logical pixel rows (every 3rd row, like hud.gd) and a dark
// broadcast edge. Everything is sampled on the 480x270 logical grid, so the
// pixel art stays crisp. Toggle it by hiding the ColorRect.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 logical = vec2(480.0, 270.0);
uniform float bloom : hint_range(0.0, 1.0) = 0.32;
uniform float scan : hint_range(0.0, 0.5) = 0.14;
uniform float edge : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / logical;
	vec3 c = texture(screen_tex, uv).rgb;

	// bloom: only near-white pixels glow (white = alive or important)
	vec3 glow = vec3(0.0);
	float wsum = 0.0;
	for (int i = -2; i <= 2; i++) {
		for (int j = -2; j <= 2; j++) {
			vec2 o = vec2(float(i), float(j));
			float w = 1.0 / (1.0 + dot(o, o));
			vec3 s = texture(screen_tex, uv + o * px).rgb;
			float lum = dot(s, vec3(0.333));
			glow += smoothstep(0.78, 0.92, lum) * w;
			wsum += w;
		}
	}
	c += vec3(glow / wsum) * bloom;

	// scanlines on logical rows, plus a faint split inside each row at 2x
	float row = floor(uv.y * logical.y);
	if (mod(row, 3.0) == 2.0) {
		c *= 1.0 - scan;
	}
	float sub = fract(uv.y * logical.y);
	c *= 1.0 - 0.06 * step(0.5, sub);

	// dark broadcast edge: stronger in the corners
	vec2 d = uv - 0.5;
	d.x *= logical.x / logical.y;
	float v = 1.0 - smoothstep(0.55, 1.05, length(d)) * edge;
	c *= v;

	COLOR = vec4(c, 1.0);
}
