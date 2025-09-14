class_name LuaURLUtils
extends RefCounted

static func url_encode_handler(vm: LuauVM) -> int:
	var input: String = vm.luaL_checkstring(1)
	var encoded = input.uri_encode()
	vm.lua_pushstring(encoded)
	return 1

static func url_decode_handler(vm: LuauVM) -> int:
	var input: String = vm.luaL_checkstring(1)
	var decoded = input.uri_decode()
	vm.lua_pushstring(decoded)
	return 1

static func setup_url_api(vm: LuauVM) -> void:
	vm.lua_pushcallable(url_encode_handler, "urlEncode")
	vm.lua_setglobal("urlEncode")
	
	vm.lua_pushcallable(url_decode_handler, "urlDecode")
	vm.lua_setglobal("urlDecode")
