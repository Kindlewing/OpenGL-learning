package main

import "base:runtime"
import "core:fmt"
import "core:image/png"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "vendor:stb/image"

GLFW_MAJOR_VERSION :: 4
GLFW_MINOR_VERSION :: 3

WINDOW_WIDTH :: 1000
WINDOW_HEIGHT :: 800

main :: proc() {
	context.logger = log.create_console_logger()
	ctx := runtime.Context {
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
			gl.DebugMessageCallback(gl_debug_output, &ctx)
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


	log.debug("Loading GLAD procs\n")
	gl.load_up_to(GLFW_MAJOR_VERSION, GLFW_MINOR_VERSION, set_addr_type)
	log.debug("Set the viewport\n")
	gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)


	shader: shader = shader_create(
		"res/shaders/pixel.vs",
		"res/shaders/pixel.fs",
	)

	camera: camera
	camera_init(
		&camera,
		shader,
		aspect = cast(f32)WINDOW_WIDTH / cast(f32)WINDOW_HEIGHT,
	)
	glfw.SetFramebufferSizeCallback(window, resize_callback)
	renderer: renderer
	renderer_init(&renderer, shader)

	glfw.SetWindowUserPointer(window, &camera)


	last_frame_time: f32 = cast(f32)glfw.GetTime()
	accum: f32 = 0.0
	dt: f32 = 0.01


	state_init()
	for !glfw.WindowShouldClose(window) {
		current_frame_time: f32 = cast(f32)glfw.GetTime()
		frame_time: f32 = current_frame_time - last_frame_time
		if frame_time > 0.25 {
			frame_time = 0.25
		}
		last_frame_time = current_frame_time
		accum += frame_time

		for accum >= dt {
			// TODO: update
			simulation_update(dt)
			accum -= dt
		}

		// EVENTS
		glfw.PollEvents()

		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.ClearColor(0.0, 0.0, 0.0, 1.0)

		// TODO: Actually render
		render(&renderer)

		glfw.SwapBuffers(window)
	}
	shader_delete(&shader)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	log.destroy_console_logger(context.logger)
	return
}
