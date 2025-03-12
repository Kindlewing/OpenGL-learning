#version 450 core

layout(location = 0) in vec4 vertex;

out vec2 tex_coords;
out vec2 uv;

uniform mat4 proj;
uniform mat4 model;
uniform vec3 iResolution;

void main() {
    tex_coords = vertex.zw;
    uv = iResolution;
    gl_Position = proj * model * vec4(vertex.xy, 0.0, 1.0);
}
