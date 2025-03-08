#version 450 core
layout(location = 0) in vec4 vertex;

out vec2 tex_coords;

uniform mat4 proj;
uniform mat4 instance_matrix;

void main() {
    tex_coords = vertex.zw;
    gl_Position = proj * instance_matrix * vec4(vertex.xy, 0.0, 1.0);
}
