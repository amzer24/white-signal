shader_type canvas_item;
render_mode unshaded;

// Limit generated art at render time; retain original PNGs and alpha unchanged.
uniform vec2 logical_size = vec2(640.0,360.0);
uniform float mode = 1.0;
uniform float reveal = 0.0;
uniform vec2 memory_at = vec2(-1000.0);
uniform vec2 player_at = vec2(48.0,223.0);
uniform vec2 lamp_at = vec2(360.0,70.0);
uniform vec4 beacon_x = vec4(-1000.0);
uniform float ceiling = 0.24;

float pool(vec2 p, vec2 origin, float radius) {
    return 1.0 - smoothstep(radius * 0.2, radius, distance(p,origin));
}

void fragment() {
    vec2 uv = (floor(UV * logical_size) + vec2(0.5)) / logical_size;
    vec4 tex = texture(TEXTURE, uv);
    vec2 p = floor(SCREEN_UV * vec2(480.0,270.0));
    float energy = clamp(dot(tex.rgb,vec3(0.299,0.587,0.114)) * 3.0,0.0,1.0);
    float ambient = mode < 0.5 ? 1.0 : (mode > 1.5 ? 0.78 : 0.26);
    float light = pool(p,player_at,85.0)*0.16;
    light += pool(p,memory_at,300.0)*reveal*0.95;
    light += pool(p,lamp_at,125.0)*0.20;
    light += pool(p,vec2(beacon_x.x,185.0),95.0)*0.25;
    light += pool(p,vec2(beacon_x.y,185.0),95.0)*0.25;
    light += pool(p,vec2(beacon_x.z,185.0),95.0)*0.25;
    light += pool(p,vec2(beacon_x.w,185.0),95.0)*0.25;
    float value = clamp(mix(0.025,ceiling,energy) * clamp(ambient+light,0.0,1.0),0.0,ceiling);
    value = floor(value*32.0+0.5)/32.0;
    COLOR = vec4(vec3(value),tex.a);
}
