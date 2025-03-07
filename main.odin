package main

import "base:runtime"
import "core:fmt"
import "core:image/png"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "vendor:stb/image"

GLFW_MAJOR_VERSION :: 4
GLFW_MINOR_VERSION :: 3

WINDOW_WIDTH :: 1920
WINDOW_HEIGHT :: 1080

sprite :: struct {
	position: linalg.Vector2f32,
	rotation: f32,
	scale:    linalg.Vector2f32,
	color:    linalg.Vector3f32,
	texture:  u32,
}

update :: proc(dt: f32, shader_program: ^u32) {

}

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

main :: proc() {
	context.logger = log.create_console_logger()
	extern_context := runtime.Context {
		logger = context.logger,
	}

	if !glfw.Init() {
		log.fatal("Unable to initialize GLFW")
		glfw.Terminate()
		return
	}
	log.debug("GLFW initialized successfully")
	glfw.WindowHint(glfw.RESIZABLE, true)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GLFW_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GLFW_MINOR_VERSION)

	when ODIN_DEBUG {
		glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, true)
		flags: i32
		if flags & gl.CONTEXT_FLAG_DEBUG_BIT == 1 {
			gl.Enable(gl.DEBUG_OUTPUT)
			gl.Enable(gl.DEBUG_OUTPUT_SYNCHRONOUS)
			gl.DebugMessageCallback(gl_debug_output, &extern_context)
		}
	}
	log.debug("About to create the window")
	window := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Game", nil, nil)
	if window == nil {
		log.fatal("Error creating window")
		glfw.Terminate()
		return
	}
	log.debug("Window created successfully")
	glfw.MakeContextCurrent(window)


	glfw.SetFramebufferSizeCallback(window, resize_callback)
	log.debug("Loading GLAD procs\n")
	gl.load_up_to(GLFW_MAJOR_VERSION, GLFW_MINOR_VERSION, set_addr_type)
	log.debug("Set the viewport\n")
	gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

	//odinfmt: enable

	shader: shader = shader_create(
		"res/shaders/sprite.vs",
		"res/shaders/sprite.fs",
	)

	texture: u32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(
		gl.TEXTURE_2D,
		gl.TEXTURE_MIN_FILTER,
		gl.LINEAR_MIPMAP_LINEAR,
	)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	width, height, nr_chan: i32
	image.set_flip_vertically_on_load(1)
	data := image.load("res/textures/grass.png", &width, &height, &nr_chan, 0)
	if data == nil {
		log.fatal("Failed to load texture: assets/grass.png")
		log.fatal(image.failure_reason())
		os.exit(-1)
	}
	fmt: i32
	if nr_chan == 4 {
		fmt = gl.RGBA
	} else {
		fmt = gl.RGB
	}
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		fmt,
		width,
		height,
		0,
		cast(u32)fmt,
		gl.UNSIGNED_BYTE,
		data,
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	image.image_free(data)

	s := sprite {
		position = {0.0, 0.0},
		rotation = 0.0,
		scale    = {200.0, 200.0},
		color    = {1.0, 1.0, 1.0},
		texture  = texture,
	}


	camera: camera
	init_camera(
		&camera,
		shader,
		aspect = cast(f32)WINDOW_WIDTH / cast(f32)WINDOW_HEIGHT,
	)
	renderer: renderer = {
		quad_vao = 0,
		shader   = shader,
	}
	init_renderer(&renderer)

	glfw.SetWindowUserPointer(window, &camera)

	last_frame_time: f32 = cast(f32)glfw.GetTime()
	accum: f32 = 0.0
	dt: f32 = 0.01
	for !glfw.WindowShouldClose(window) {
		current_frame_time: f32 = cast(f32)glfw.GetTime()
		frame_time: f32 = current_frame_time - last_frame_time
		last_frame_time = current_frame_time
		accum += frame_time

		for accum >= dt {
			update(dt, &shader.program)
			accum -= dt
		}

		// EVENTS
		glfw.PollEvents()

		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.ClearColor(0.0, 0.0, 0.0, 1.0)

		draw_sprite(&renderer, s)

		glfw.SwapBuffers(window)
	}
	shader_delete(&shader)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	log.destroy_console_logger(context.logger)
	return
}
