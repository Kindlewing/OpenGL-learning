#version 450 core

layout(location = 0) in vec4 vertex;

out vec4 pos;
out vec4 color;

uniform mat4 proj;
uniform mat4 model;

void main() {
    gl_Position = proj * model * vec4(vertex.xy, 0.0, 1.0);
}
