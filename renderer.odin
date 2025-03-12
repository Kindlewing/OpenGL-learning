package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:stb/image"

renderer :: struct {
	shaders:  map[string]shader,
	quad_vao: u32,
	quad_vbo: u32,
	mode:     render_mode,
}

render_mode :: enum {
	QUAD,
	CIRCLE,
}

renderer_init :: proc(r: ^renderer, cam: ^camera) {
	// odinfmt: disable
	r.shaders["QUAD"] = shader_create("res/shaders/quad.vs", "res/shaders/quad.fs")	
	r.shaders["CIRCLE"] = shader_create("res/shaders/circle.vs", "res/shaders/circle.fs")	

	r.mode =.CIRCLE

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


render :: proc(r: ^renderer, state: ^state) {
	uv_loc, color_loc, model_loc, texture_loc: i32
	switch r.mode {
	case .QUAD:
		sh := r.shaders["QUAD"]
		gl.UseProgram(sh.program)
		color_loc = gl.GetUniformLocation(sh.program, "sprite_color")
		texture_loc = gl.GetUniformLocation(sh.program, "pixel_texture")
		model_loc = gl.GetUniformLocation(sh.program, "model")
	case .CIRCLE:
		sh := r.shaders["CIRCLE"]
		gl.UseProgram(sh.program)
		uv_loc = gl.GetUniformLocation(sh.program, "iResolution")
		color_loc = gl.GetUniformLocation(sh.program, "sprite_color")
		texture_loc = gl.GetUniformLocation(sh.program, "pixel_texture")
		model_loc = gl.GetUniformLocation(sh.program, "model")
		gl.Uniform3f(uv_loc, WINDOW_WIDTH, WINDOW_HEIGHT, 0.0)
	}
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, state.px[0].texture.id)

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
		if r.mode == .CIRCLE {
			gl.Uniform3f(uv_loc, WINDOW_WIDTH, WINDOW_HEIGHT, 0.0)
		}
		gl.UniformMatrix4fv(model_loc, 1, false, raw_data(&model))
		gl.Uniform1i(texture_loc, 0)
		// don't need to rebind
		gl.DrawArrays(gl.TRIANGLES, 0, 6)
	}
}

renderer_destroy :: proc(r: ^renderer) {
	assert(1 == 0, "I FORGOT TO DELETE SHADERS")
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}
