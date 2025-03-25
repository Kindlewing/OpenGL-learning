package main
import "core:math/linalg"
import "core:math/rand"
import t "core:time"


pixel :: struct {
	pos:     linalg.Vector2f32,
	radius:  f32,
	size:    f32,
	vel:     linalg.Vector2f32,
	accel:   linalg.Vector2f32,
	mass:    f32,
	color:   linalg.Vector3f32,
	texture: texture,
}

state :: struct {
	px:      [MAX_PIXELS]pixel,
	bounds:  linalg.Vector2f32,
	gravity: f32,
}

state_init :: proc(state: ^state) {
	sand: texture = texture_create("res/textures/sand.png")
	state.bounds = {WINDOW_WIDTH, WINDOW_HEIGHT}
	for i := 0; i < MAX_PIXELS; i += 1 {
		pixel: pixel
		pixel.size = PIXEL_SIZE
		pixel.radius = pixel.size / 2
		pixel.mass = 10

		pixel.accel = {0.0, -5.0}
		pixel.pos = {
			rand.float32_range(
				-state.bounds.x + pixel.radius,
				state.bounds.x - pixel.radius,
			),
			rand.float32_range(
				-state.bounds.y + pixel.radius,
				state.bounds.y - pixel.radius,
			),
		}
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
	radius: f32 = state.px[0].radius
	for i := 0; i < MAX_PIXELS; i += 1 {
		// movement
		state.px[i].pos += state.px[i].vel * speed * delta_time


		// collision with border
		if state.px[i].pos.x - radius < -state.bounds.x {
			state.px[i].vel.x *= -1
		}
		if state.px[i].pos.x + radius > state.bounds.x {
			state.px[i].vel.x *= -1
		}
		if state.px[i].pos.y - radius < -state.bounds.y {
			state.px[i].vel.y *= -1
		}
		if state.px[i].pos.y + radius > state.bounds.y {
			state.px[i].vel.y *= -1
		}

		// collision of two pixels
		for j := 0; j < MAX_PIXELS; j += 1 {
			if i == j {
				continue
			}
			p1, p2: ^pixel = &state.px[i], &state.px[j]
			if linalg.distance(p1.pos, p2.pos) <= p1.radius + p2.radius {
				normal: linalg.Vector2f32 = p2.pos - p1.pos
				u_normal: linalg.Vector2f32 = normal / linalg.length(normal)
				u_tan: linalg.Vector2f32 = {-u_normal.y, u_normal.x}
				v1_normal: f32 = linalg.vector_dot(u_normal, p1.vel)
				v1_tan: f32 = linalg.vector_dot(u_tan, p1.vel)
				v2_normal: f32 = linalg.vector_dot(u_normal, p2.vel)
				v2_tan: f32 = linalg.vector_dot(u_tan, p2.vel)

				new_normal_v1 :=
					(v1_normal * (p1.mass - p2.mass) +
						2 * p2.mass * v2_normal) /
					(p1.mass + p2.mass)
				new_normal_v2 :=
					(v2_normal * (p2.mass - p1.mass) +
						2 * p1.mass * v1_normal) /
					(p1.mass + p2.mass)

				vec1_normal_new: linalg.Vector2f32 = new_normal_v1 * u_normal
				vec2_normal_new: linalg.Vector2f32 = new_normal_v2 * u_normal
				vec1_tan_new: linalg.Vector2f32 = v1_tan * u_tan
				vec2_tan_new: linalg.Vector2f32 = v2_tan * u_tan
				p1.vel = vec1_normal_new + vec1_tan_new
				p2.vel = vec2_normal_new + vec2_tan_new

				overlap: f32 =
					(p1.radius + p2.radius) - linalg.distance(p1.pos, p2.pos)
				correction: linalg.Vector2f32 = (overlap / 2) * u_normal
				p1.pos -= correction
				p2.pos += correction
			}
		}
	}
}
