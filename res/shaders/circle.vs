#version 450 core

layout(location = 0) in vec4 vertex;

out vec2 pos;

uniform mat4 proj;
uniform mat4 model;

void main() {
    pos = vec2(vertex.x, vertex.y);
    gl_Position = proj * model * vec4(vertex.xy, 0.0, 1.0);
}
