package main
import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import t "core:time"

pixel :: struct {
	pos:      linalg.Vector2f32,
	prev_pos: linalg.Vector2f32,
	radius:   f32,
	size:     f32,
	vel:      linalg.Vector2f32,
	accel:    linalg.Vector2f32,
	mass:     f32,
	color:    linalg.Vector3f32,
	texture:  texture,
}

state :: struct {
	px:      [MAX_PIXELS]pixel,
	bounds:  linalg.Vector2f32,
	gravity: f32,
}

state_init :: proc(st: ^state) {
	sand: texture = texture_create("res/textures/sand.png")
	st.bounds = {WINDOW_WIDTH, WINDOW_HEIGHT}
	st.gravity = -9.81
	for i := 0; i < MAX_PIXELS; i += 1 {
		pixel: pixel
		pixel.size = PIXEL_SIZE
		pixel.radius = pixel.size / 2
		pixel.mass = 20

		pixel.accel = {0.0, st.gravity}
		pixel.pos = {
			rand.float32_range(
				-st.bounds.x + pixel.radius,
				st.bounds.x - pixel.radius,
			),
			rand.float32_range(
				-st.bounds.y + pixel.radius,
				st.bounds.y - pixel.radius,
			),
		}
		pixel.prev_pos = pixel.pos
		pixel.color = {0.8, 0.3, 0.2}
		pixel.vel = {rand.float32_range(-10, 10), rand.float32_range(-10, 10)}
		pixel.texture = sand
		st.px[i] = pixel
	}
}


verlet :: proc(
	pos: ^linalg.Vector2f32,
	prev_pos: ^linalg.Vector2f32,
	accel: ^linalg.Vector2f32,
	dt: f32,
) {
	new_pos: linalg.Vector2f32 = 2 * pos^ - prev_pos^ + accel^ * (dt * dt)
	prev_pos^ = pos^
	pos^ = new_pos
}

simulation_update :: proc(delta_time: f32, st: ^state) {
	speed: f32 = 5.0
	radius: f32 = st.px[0].radius
	for i := 0; i < MAX_PIXELS; i += 1 {
		px: ^pixel = &st.px[i]
		// movement
		px.pos += speed * px.vel * px.accel * delta_time

		// collision with border
		if px.pos.x - radius < -st.bounds.x {
			px.vel.x *= -1
		}
		if px.pos.x + radius > st.bounds.x {
			px.vel.x *= -1
		}
		if px.pos.y - radius < -st.bounds.y {
			px.vel.y *= -1
		}
		if px.pos.y + radius > st.bounds.y {
			px.vel.y *= -1
		}

		// collision of two pixels
		for j := 0; j < MAX_PIXELS; j += 1 {
			if i == j {
				continue
			}
			px_2: ^pixel = &st.px[j]
			if linalg.distance(px.pos, px_2.pos) <= px.radius + px_2.radius {
				normal: linalg.Vector2f32 = px_2.pos - px.pos
				u_normal: linalg.Vector2f32 = normal / linalg.length(normal)
				u_tan: linalg.Vector2f32 = {-u_normal.y, u_normal.x}
				v1_normal: f32 = linalg.vector_dot(u_normal, px.vel)
				v1_tan: f32 = linalg.vector_dot(u_tan, px.vel)
				v2_normal: f32 = linalg.vector_dot(u_normal, px_2.vel)
				v2_tan: f32 = linalg.vector_dot(u_tan, px_2.vel)

				new_normal_v1 :=
					(v1_normal * (px.mass - px_2.mass) +
						2 * px_2.mass * v2_normal) /
					(px.mass + px_2.mass)
				new_normal_v2 :=
					(v2_normal * (px_2.mass - px.mass) +
						2 * px.mass * v1_normal) /
					(px.mass + px_2.mass)

				vec1_normal_new: linalg.Vector2f32 = new_normal_v1 * u_normal
				vec2_normal_new: linalg.Vector2f32 = new_normal_v2 * u_normal
				vec1_tan_new: linalg.Vector2f32 = v1_tan * u_tan
				vec2_tan_new: linalg.Vector2f32 = v2_tan * u_tan
				px.vel = vec1_normal_new + vec1_tan_new
				px_2.vel = vec2_normal_new + vec2_tan_new

				overlap: f32 =
					(px.radius + px_2.radius) -
					linalg.distance(px.pos, px_2.pos)
				correction: linalg.Vector2f32 = (overlap / 2) * u_normal
				px.pos -= correction
				px_2.pos += correction
			}
		}
	}
}
