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
	quad_vbo: u32,
}

renderer_init :: proc(r: ^renderer, shader: shader) {
	// odinfmt: disable
	r.shader = shader
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

	gl.GenBuffers(1, &r.quad_vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, r.quad_vbo)
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
}

render_prepare :: proc(r: ^renderer, state: ^state) {
	gl.UseProgram(r.shader.program)
}

render :: proc(r: ^renderer, state: ^state) {
	gl.UseProgram(r.shader.program)
	color_loc := gl.GetUniformLocation(r.shader.program, "sprite_color")
	texture_loc := gl.GetUniformLocation(r.shader.program, "pixel_texture")
	model_loc := gl.GetUniformLocation(r.shader.program, "model")

	for i := 0; i < MAX_PIXELS; i += 1 {
		gl.Uniform3f(
			color_loc,
			state.px[i].color.x,
			state.px[i].color.y,
			state.px[i].color.z,
		)
		model: linalg.Matrix4f32 = linalg.MATRIX4F32_IDENTITY
		model *= linalg.matrix4_translate_f32(
			{state.px[i].x, state.px[i].y, 0.0},
		)
		model *= linalg.matrix4_translate_f32(
			{0.5 * state.px[i].size, 0.5 * state.px[i].size, 0.0},
		)
		model *= linalg.matrix4_rotate_f32(
			math.to_radians_f32(0.0),
			{0.0, 0.0, 1.0},
		)
		model *= linalg.matrix4_translate_f32(
			{-0.5 * state.px[i].size, -0.5 * state.px[i].size, 0.0},
		)
		model *= linalg.matrix4_scale_f32(
			{state.px[i].size, state.px[i].size, 0.0},
		)
		gl.UniformMatrix4fv(model_loc, 1, false, raw_data(&model))
		gl.ActiveTexture(gl.TEXTURE0)
		gl.Uniform1i(texture_loc, 0)
		gl.BindTexture(gl.TEXTURE_2D, state.px[i].texture.id)
		// don't need to rebind
		gl.DrawArrays(gl.TRIANGLES, 0, 6)
	}
}

renderer_destroy :: proc(r: ^renderer) {
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}
