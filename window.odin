package main

import "base:runtime"
import "core:log"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"

set_addr_type :: proc(p: rawptr, name: cstring) {
	(^rawptr)(p)^ = glfw.GetProcAddress(name)
}

resize_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
	w := cast(f32)width
	h := cast(f32)height
	cam := cast(^camera)glfw.GetWindowUserPointer(window)
	cam.aspect_ratio = w / h

	if cam.aspect_ratio >= 1 {
		cam.projection_matrix = linalg.matrix_ortho3d_f32(
			-w / cam.aspect_ratio,
			w / cam.aspect_ratio,
			-h,
			h,
			0,
			1,
		)
	} else {
		cam.projection_matrix = linalg.matrix_ortho3d_f32(
			-w,
			w,
			-h / cam.aspect_ratio,
			h / cam.aspect_ratio,
			0,
			1,
		)
	}
	proj_loc: i32 = gl.GetUniformLocation(cam.shader.program, "proj")
	if proj_loc == -1 {
		os.exit(-1)
	}
	gl.UniformMatrix4fv(proj_loc, 1, false, raw_data(&cam.projection_matrix))
}
