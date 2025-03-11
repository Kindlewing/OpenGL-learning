package main

import "base:runtime"
import "core:fmt"
import "core:image/png"
import "core:log"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"
import "vendor:stb/image"

GLFW_MAJOR_VERSION :: 4
GLFW_MINOR_VERSION :: 3

WINDOW_WIDTH :: 1000
WINDOW_HEIGHT :: 800

MAX_PIXELS :: 5

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				for _, entry in track.allocation_map {
					fmt.eprintf(
						"%v leaked %v bytes\n",
						entry.location,
						entry.size,
					)
				}
			}
			if len(track.bad_free_array) > 0 {
				for entry in track.bad_free_array {
					fmt.eprintf(
						"%v bad free at %v\n",
						entry.location,
						entry.memory,
					)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

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

	state: ^state = new(state)
	defer free(state)

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
	dt: f32 = 1.0 / 60.0
	fps_frame_time: f32 = 0.0
	frame_count: int = 0

	state_init(state)
	for !glfw.WindowShouldClose(window) {
		current_frame_time: f32 = cast(f32)glfw.GetTime()
		frame_time: f32 = current_frame_time - last_frame_time
		if frame_time > 0.25 {
			frame_time = 0.25
		}
		last_frame_time = current_frame_time
		accum += frame_time
		fps_frame_time += frame_time

		for accum >= dt {
			simulation_update(dt, state)
			accum -= dt
		}

		glfw.PollEvents()
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.ClearColor(0.0, 0.0, 0.0, 1.0)

		render(&renderer, state)

		if frame_count == 60 {
			fps := cast(f32)frame_count / fps_frame_time
			fmt.printf("FPS: %f\n", fps)
			frame_count = 0
			fps_frame_time = 0.0
		}

		glfw.SwapBuffers(window)
		frame_count += 1
	}
	renderer_destroy(&renderer)
	shader_delete(&shader)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	log.destroy_console_logger(context.logger)
	return
}
