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

sprite :: struct {
	position: linalg.Vector2f32,
	scale:    linalg.Vector2f32,
	color:    linalg.Vector3f32,
	rotation: f32,
	texture:  u32,
}

update :: proc(delta_time: f32, sprites: [dynamic]sprite) {
	for i := 0; i < len(sprites); i += 1 {
		sprites[i].position += {0.0, -250.0 * delta_time}
	}
}

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
		"res/shaders/sprite.vs",
		"res/shaders/sprite.fs",
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

	grass: texture = texture_create("res/textures/grass.png")

	sprites: [dynamic]sprite


	for !glfw.WindowShouldClose(window) {
		current_frame_time: f32 = cast(f32)glfw.GetTime()
		frame_time: f32 = current_frame_time - last_frame_time
		last_frame_time = current_frame_time
		accum += frame_time

		for accum >= dt {
			// TODO: update
			update(dt, sprites)
			accum -= dt
		}

		// EVENTS
		glfw.PollEvents()

		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		if glfw.GetKey(window, glfw.KEY_SPACE) == glfw.PRESS {
			if glfw.GetKey(window, glfw.KEY_SPACE) == glfw.RELEASE {
				append(
					&sprites,
					sprite {
						position = {0.0, WINDOW_HEIGHT - 50},
						rotation = 0.0,
						texture = grass.id,
						scale = {100.0, 100.0},
						color = {1.0, 1.0, 1.0},
					},
				)
			}
		}

		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.ClearColor(0.0, 0.0, 0.0, 1.0)

		// TODO: Actually render
		for i := 0; i < len(sprites); i += 1 {
			draw_sprite(&renderer, sprites[i])
		}

		glfw.SwapBuffers(window)
	}
	shader_delete(&shader)
	glfw.DestroyWindow(window)
	glfw.Terminate()
	log.destroy_console_logger(context.logger)
	return
}
