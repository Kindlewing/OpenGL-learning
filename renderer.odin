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
	r.mode =.CIRCLE
	r.shaders["QUAD"] = shader_create("res/shaders/quad.vs", "res/shaders/quad.fs")	
	r.shaders["CIRCLE"] = shader_create("res/shaders/circle.vs", "res/shaders/circle.fs")	

	vertices: [24]f32 = {
		//pos          //tex
	   -1.0,  1.0, 0.0, 1.0,  // Top-left
		1.0, -1.0, 1.0, 0.0,  // Bottom-right
	   -1.0, -1.0, 0.0, 0.0,  // Bottom-left

	   -1.0,  1.0, 0.0, 1.0,  // Top-left (repeated)
		1.0,  1.0, 1.0, 1.0,  // Top-right
		1.0, -1.0, 1.0, 0.0,  // Bottom-right (repeated)
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

	for key in r.shaders {
		gl.UseProgram(r.shaders[key].program)
		proj_loc: i32 = gl.GetUniformLocation(r.shaders[key].program, "proj")
		if proj_loc == -1 {
			log.fatalf("Projection matrix not found in shader")
			os.exit(-1)
		}
		gl.UniformMatrix4fv(
			proj_loc,
			1,
			false,
			raw_data(&cam.projection_matrix),
		)
	}
}

render_prepare :: proc() {
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}

render :: proc(r: ^renderer, state: ^state) {
	render_prepare()
	proj_loc, resolution_loc, color_loc, model_loc, texture_loc: i32
	origin_loc, radius_loc: i32
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
		resolution_loc = gl.GetUniformLocation(sh.program, "u_resolution")
		color_loc = gl.GetUniformLocation(sh.program, "sprite_color")
		texture_loc = gl.GetUniformLocation(sh.program, "pixel_texture")
		model_loc = gl.GetUniformLocation(sh.program, "model")
		gl.Uniform2f(resolution_loc, WINDOW_WIDTH, WINDOW_HEIGHT)

		radius_loc = gl.GetUniformLocation(sh.program, "radius")
		gl.Uniform1f(radius_loc, state.px[0].size)
		origin_loc = gl.GetUniformLocation(sh.program, "origin")
		gl.Uniform2f(origin_loc, state.px[0].size, state.px[0].size)
	}
	for i := 0; i < MAX_PIXELS; i += 1 {
		gl.Uniform3f(
			color_loc,
			state.px[i].color.x,
			state.px[i].color.y,
			state.px[i].color.z,
		)
		model: linalg.Matrix4f32 = linalg.MATRIX4F32_IDENTITY
		model *= linalg.matrix4_translate_f32(
			{state.px[i].pos.x, state.px[i].pos.y, 0.0},
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
			gl.Uniform1f(radius_loc, 0.5 * state.px[i].size)
			gl.Uniform2f(resolution_loc, WINDOW_WIDTH, WINDOW_HEIGHT)
		}
		gl.UniformMatrix4fv(model_loc, 1, false, raw_data(&model))
		gl.BindTexture(gl.TEXTURE_2D, state.px[i].texture.id)
		gl.Uniform1i(texture_loc, 0)
		// don't need to rebind
		gl.DrawArrays(gl.TRIANGLES, 0, 6)
	}
}

renderer_destroy :: proc(r: ^renderer) {
	for key in r.shaders {
		shader_delete(&r.shaders[key])
	}
	delete_map(r.shaders)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}
