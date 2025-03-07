#version 450 core
in vec2 TexCoord;
out vec4 color;
uniform vec3 sprite_color;
uniform sampler2D block_texture;

void main() {
    color = texture(block_texture, TexCoord);
}
