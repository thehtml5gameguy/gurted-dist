class_name LuaRegexUtils
extends RefCounted

static func regex_new_handler(vm: LuauVM) -> int:
	var pattern: String = vm.luaL_checkstring(1)
	var regex = RegEx.new()
	var result = regex.compile(pattern)
	
	if result != OK:
		vm.luaL_error("Invalid regex pattern: " + pattern)
		return 0
	
	vm.lua_newtable()
	vm.lua_pushobject(regex)
	vm.lua_setfield(-2, "_regex")
	
	vm.lua_pushcallable(regex_match_handler, "regex:match")
	vm.lua_setfield(-2, "match")
	
	vm.lua_pushcallable(regex_test_handler, "regex:test")
	vm.lua_setfield(-2, "test")
	
	return 1

static func regex_match_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var subject: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_regex")
	var regex: RegEx = vm.lua_toobject(-1) as RegEx
	vm.lua_pop(1)
	
	if not regex:
		vm.luaL_error("Invalid regex object")
		return 0
	
	var result = regex.search(subject)
	if not result:
		vm.lua_pushnil()
		return 1
	
	vm.lua_newtable()
	
	vm.lua_pushstring(result.get_string())
	vm.lua_rawseti(-2, 1)
	
	for i in range(1, result.get_group_count()):
		var group = result.get_string(i)
		vm.lua_pushstring(group)
		vm.lua_rawseti(-2, i + 1)
	
	return 1

static func regex_test_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var subject: String = vm.luaL_checkstring(2)
	
	vm.lua_getfield(1, "_regex")
	var regex: RegEx = vm.lua_toobject(-1) as RegEx
	vm.lua_pop(1)
	
	if not regex:
		vm.luaL_error("Invalid regex object")
		return 0
	
	var result = regex.search(subject)
	vm.lua_pushboolean(result != null)
	return 1

static func string_replace_handler(vm: LuauVM) -> int:
	var subject: String = vm.luaL_checkstring(1)
	
	if vm.lua_istable(2):
		vm.lua_getfield(2, "_regex")
		var regex: RegEx = vm.lua_toobject(-1) as RegEx
		vm.lua_pop(1)
		
		if not regex:
			vm.luaL_error("Invalid regex object")
			return 0
		
		var replacement: String = vm.luaL_checkstring(3)
		var result = regex.sub(subject, replacement, false)
		vm.lua_pushstring(result)
	else:
		var search: String = vm.luaL_checkstring(2)
		var replacement: String = vm.luaL_checkstring(3)
		
		var pos = subject.find(search)
		if pos >= 0:
			var result = subject.substr(0, pos) + replacement + subject.substr(pos + search.length())
			vm.lua_pushstring(result)
		else:
			vm.lua_pushstring(subject)
	
	return 1

static func string_replace_all_handler(vm: LuauVM) -> int:
	var subject: String = vm.luaL_checkstring(1)
	
	if vm.lua_istable(2):
		vm.lua_getfield(2, "_regex")
		var regex: RegEx = vm.lua_toobject(-1) as RegEx
		vm.lua_pop(1)
		
		if not regex:
			vm.luaL_error("Invalid regex object")
			return 0
		
		var replacement: String = vm.luaL_checkstring(3)
		var result = regex.sub(subject, replacement, true)
		vm.lua_pushstring(result)
	else:
		var search: String = vm.luaL_checkstring(2)
		var replacement: String = vm.luaL_checkstring(3)
		var result = subject.replace(search, replacement)
		vm.lua_pushstring(result)
	
	return 1

static func string_trim_handler(vm: LuauVM) -> int:
	var subject: String = vm.luaL_checkstring(1)
	var trimmed = subject.strip_edges()
	vm.lua_pushstring(trimmed)
	return 1

static func setup_regex_api(vm: LuauVM) -> void:
	vm.lua_newtable()
	
	vm.lua_pushcallable(regex_new_handler, "Regex.new")
	vm.lua_setfield(-2, "new")
	
	vm.lua_setglobal("Regex")
	
	vm.lua_getglobal("string")
	if vm.lua_isnil(-1):
		vm.lua_pop(1)
		vm.lua_newtable()
		vm.lua_setglobal("string")
		vm.lua_getglobal("string")
	
	vm.lua_pushcallable(string_replace_handler, "string.replace")
	vm.lua_setfield(-2, "replace")
	
	vm.lua_pushcallable(string_replace_all_handler, "string.replaceAll")
	vm.lua_setfield(-2, "replaceAll")
	
	vm.lua_pushcallable(string_trim_handler, "string.trim")
	vm.lua_setfield(-2, "trim")
	
	vm.lua_pop(1)
