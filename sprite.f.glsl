#version 450 core
in vec2 tex_coords;
out vec4 color;
uniform vec3 sprite_color;
uniform sampler2D block_texture;

void main() {
    color = vec4(sprite_color, 1.0) * texture(block_texture, tex_coords);
}
