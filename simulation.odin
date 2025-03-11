package main
import "core:math/linalg"
import "core:math/rand"
import t "core:time"


state_init :: proc(state: ^state) {
	sand: texture = texture_create("res/textures/sand.png")
	for i := 0; i < MAX_PIXELS; i += 1 {
		pixel: pixel
		pixel.size = 8.0
		pixel.x = rand.float32_range(-WINDOW_WIDTH, WINDOW_WIDTH)
		pixel.y = rand.float32_range(-WINDOW_HEIGHT, WINDOW_HEIGHT)
		pixel.type = .SAND
		pixel.color = {1.0, 1.0, 1.0}
		pixel.velocity = {
			rand.float32_range(-0.5, 0.5),
			rand.float32_range(-0.5, 0.5),
		}
		pixel.texture = sand
		state.px[i] = pixel
	}
}

simulation_update :: proc(delta_time: f32, state: ^state) {
	speed: f32 = 800.0
	half_w: f32 = state.px[0].size / 2
	for i := 0; i < MAX_PIXELS; i += 1 {
		state.px[i].x += state.px[i].velocity.x * speed * delta_time
		state.px[i].y += state.px[i].velocity.y * speed * delta_time

		// Check for collisions with other px
		for j := 0; j < MAX_PIXELS; j += 1 {
			if i == j {
				continue
			}
			if state.px[i].x - half_w < state.px[j].x + half_w &&
			   state.px[i].x + half_w > state.px[j].x - half_w &&
			   state.px[i].y - half_w < state.px[j].y + half_w &&
			   state.px[i].y + half_w > state.px[j].y - half_w {
				state.px[i].velocity = -state.px[i].velocity
				state.px[j].velocity = -state.px[j].velocity
			}
		}
	}
}
