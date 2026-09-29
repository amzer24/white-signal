shader_type canvas_item;
// World atmosphere pass, drawn over the game and under the HUD-free CRT pass.
//  1. Darkness: inside the level's dark stretches only light sources show.
//     Light falls off in dithered steps so it stays pixel art.
//  2. Lightning: a short flash that lifts everything towards white.
//  3. Tint: the four greys are mapped to this world's four colours, so all the
//     art stays readable and each world gets its own light.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec2 cam = vec2(0.0);                 // world position of the screen's top-left
uniform vec4 dark_ranges[8];                  // x0, x1 (world px), fade px, strength
uniform int dark_count = 0;
uniform vec3 lights[24];                      // world x, world y, radius
uniform int light_count = 0;
uniform vec4 clear_rects[16];                 // screen px x0, y0, x1, y1 the dark leaves alone: text, menus, bubbles
uniform int clear_count = 0;
uniform float flash = 0.0;                    // 0 none .. 1 full lightning
uniform vec3 ramp0 : source_color = vec3(0.043);
uniform vec3 ramp1 : source_color = vec3(0.227);
uniform vec3 ramp2 : source_color = vec3(0.541);
uniform vec3 ramp3 : source_color = vec3(0.949);
uniform float hud_rows = 17.0;                // the HUD strip is never darkened
uniform vec2 view = vec2(480.0, 270.0);       // logical screen size (wider on wide screens)

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}

vec3 tint(float l) {
	// the palette's four greys sit at these brightness levels
	if (l < 0.227) return mix(ramp0, ramp1, clamp((l - 0.043) / (0.227 - 0.043), 0.0, 1.0));
	if (l < 0.541) return mix(ramp1, ramp2, (l - 0.227) / (0.541 - 0.227));
	return mix(ramp2, ramp3, clamp((l - 0.541) / (0.949 - 0.541), 0.0, 1.0));
}

void fragment() {
	vec2 px = floor(UV * view);
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	if (px.y >= hud_rows) {
		vec2 w = px + cam;
		float dark = 0.0;
		for (int i = 0; i < dark_count; i++) {
			vec4 d = dark_ranges[i];
			float inside = min(w.x - d.x, d.y - w.x);
			dark = max(dark, clamp(inside / max(d.z, 1.0), 0.0, 1.0) * d.w);
		}
		for (int i = 0; i < clear_count; i++) {
			vec4 r = clear_rects[i];
			if (px.x >= r.x && px.y >= r.y && px.x < r.z && px.y < r.w) dark = 0.0;
		}
		if (dark > 0.0) {
			float lit = 0.0;
			for (int i = 0; i < light_count; i++) {
				float dist = length(w - lights[i].xy) / lights[i].z;
				lit = max(lit, clamp(1.4 - dist * 1.4, 0.0, 1.0));
			}
			float shade = dark * (1.0 - lit) * (1.0 - flash);
			// dithered steps: a pixel goes dark when the shade beats its threshold
			if (shade > bayer4(px) * 0.9 + 0.05) l = min(l, 0.043);
			else if (shade > 0.5) l = min(l, 0.227);
		}
		l = mix(l, 1.0, flash * 0.85);
	}
	COLOR = vec4(tint(l), 1.0);
}
