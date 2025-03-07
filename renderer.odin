package main

import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:stb/image"

renderer :: struct {
	shader:   shader,
	quad_vao: u32,
}

renderer_init :: proc(r: ^renderer, shader: shader) {
	// odinfmt: disable
	r.shader = shader
	vbo: u32 = 0
	vertices: [24]f32 = {
		//pos       //tex
		0.0, 1.0, 0.0, 1.0,
        1.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 
    
        0.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 0.0, 1.0, 0.0,
	}
	// odinfmt: enable
	gl.GenVertexArrays(1, &r.quad_vao)

	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(vertices),
		&vertices,
		gl.STATIC_DRAW,
	)
	gl.BindVertexArray(r.quad_vao)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(
		0,
		4,
		gl.FLOAT,
		false,
		4 * size_of(f32),
		cast(uintptr)0,
	)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}

draw_sprite :: proc(r: ^renderer, s: sprite) {
	gl.UseProgram(r.shader.program)
	model: linalg.Matrix4f32 = linalg.MATRIX4F32_IDENTITY

	model *= linalg.matrix4_translate_f32({s.position.x, s.position.y, 0.0})
	model *= linalg.matrix4_translate_f32(
		{0.5 * s.scale.x, 0.5 * s.scale.y, 0.0},
	)
	model *= linalg.matrix4_rotate_f32(
		math.to_radians_f32(s.rotation),
		{0.0, 0.0, 1.0},
	)
	model *= linalg.matrix4_translate_f32(
		{-0.5 * s.scale.x, -0.5 * s.scale.y, 0.0},
	)
	model *= linalg.matrix4_scale_f32({s.scale.x, s.scale.y, 0.0})

	model_loc := gl.GetUniformLocation(r.shader.program, "model")
	gl.UniformMatrix4fv(model_loc, 1, false, raw_data(&model))
	color_loc := gl.GetUniformLocation(r.shader.program, "sprite_color")
	gl.Uniform3f(color_loc, s.color.x, s.color.y, s.color.z)

	gl.ActiveTexture(gl.TEXTURE0)
	texture_loc := gl.GetUniformLocation(r.shader.program, "block_texture")
	gl.Uniform1i(texture_loc, 0)
	gl.BindTexture(gl.TEXTURE_2D, s.texture)
	gl.BindVertexArray(r.quad_vao)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	gl.BindVertexArray(0)
}
