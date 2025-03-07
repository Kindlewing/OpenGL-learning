package main

import "core:log"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"

camera :: struct {
	zoom:              f32,
	shader:            shader,
	projection_matrix: linalg.Matrix4f32,
	aspect_ratio:      f32,
}

camera_init :: proc(
	cam: ^camera,
	shader: shader,
	zoom: f32 = 1.0,
	aspect: f32,
) {
	cam.zoom = zoom
	cam.shader = shader
	cam.aspect_ratio = aspect

	if cam.aspect_ratio >= 1 {
		cam.projection_matrix = linalg.matrix_ortho3d_f32(
			-WINDOW_WIDTH / cam.zoom,
			WINDOW_WIDTH / cam.zoom,
			-WINDOW_HEIGHT / cam.zoom,
			WINDOW_HEIGHT / cam.zoom,
			0,
			1,
		)
	} else {
		cam.projection_matrix = linalg.matrix_ortho3d_f32(
			(-WINDOW_WIDTH / cam.zoom) / cam.aspect_ratio,
			(WINDOW_WIDTH / cam.zoom) / cam.aspect_ratio,
			-WINDOW_HEIGHT / cam.zoom,
			WINDOW_HEIGHT / cam.zoom,
			0,
			1,
		)
	}

	proj_loc: i32 = gl.GetUniformLocation(cam.shader.program, "proj")
	if proj_loc == -1 {
		log.fatalf("Projection matrix not found in shader")
		os.exit(-1)
	}
	gl.UniformMatrix4fv(proj_loc, 1, false, raw_data(&cam.projection_matrix))
}
