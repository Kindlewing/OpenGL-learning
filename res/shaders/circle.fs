#version 450 core
in vec2 uv

out vec4 color;

float fade = 0.005;
float distance = 1.0 - length(uv);
vec3 col = vec3(smoothstep(0.0, fade, distance));

void main() {
    color = col;
    uv = gl_FragCoord / iResolution.xy;
}
