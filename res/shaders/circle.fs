#version 450 core
out vec4 color;

in vec4 pos;

uniform vec3 sprite_color;
uniform sampler2D pixel_texture;
uniform vec3 iResolution;

void main() {
    color.a = 1.0;
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    uv.x *= aspect;

    float fade = 0.005;
    float distance = length(uv);
    float cir = smoothstep(0.0, fade, distance);
    if (cir == 0.0) {
        discard;
    }
    color.rgb *= sprite_color;
}
