package main

import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:stb/image"

renderer :: struct {
	shader:         shader,
	model_matrices: [dynamic]linalg.Matrix4f32,
	quad_vao:       u32,
}

renderer_init :: proc(r: ^renderer, shader: shader) {
	// odinfmt: disable
	r.shader = shader
	r.model_matrices = make_dynamic_array_len_cap([dynamic]linalg.Matrix4f32, 
		MAX_PIXELS, MAX_PIXELS)
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
	gl.UseProgram(r.shader.program)
}

render_prepare :: proc(r: ^renderer) {
	for px in global_state.pixels {
		model: linalg.Matrix4f32 = linalg.MATRIX4F32_IDENTITY
		model *= linalg.matrix4_translate_f32(
			{px.position.x, px.position.y, 0.0},
		)
		model *= linalg.matrix4_translate_f32(
			{0.5 * px.size, 0.5 * px.size, 0.0},
		)
		model *= linalg.matrix4_rotate_f32(
			math.to_radians_f32(0.0),
			{0.0, 0.0, 1.0},
		)
		model *= linalg.matrix4_translate_f32(
			{-0.5 * px.size, -0.5 * px.size, 0.0},
		)
		model *= linalg.matrix4_scale_f32({px.size, px.size, 0.0})
		append(&r.model_matrices, model)
	}
}

render :: proc(r: ^renderer) {
	render_prepare(r)
	for i := 0; i < MAX_PIXELS; i += 1 {

		model_loc := gl.GetUniformLocation(r.shader.program, "instance_matrix")
		gl.UniformMatrix4fv(
			model_loc,
			1,
			false,
			raw_data(&r.model_matrices[i]),
		)
		color_loc := gl.GetUniformLocation(r.shader.program, "sprite_color")
		gl.Uniform3f(
			color_loc,
			global_state.pixels[i].color.x,
			global_state.pixels[i].color.y,
			global_state.pixels[i].color.z,
		)

		gl.ActiveTexture(gl.TEXTURE0)
		texture_loc := gl.GetUniformLocation(r.shader.program, "pixel_texture")
		gl.Uniform1i(texture_loc, 0)
		gl.BindTexture(gl.TEXTURE_2D, global_state.pixels[i].texture.id)
		gl.BindVertexArray(r.quad_vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 6)
		gl.BindVertexArray(0)
	}
}
