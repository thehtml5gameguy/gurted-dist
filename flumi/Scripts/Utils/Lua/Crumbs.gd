class_name LuaCrumbsUtils
extends RefCounted

const CRUMBS_DIR_PATH = "user://crumbs/"

class Crumb:
	var name: String
	var value: String
	var created_at: float
	var lifespan: float = -1.0 # -1 = no expiry, otherwise lifespan in seconds
	
	func _init(n: String, v: String, lifetime: float = -1.0):
		name = n
		value = v
		created_at = Time.get_unix_time_from_system()
		lifespan = lifetime
	
	func is_expired() -> bool:
		if lifespan < 0:
			return false
		var current_time = Time.get_unix_time_from_system()
		return current_time > (created_at + lifespan)
	
	func get_expiry_time() -> float:
		if lifespan < 0:
			return -1.0
		return created_at + lifespan
	
	func to_dict() -> Dictionary:
		return {
			"name": name,
			"value": value,
			"created_at": created_at,
			"lifespan": lifespan
		}
	
	static func from_dict(data: Dictionary) -> Crumb:
		var crumb = Crumb.new(data.get("name", ""), data.get("value", ""))
		crumb.created_at = data.get("created_at", Time.get_unix_time_from_system())
		crumb.lifespan = data.get("lifespan", -1.0)
		return crumb

static func setup_crumbs_api(vm: LuauVM):
	# Ensure crumbs directory exists
	if not DirAccess.dir_exists_absolute(CRUMBS_DIR_PATH):
		DirAccess.make_dir_recursive_absolute(CRUMBS_DIR_PATH)
	
	vm.lua_newtable()
	
	vm.lua_pushcallable(_crumbs_set_handler, "gurt.crumbs.set")
	vm.lua_setfield(-2, "set")
	
	vm.lua_pushcallable(_crumbs_get_handler, "gurt.crumbs.get")
	vm.lua_setfield(-2, "get")
	
	vm.lua_pushcallable(_crumbs_delete_handler, "gurt.crumbs.delete")
	vm.lua_setfield(-2, "delete")
	
	vm.lua_pushcallable(_crumbs_get_all_handler, "gurt.crumbs.getAll")
	vm.lua_setfield(-2, "getAll")
	
	vm.lua_getglobal("gurt")
	if vm.lua_isnil(-1):
		vm.lua_pop(1)
		vm.lua_newtable()
		vm.lua_setglobal("gurt")
		vm.lua_getglobal("gurt")
	
	vm.lua_pushvalue(-2)
	vm.lua_setfield(-2, "crumbs")
	vm.lua_pop(2)

static func get_current_domain() -> String:
	var main_node = Engine.get_main_loop().current_scene
	if main_node and main_node.has_method("get_current_url"):
		var current_url = main_node.get_current_url()
		return sanitize_domain_for_filename(current_url)
	return "default"

static func sanitize_domain_for_filename(domain: String) -> String:
	# Remove protocol prefix
	if domain.begins_with("gurt://"):
		domain = domain.substr(7)
	elif domain.contains("://"):
		var parts = domain.split("://")
		if parts.size() > 1:
			domain = parts[1]
	
	# Extract only the domain part (remove path)
	if domain.contains("/"):
		domain = domain.split("/")[0]
	
	# Replace invalid filename characters (mainly colons for ports)
	domain = domain.replace(":", "_")
	domain = domain.replace("\\", "_")
	domain = domain.replace("*", "_")
	domain = domain.replace("?", "_")
	domain = domain.replace("\"", "_")
	domain = domain.replace("<", "_")
	domain = domain.replace(">", "_")
	domain = domain.replace("|", "_")
	
	# Ensure it's not empty
	if domain.is_empty():
		domain = "default"
	
	return domain

static func get_domain_file_path(domain: String) -> String:
	return CRUMBS_DIR_PATH + domain + ".json"

static func _crumbs_set_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "name")
	if vm.lua_isnil(-1):
		vm.luaL_error("crumb 'name' field is required")
		return 0
	var name: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	vm.lua_getfield(1, "value")
	if vm.lua_isnil(-1):
		vm.luaL_error("crumb 'value' field is required")
		return 0
	var value: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var lifetime: float = -1.0
	vm.lua_getfield(1, "lifetime")
	if not vm.lua_isnil(-1):
		lifetime = vm.lua_tonumber(-1)
	vm.lua_pop(1)
	
	var domain = get_current_domain()
	var crumb = Crumb.new(name, value, lifetime)
	save_crumb(domain, crumb)
	
	return 0

static func _crumbs_get_handler(vm: LuauVM) -> int:
	var name: String = vm.luaL_checkstring(1)
	var domain = get_current_domain()
	var crumb = load_crumb(domain, name)
	
	if crumb and not crumb.is_expired():
		vm.lua_pushstring(crumb.value)
	else:
		vm.lua_pushnil()
	
	return 1

static func _crumbs_delete_handler(vm: LuauVM) -> int:
	var name: String = vm.luaL_checkstring(1)
	var domain = get_current_domain()
	var existed = delete_crumb(domain, name)
	
	vm.lua_pushboolean(existed)
	return 1

static func _crumbs_get_all_handler(vm: LuauVM) -> int:
	var domain = get_current_domain()
	var all_crumbs = load_all_crumbs(domain)
	
	vm.lua_newtable()
	
	for crumb_name in all_crumbs:
		var crumb = all_crumbs[crumb_name]
		if not crumb.is_expired():
			vm.lua_newtable()
			vm.lua_pushstring(crumb.name)
			vm.lua_setfield(-2, "name")
			vm.lua_pushstring(crumb.value)
			vm.lua_setfield(-2, "value")
			
			# Include expiry time if it exists (but not created_at)
			var expiry_time = crumb.get_expiry_time()
			if expiry_time > 0:
				vm.lua_pushnumber(expiry_time)
				vm.lua_setfield(-2, "expiry")
			
			vm.lua_setfield(-2, crumb_name)
	
	return 1

static func load_all_crumbs(domain: String) -> Dictionary:
	var file_path = get_domain_file_path(domain)
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return {}
	
	var crumbs_data = json.data
	if not crumbs_data is Dictionary:
		return {}
	
	var crumbs = {}
	var changed = false
	
	for crumb_name in crumbs_data:
		var crumb_dict = crumbs_data[crumb_name]
		if crumb_dict is Dictionary:
			var crumb = Crumb.from_dict(crumb_dict)
			if crumb.is_expired():
				changed = true
			else:
				crumbs[crumb_name] = crumb
	
	# Save back if we removed expired crumbs
	if changed:
		save_all_crumbs(domain, crumbs)
	
	return crumbs

static func save_all_crumbs(domain: String, crumbs: Dictionary):
	var crumbs_data = {}
	for crumb_name in crumbs:
		var crumb = crumbs[crumb_name]
		crumbs_data[crumb_name] = crumb.to_dict()
	
	var file_path = get_domain_file_path(domain)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open crumbs file for writing: " + file_path)
		return
	
	var json_string = JSON.stringify(crumbs_data)
	file.store_string(json_string)
	file.close()

static func load_crumb(domain: String, name: String) -> Crumb:
	var all_crumbs = load_all_crumbs(domain)
	return all_crumbs.get(name, null)

static func save_crumb(domain: String, crumb: Crumb):
	var all_crumbs = load_all_crumbs(domain)
	all_crumbs[crumb.name] = crumb
	save_all_crumbs(domain, all_crumbs)

static func delete_crumb(domain: String, name: String) -> bool:
	var all_crumbs = load_all_crumbs(domain)
	var existed = all_crumbs.has(name)
	if existed:
		all_crumbs.erase(name)
		save_all_crumbs(domain, all_crumbs)
	return existed

static func clear_all_crumbs():
	if DirAccess.dir_exists_absolute(CRUMBS_DIR_PATH):
		var dir = DirAccess.open(CRUMBS_DIR_PATH)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".json"):
					dir.remove(file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
