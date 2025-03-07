package main

import "core:log"
import "core:os"
import gl "vendor:OpenGL"

shader_type :: enum {
	VERTEX,
	FRAGMENT,
}

compile_shader :: proc(filepath: string, type: shader_type) -> u32 {
	ret: u32 = 0
	switch type {
	case .VERTEX:
		ret = gl.CreateShader(gl.VERTEX_SHADER)
		vertex_shader_src, ok := os.read_entire_file_from_filename(filepath)
		if !ok {
			log.fatalf("Err reading file\n")
		}
		gl.ShaderSource(ret, 1, cast(^cstring)&vertex_shader_src, nil)
		log.debugf("About to compile vertex shader defined in: %s\n", filepath)
		gl.CompileShader(ret)
		compile_ok: i32
		info: [1024]u8
		gl.GetShaderiv(ret, gl.COMPILE_STATUS, &compile_ok)
		if compile_ok == 0 {
			gl.GetShaderInfoLog(ret, 1024, nil, raw_data(&info))
			log.errorf(
				"ERROR::SHADER::VERTEX::COMPILATION_FAILED\n %s\n",
				info,
			)
		}
		log.debugf("Compilation of vertex shader successful.\n")
	case .FRAGMENT:
		ret = gl.CreateShader(gl.FRAGMENT_SHADER)
		frag_shader_src, frag_ok := os.read_entire_file_from_filename(filepath)
		if !frag_ok {
			log.fatalf("Err reading file\n")
		}
		gl.ShaderSource(ret, 1, cast(^cstring)&frag_shader_src, nil)
		log.debugf(
			"About to compile fragment shader defined in: %s\n",
			filepath,
		)
		gl.CompileShader(ret)
		ok: i32
		info: [1024]u8
		gl.GetShaderiv(ret, gl.COMPILE_STATUS, &ok)
		if ok == 0 {
			gl.GetShaderInfoLog(ret, 1024, nil, raw_data(&info))
			log.errorf(
				"ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n %s\n",
				info,
			)
		}
		log.debugf("Compilation of fragment shader successful.\n")
	}
	return ret
}
