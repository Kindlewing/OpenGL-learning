package main
import "core:math/linalg"
import "core:math/rand"
import t "core:time"

pixel :: struct {
	x, y:    f32,
	size:    f32,
	vel:     linalg.Vector2f32,
	accel:   linalg.Vector2f32,
	mass:    f32,
	color:   linalg.Vector3f32,
	type:    pixel_type,
	texture: texture,
}

state :: struct {
	px:      [MAX_PIXELS]pixel,
	bounds:  linalg.Vector2f32,
	gravity: f32,
}

pixel_type :: enum {
	SAND,
}

state_init :: proc(state: ^state) {
	sand: texture = texture_create("res/textures/sand.png")
	state.bounds = {WINDOW_WIDTH, WINDOW_HEIGHT}
	for i := 0; i < MAX_PIXELS; i += 1 {
		pixel: pixel
		pixel.size = 30.0
		pixel.mass = 0.0
		pixel.accel = {0.0, -5.0}
		pixel.x = rand.float32_range(-state.bounds.x, state.bounds.x)
		pixel.y = rand.float32_range(-state.bounds.y, state.bounds.y)
		pixel.type = .SAND
		pixel.color = {1.0, 1.0, 1.0}
		pixel.vel = {
			rand.float32_range(-0.5, 0.5),
			rand.float32_range(-0.5, 0.5),
		}
		pixel.texture = sand
		state.px[i] = pixel
	}
}

simulation_update :: proc(delta_time: f32, state: ^state) {
	speed: f32 = 600.0
	half_w: f32 = state.px[0].size / 2
	for i := 0; i < MAX_PIXELS; i += 1 {
		// movement
		state.px[i].x += state.px[i].vel.x * speed * delta_time
		state.px[i].y += state.px[i].vel.y * speed * delta_time

		// collision
		if state.px[i].x < -state.bounds.x || state.px[i].x > state.bounds.x {
			state.px[i].vel.x = -state.px[i].vel.x
		}

		if state.px[i].y < -state.bounds.y || state.px[i].y > state.bounds.y {
			state.px[i].vel.y = -state.px[i].vel.y
		}

	}
}
