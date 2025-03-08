package main
import "core:math/linalg"
import "core:math/rand"
import "core:time"

MAX_PIXELS :: 10

pixel :: struct {
	position: linalg.Vector2f32,
	size:     f32,
	color:    linalg.Vector3f32,
	type:     pixel_type,
	texture:  texture,
}

state :: struct {
	pixels: [MAX_PIXELS]pixel,
}

pixel_type :: enum {
	SAND,
}
global_state: state

state_init :: proc() {
	sand: texture = texture_create("res/textures/sand.png")
	gen := rand.create(u64(time.tick_now()._nsec))
	for i := 0; i < MAX_PIXELS; i += 1 {
		pixel: pixel
		pixel.size = 80.0
		pos_x := rand.float32_range(
			-WINDOW_WIDTH + pixel.size,
			WINDOW_WIDTH - pixel.size,
		)
		pos_y := rand.float32_range(
			-WINDOW_HEIGHT + pixel.size,
			WINDOW_HEIGHT - pixel.size,
		)
		pixel.position = {pos_x, pos_y}
		pixel.type = .SAND
		pixel.color = {1.0, 1.0, 1.0}
		pixel.texture = sand
		global_state.pixels[i] = pixel
	}
}

simulation_update :: proc(delta_time: f32) {
	for i := 0; i < MAX_PIXELS; i += 1 {
		global_state.pixels[i].position.y += -10.0 * delta_time
	}
}
