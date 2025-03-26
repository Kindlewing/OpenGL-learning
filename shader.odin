package main

import "core:log"
import "core:os"
import gl "vendor:OpenGL"

shader_type :: enum {
	VERTEX,
	FRAGMENT,
}

shader :: struct {
	program, vertex_handle, fragment_handle: u32,
}

shader_create :: proc(vertex_file: string, fragment_file: string) -> shader {
	shader: shader
	shader.vertex_handle = shader_compile(vertex_file, gl.VERTEX_SHADER)
	shader.fragment_handle = shader_compile(fragment_file, gl.FRAGMENT_SHADER)

	shader.program = gl.CreateProgram()
	gl.AttachShader(shader.program, shader.vertex_handle)
	gl.AttachShader(shader.program, shader.fragment_handle)
	gl.LinkProgram(shader.program)
	link_status: i32
	gl.GetProgramiv(shader.program, gl.LINK_STATUS, &link_status)
	if link_status != 1 {
		info_log: [1024]u8
		gl.GetProgramInfoLog(shader.program, 1024, nil, raw_data(&info_log))
		log.panicf("Shader program linking failed: %s\n", info_log)
	}
	return shader
}

shader_compile :: proc(file: string, type: u32) -> u32 {
	handle: u32

	shader_src, read_success := os.read_entire_file_from_filename(file)
	if !read_success {
		log.fatalf("Could not read file %s\n", file)
		os.exit(-1)
	}
	defer delete_slice(shader_src)
	handle = gl.CreateShader(type)
	gl.ShaderSource(handle, 1, cast(^cstring)&shader_src, nil)
	when ODIN_DEBUG {log.debugf("About to compile shader: %s\n", file)}
	gl.CompileShader(handle)
	ok: i32
	info: [512]u8
	gl.GetShaderiv(handle, gl.COMPILE_STATUS, &ok)
	if ok == 0 {
		gl.GetShaderInfoLog(handle, 512, nil, raw_data(&info))
		log.errorf("Shader %s compilation failed:\n reason: %s\n", file, info)
		os.exit(-1)
	}
	when ODIN_DEBUG {log.debugf("Shader %s compilation successful\n", file)}
	return handle
}

shader_delete :: proc(shader: ^shader) {
	gl.DeleteShader(shader.vertex_handle)
	gl.DeleteShader(shader.fragment_handle)
	gl.DeleteProgram(shader.program)
}
