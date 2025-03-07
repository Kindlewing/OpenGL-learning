package main

import "base:runtime"
import "core:log"
import gl "vendor:OpenGL"

gl_debug_output :: proc "c" (
	source: u32,
	type: u32,
	id: u32,
	severity: u32,
	length: i32,
	message: cstring,
	userParam: rawptr,
) {
	ctx := cast(^runtime.Context)userParam
	context = ctx^
	// ignore non-significant error/warning codes
	if id == 131169 || id == 131185 || id == 131218 || id == 131204 {
		return
	}

	log.debugf("---------------\n")
	log.debugf("Debug message (%d): %s\n", id, message)

	switch source {
	case gl.DEBUG_SOURCE_API:
		log.debugf("Source: API\n")
	case gl.DEBUG_SOURCE_WINDOW_SYSTEM:
		log.debugf("Source: Window System\n")
	case gl.DEBUG_SOURCE_SHADER_COMPILER:
		log.debugf("Source: Shader Compiler\n")
	case gl.DEBUG_SOURCE_THIRD_PARTY:
		log.debugf("Source: Third Party\n")
	case gl.DEBUG_SOURCE_APPLICATION:
		log.debugf("Source: Application\n")
	case gl.DEBUG_SOURCE_OTHER:
		log.debugf("Source: Other\n")
	}

	switch type {
	case gl.DEBUG_TYPE_ERROR:
		log.debugf("Type: Error\n")
	case gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR:
		log.debugf("Type: Deprecated Behaviour\n")
	case gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR:
		log.debugf("Type: Undefined Behaviour\n")
	case gl.DEBUG_TYPE_PORTABILITY:
		log.debugf("Type: Portability\n")
	case gl.DEBUG_TYPE_PERFORMANCE:
		log.debugf("Type: Performance\n")
	case gl.DEBUG_TYPE_MARKER:
		log.debugf("Type: Marker\n")
	case gl.DEBUG_TYPE_PUSH_GROUP:
		log.debugf("Type: Push Group\n")
	case gl.DEBUG_TYPE_POP_GROUP:
		log.debugf("Type: Pop Group\n")
	case gl.DEBUG_TYPE_OTHER:
		log.debugf("Type: Other\n")
	}

	switch severity {
	case gl.DEBUG_SEVERITY_HIGH:
		log.debugf("Severity: high\n")
	case gl.DEBUG_SEVERITY_MEDIUM:
		log.debugf("Severity: medium\n")
	case gl.DEBUG_SEVERITY_LOW:
		log.debugf("Severity: low\n")
	case gl.DEBUG_SEVERITY_NOTIFICATION:
		log.debugf("Severity: notification\n")
	}

	log.debugf("\n")
}
