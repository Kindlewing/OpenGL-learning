#version 450 core
out vec4 frag_color;

in vec2 pos;
uniform vec3 sprite_color;
uniform float radius;
uniform vec2 u_resolution;

void main() {
    float d = length(pos);
    float thickness = 0.5;
    float fade = 0.005;
    if (d > 1.0) discard;
    float alpha = smoothstep(thickness + fade, thickness, d);
    vec3 col = sprite_color * alpha;

    frag_color = vec4(sprite_color, alpha);
}
