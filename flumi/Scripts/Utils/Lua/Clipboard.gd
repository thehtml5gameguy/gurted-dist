class_name LuaClipboardUtils
extends RefCounted

static func clipboard_write_handler(vm: LuauVM) -> int:
	var text: String = vm.luaL_checkstring(1)
	
	DisplayServer.clipboard_set(text)
	
	return 0

static func setup_clipboard_api(vm: LuauVM) -> void:
	vm.lua_newtable()
	
	vm.lua_pushcallable(clipboard_write_handler, "Clipboard.write")
	vm.lua_setfield(-2, "write")
	
	vm.lua_setglobal("Clipboard")
