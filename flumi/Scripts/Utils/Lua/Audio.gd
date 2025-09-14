class_name LuaAudioUtils
extends RefCounted

static var last_user_event_time: int = 0
static var user_event_window_ms: int = 100

static func setup_audio_api(vm: LuauVM):
	vm.lua_newtable()
	vm.lua_pushcallable(_lua_audio_new_handler, "Audio.new")
	vm.lua_setfield(-2, "new")
	vm.lua_setglobal("Audio")

static func mark_user_event():
	last_user_event_time = Time.get_ticks_msec()

static func _check_if_likely_user_event(current_time: int) -> bool:
	var time_since_user_event = current_time - last_user_event_time
	return time_since_user_event < user_event_window_ms

static func _defer_audio_setup(audio_node: HTMLAudio):
	var main_scene = Engine.get_main_loop().current_scene
	main_scene.add_child(audio_node)
	audio_node.visible = false
	
	var element = audio_node.current_element
	var src = element.get_attribute("src")
	if not src.is_empty():
		audio_node.loop = element.has_attribute("loop")
		if element.has_attribute("muted"):
			audio_node.muted = true
		audio_node.load_audio_async(src)

static func _lua_audio_new_handler(vm: LuauVM) -> int:
	var url: String = vm.luaL_checkstring(1)
	
	var audio_scene = preload("res://Scenes/Tags/audio.tscn")
	var audio_node = audio_scene.instantiate() as HTMLAudio
	
	var dummy_element = HTMLParser.HTMLElement.new("audio")
	dummy_element.set_attribute("src", url)
	dummy_element.set_attribute("controls", "false")
	
	audio_node.current_element = dummy_element
	audio_node.current_parser = null
	audio_node.visible = false
	
	audio_node.set_meta("deferred_url", url)
	
	_defer_audio_setup.call_deferred(audio_node)
	
	vm.lua_newtable()
	
	vm.lua_pushobject(audio_node)
	vm.lua_setfield(-2, "_audio_node")
	
	vm.lua_pushcallable(_lua_audio_play_handler, "Audio.play")
	vm.lua_setfield(-2, "play")
	
	vm.lua_pushcallable(_lua_audio_pause_handler, "Audio.pause")
	vm.lua_setfield(-2, "pause")
	
	vm.lua_pushcallable(_lua_audio_stop_handler, "Audio.stop")
	vm.lua_setfield(-2, "stop")
	
	# Set up metatable for property access
	vm.lua_newtable()
	vm.lua_pushcallable(_lua_audio_index_handler, "Audio.__index")
	vm.lua_setfield(-2, "__index")
	vm.lua_pushcallable(_lua_audio_newindex_handler, "Audio.__newindex")
	vm.lua_setfield(-2, "__newindex")
	vm.lua_setmetatable(-2)
	
	return 1

static func _get_audio_node_from_table(vm: LuauVM) -> HTMLAudio:
	vm.lua_getfield(1, "_audio_node")
	var audio_node = vm.lua_toobject(-1) as HTMLAudio
	vm.lua_pop(1)
	return audio_node

static func _lua_audio_play_handler(vm: LuauVM) -> int:
	var audio_node = _get_audio_node_from_table(vm)
	if audio_node:
		var current_time = Time.get_ticks_msec()
		var is_likely_user_event = _check_if_likely_user_event(current_time)
		audio_node.call_deferred("_deferred_play_with_user_context", is_likely_user_event)
		vm.lua_pushboolean(true)
	else:
		vm.lua_pushboolean(false)
	return 1

static func _lua_audio_pause_handler(vm: LuauVM) -> int:
	var audio_node = _get_audio_node_from_table(vm)
	if audio_node:
		audio_node.call_deferred("pause")
	return 0

static func _lua_audio_stop_handler(vm: LuauVM) -> int:
	var audio_node = _get_audio_node_from_table(vm)
	if audio_node:
		audio_node.call_deferred("stop")
	return 0

# Property access handlers for programmatic audio
static func _lua_audio_index_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var key: String = vm.luaL_checkstring(2)
	
	var audio_node = _get_audio_node_from_table(vm)
	if not audio_node:
		vm.lua_pushnil()
		return 1
	
	match key:
		"volume":
			vm.lua_pushnumber(audio_node.volume)
			return 1
		"loop":
			vm.lua_pushboolean(audio_node.loop)
			return 1
		"currentTime":
			vm.lua_pushnumber(audio_node.get_current_time())
			return 1
		"duration":
			vm.lua_pushnumber(audio_node.get_duration())
			return 1
		"paused":
			vm.lua_pushboolean(not audio_node.is_playing)
			return 1
		"src":
			if audio_node.current_element:
				vm.lua_pushstring(audio_node.current_element.get_attribute("src"))
			else:
				vm.lua_pushstring("")
			return 1
		_:
			# Look up other methods/properties in the table itself
			vm.lua_rawget(1)
			return 1

static func _lua_audio_newindex_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	var key: String = vm.luaL_checkstring(2)
	var value = vm.lua_tovariant(3)
	
	var audio_node = _get_audio_node_from_table(vm)
	if not audio_node:
		return 0
	
	match key:
		"volume":
			audio_node.call_deferred("set", "volume", float(value))
			return 0
		"loop":
			audio_node.call_deferred("set", "loop", bool(value))
			return 0
		"currentTime":
			audio_node.call_deferred("set_current_time", float(value))
			return 0
		"src":
			var src_url = str(value)
			if audio_node.current_element:
				audio_node.current_element.set_attribute("src", src_url)
			audio_node.call_deferred("load_audio_async", src_url)
			return 0
		_:
			vm.lua_rawset(1)
			return 0

static func _dom_audio_play_handler(vm: LuauVM) -> int:
	var element_id: String = vm.luaL_checkstring(1)
	var lua_api = vm.get_meta("lua_api") as LuaAPI
	if not lua_api:
		return 0
	
	mark_user_event()
	var audio_node = _get_dom_audio_node(element_id, lua_api)
	if audio_node:
		audio_node.call_deferred("_deferred_play_with_user_context", true)
	return 0

static func _dom_audio_pause_handler(vm: LuauVM) -> int:
	var element_id: String = vm.luaL_checkstring(1)
	var lua_api = vm.get_meta("lua_api") as LuaAPI
	if not lua_api:
		return 0
	
	var audio_node = _get_dom_audio_node(element_id, lua_api)
	if audio_node:
		audio_node.call_deferred("pause")
	return 0

static func _get_dom_audio_node(element_id: String, lua_api) -> HTMLAudio:
	return lua_api.dom_parser.parse_result.dom_nodes.get(element_id, null) as HTMLAudio

static func handle_dom_audio_index(vm: LuauVM, element_id: String, key: String) -> int:
	var lua_api = vm.get_meta("lua_api") as LuaAPI
	var audio_node = _get_dom_audio_node(element_id, lua_api)
	if not audio_node:
		vm.lua_pushnil()
		return 1
	
	match key:
		"play":
			var play_code = "return function(self) _dom_audio_play('" + element_id + "') end"
			vm.load_string(play_code, "audio.play_closure")
			if vm.lua_pcall(0, 1, 0) == vm.LUA_OK:
				return 1
			else:
				vm.lua_pop(1)
				vm.lua_pushnil()
				return 1
		"pause":
			var pause_code = "return function(self) _dom_audio_pause('" + element_id + "') end"
			vm.load_string(pause_code, "audio.pause_closure")
			if vm.lua_pcall(0, 1, 0) == vm.LUA_OK:
				return 1
			else:
				vm.lua_pop(1)
				vm.lua_pushnil()
				return 1
		"volume":
			vm.lua_pushnumber(audio_node.volume)
			return 1
		"loop":
			vm.lua_pushboolean(audio_node.loop)
			return 1
		"currentTime":
			vm.lua_pushnumber(audio_node.get_current_time())
			return 1
		"duration":
			vm.lua_pushnumber(audio_node.get_duration())
			return 1
		"paused":
			vm.lua_pushboolean(not audio_node.is_playing)
			return 1
		"src":
			if audio_node.current_element:
				vm.lua_pushstring(audio_node.current_element.get_attribute("src"))
			else:
				vm.lua_pushstring("")
			return 1
	
	return 0

static func handle_dom_audio_newindex(vm: LuauVM, element_id: String, key: String, value: Variant) -> int:
	var lua_api = vm.get_meta("lua_api") as LuaAPI
	var audio_node = _get_dom_audio_node(element_id, lua_api)
	if not audio_node:
		return 0
	
	match key:
		"volume":
			audio_node.call_deferred("set", "volume", float(value))
		"loop":
			audio_node.call_deferred("set", "loop", bool(value))
		"currentTime":
			audio_node.call_deferred("set_current_time", float(value))
		"src":
			var src_url = str(value)
			if audio_node.current_element:
				audio_node.current_element.set_attribute("src", src_url)
			audio_node.call_deferred("load_audio_async", src_url)
	
	return 0
