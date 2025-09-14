class_name LuaPrintUtils
extends RefCounted

static func lua_print(vm: LuauVM) -> int:
	var message_parts: Array[String] = []
	var num_args: int = vm.lua_gettop()
	
	for i in range(1, num_args + 1):
		var value_str = lua_value_to_string(vm, i)
		message_parts.append(value_str)
	
	var final_message = "\t".join(message_parts)
	Trace.trace_log(final_message)
	return 0

static func lua_value_to_string(vm: LuauVM, index: int) -> String:
	var lua_type = vm.lua_type(index)
	
	match lua_type:
		vm.LUA_TNIL:
			return "nil"
		vm.LUA_TBOOLEAN:
			return "true" if vm.lua_toboolean(index) else "false"
		vm.LUA_TNUMBER:
			return str(vm.lua_tonumber(index))
		vm.LUA_TSTRING:
			return vm.lua_tostring(index)
		vm.LUA_TTABLE:
			return table_to_string(vm, index)
		vm.LUA_TFUNCTION:
			return "[function]"
		vm.LUA_TUSERDATA:
			return "[userdata]"
		vm.LUA_TVECTOR:
			var vec = vm.lua_tovector(index)
			return "vector(" + str(vec.x) + ", " + str(vec.y) + ", " + str(vec.z) + ", " + str(vec.w) + ")"
		_:
			return "[" + vm.lua_typename(lua_type) + "]"

static func table_to_string(vm: LuauVM, index: int, max_depth: int = 3, current_depth: int = 0) -> String:
	if current_depth >= max_depth:
		return "{...}"
	
	var result = "{"
	var first = true
	var count = 0
	var max_items = 10
	
	# Convert negative index to positive
	if index < 0:
		index = vm.lua_gettop() + index + 1
	
	# Iterate through table
	vm.lua_pushnil()  # First key
	while vm.lua_next(index):
		if count >= max_items:
			# We need to pop the value and key before breaking
			vm.lua_pop(2)  # Remove value and key
			break
			
		if not first:
			result += ", "
		first = false
		
		# Get key
		var key_str = lua_value_to_string(vm, -2)
		# Get value  
		var value_str = ""
		if vm.lua_type(-1) == vm.LUA_TTABLE:
			value_str = table_to_string(vm, -1, max_depth, current_depth + 1)
		else:
			value_str = lua_value_to_string(vm, -1)
		
		# Check if key is a valid identifier (for shorthand)
		if key_str.is_valid_identifier():
			result += key_str + ": " + value_str
		else:
			result += "[" + key_str + "]: " + value_str
		
		vm.lua_pop(1)  # Remove value, keep key for next iteration
		count += 1
	
	if count >= max_items:
		result += ", ..."
	
	result += "}"
	return result
