class_name LuaDownloadUtils
extends RefCounted

static var last_user_event_time: int = 0
static var user_event_window_ms: int = 100
static var next_download_id: int = 1

static func setup_download_api(vm: LuauVM):
	vm.lua_pushcallable(_lua_download_handler, "gurt.download")
	vm.lua_getglobal("gurt")
	if vm.lua_isnil(-1):
		vm.lua_pop(1)
		vm.lua_newtable()
		vm.lua_setglobal("gurt")
		vm.lua_getglobal("gurt")
	
	vm.lua_pushvalue(-2)
	vm.lua_setfield(-2, "download")
	vm.lua_pop(2)

static func mark_user_event():
	last_user_event_time = Time.get_ticks_msec()

static func _check_if_likely_user_event(current_time: int) -> bool:
	var time_since_user_event = current_time - last_user_event_time
	return time_since_user_event < user_event_window_ms

static func _lua_download_handler(vm: LuauVM) -> int:
	var url: String = vm.luaL_checkstring(1)
	var filename: String = ""
	
	if vm.lua_gettop() >= 2 and not vm.lua_isnil(2):
		filename = vm.luaL_checkstring(2)
	else:
		filename = url.get_file()
		if filename.is_empty():
			filename = "download"
	
	var current_time = Time.get_ticks_msec()
	var is_likely_user_event = _check_if_likely_user_event(current_time)
	
	if not is_likely_user_event:
		vm.luaL_error("Download can only be called from within a user interaction (like a click event)")
		return 0
	
	var download_id = "download_" + str(next_download_id)
	next_download_id += 1
	
	var download_data = {
		"id": download_id,
		"url": url,
		"filename": filename,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var lua_api = vm.get_meta("lua_api") as LuaAPI
	if lua_api:
		var operation = {
			"type": "request_download",
			"download_data": download_data
		}
		lua_api.call_deferred("_handle_dom_operation", operation)
	
	vm.lua_pushstring(download_id)
	return 1
