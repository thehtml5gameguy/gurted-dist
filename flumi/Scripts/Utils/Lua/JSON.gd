class_name LuaJSONUtils
extends RefCounted

static func setup_json_api(vm: LuauVM):
	vm.lua_newtable()
	
	vm.lua_pushcallable(_lua_json_parse_handler, "JSON.parse")
	vm.lua_setfield(-2, "parse")
	
	vm.lua_pushcallable(_lua_json_stringify_handler, "JSON.stringify")
	vm.lua_setfield(-2, "stringify")
	
	vm.lua_setglobal("JSON")

static func _lua_json_parse_handler(vm: LuauVM) -> int:
	var json_string: String = vm.luaL_checkstring(1)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		vm.lua_pushvariant(json.data)
		return 1
	else:
		# Return nil and error message
		vm.lua_pushnil()
		vm.lua_pushstring("JSON parse error: " + json.get_error_message())
		return 2

static func _lua_json_stringify_handler(vm: LuauVM) -> int:
	var value = vm.lua_tovariant(1)
	
	var json_string = JSON.stringify(value)
	
	vm.lua_pushstring(json_string)
	return 1
