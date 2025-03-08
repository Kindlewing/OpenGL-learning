package main

import "core:log"
import "core:os"
import gl "vendor:OpenGL"
import "vendor:stb/image"

texture :: struct {
	id: u32,
}

texture_create :: proc(filename: cstring) -> texture {
	texture: texture
	gl.GenTextures(1, &texture.id)
	gl.BindTexture(gl.TEXTURE_2D, texture.id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	width, height, nr_chan: i32
	image.set_flip_vertically_on_load(1)
	data := image.load(filename, &width, &height, &nr_chan, 0)
	if data == nil {
		log.fatalf(
			"Failed to load texture: %s\n reason: %s\n",
			filename,
			image.failure_reason(),
		)
		os.exit(-1)
	}
	format: i32
	if nr_chan == 4 {
		format = gl.RGBA
	} else {
		format = gl.RGB
	}
	gl.TexImage2D(
		gl.TEXTURE_2D,
		0,
		format,
		width,
		height,
		0,
		cast(u32)format,
		gl.UNSIGNED_BYTE,
		data,
	)
	gl.GenerateMipmap(gl.TEXTURE_2D)
	image.image_free(data)
	return texture
}

texture_destroy :: proc(texture: ^texture) {
	gl.BindTexture(texture.id, 0)
}
