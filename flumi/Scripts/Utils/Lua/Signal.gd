class_name LuaSignalUtils
extends RefCounted

# Signal API for Lua - provides custom signal functionality
# Usage: local mySignal = Signal.new(), mySignal:connect(callback), mySignal:fire(args...)

class LuaSignal:
	var connections: Array[Dictionary] = []
	var next_connection_id: int = 1
	var signal_table_ref: int = -1
	
	func connect_callback(callback_ref: int, vm: LuauVM) -> int:
		var connection_id = next_connection_id
		next_connection_id += 1
		
		var connection = {
			"id": connection_id,
			"callback_ref": callback_ref,
			"vm": vm
		}
		connections.append(connection)
		return connection_id
	
	func disconnect_callback(connection_id: int, vm: LuauVM) -> void:
		for i in range(connections.size() - 1, -1, -1):
			var connection = connections[i]
			if connection.id == connection_id:
				# Clean up the Lua reference from custom storage
				vm.lua_pushstring("SIGNAL_CALLBACKS")
				vm.lua_rawget(vm.LUA_REGISTRYINDEX)
				vm.lua_pushinteger(connection.callback_ref)
				vm.lua_pushnil()
				vm.lua_rawset(-3) # Set callbacks[callback_ref] = nil
				vm.lua_pop(1) # Pop callbacks table
				connections.remove_at(i)
				break
	
	func disconnect_all(vm: LuauVM) -> void:
		# Clean up all Lua references from custom storage
		vm.lua_pushstring("SIGNAL_CALLBACKS")
		vm.lua_rawget(vm.LUA_REGISTRYINDEX)
		for connection in connections:
			vm.lua_pushinteger(connection.callback_ref)
			vm.lua_pushnil()
			vm.lua_rawset(-3) # Set callbacks[callback_ref] = nil
		vm.lua_pop(1) # Pop callbacks table
		connections.clear()
	
	func fire_signal(args: Array) -> void:
		for connection in connections:
			var vm = connection.vm as LuauVM
			# Get the callback function from our custom storage
			vm.lua_pushstring("SIGNAL_CALLBACKS")
			vm.lua_rawget(vm.LUA_REGISTRYINDEX)
			vm.lua_pushinteger(connection.callback_ref)
			vm.lua_rawget(-2)
			if vm.lua_isfunction(-1):
				# Push the arguments directly (don't pass self)
				for arg in args:
					vm.lua_pushvariant(arg)
				
				# Call the function
				if vm.lua_pcall(args.size(), 0, 0) != vm.LUA_OK:
					vm.lua_pop(1)
				# Pop the callbacks table
				vm.lua_pop(1)
			else:
				vm.lua_pop(2) # Pop both the non-function and the callbacks table

static var signals_registry: Dictionary = {}
static var next_signal_id: int = 1
static var next_callback_ref: int = 1

# Signal.new() constructor
static func signal_new_handler(vm: LuauVM) -> int:
	var signal_id = next_signal_id
	next_signal_id += 1
	
	var lua_signal = LuaSignal.new()
	signals_registry[signal_id] = lua_signal
	
	# Create the signal table
	vm.lua_newtable()
	vm.lua_pushinteger(signal_id)
	vm.lua_setfield(-2, "_signal_id")
	
	# Store a reference to this signal table for : syntax
	vm.lua_pushvalue(-1) # Duplicate the signal table
	var signal_table_ref = vm.luaL_ref(vm.LUA_REGISTRYINDEX)
	lua_signal.signal_table_ref = signal_table_ref
	
	# Add methods
	vm.lua_pushcallable(signal_connect_handler, "signal:connect")
	vm.lua_setfield(-2, "connect")
	
	vm.lua_pushcallable(signal_fire_handler, "signal:fire")
	vm.lua_setfield(-2, "fire")
	
	vm.lua_pushcallable(signal_disconnect_handler, "signal:disconnect")
	vm.lua_setfield(-2, "disconnect")
	
	return 1

# signal:connect(callback) method
static func signal_connect_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.luaL_checktype(2, vm.LUA_TFUNCTION)
	
	# Get signal ID
	vm.lua_getfield(1, "_signal_id")
	var signal_id: int = vm.lua_tointeger(-1)
	vm.lua_pop(1)
	
	var lua_signal = signals_registry.get(signal_id) as LuaSignal
	if not lua_signal:
		vm.lua_pushnil()
		return 1
	
	# Store callback in a custom registry table instead of using luaL_ref
	# Get or create our custom callback storage table
	vm.lua_pushstring("SIGNAL_CALLBACKS")
	vm.lua_rawget(vm.LUA_REGISTRYINDEX)
	if vm.lua_isnil(-1):
		vm.lua_pop(1) # Pop nil
		vm.lua_newtable() # Create new table
		vm.lua_pushstring("SIGNAL_CALLBACKS")
		vm.lua_pushvalue(-2) # Duplicate the table
		vm.lua_rawset(vm.LUA_REGISTRYINDEX) # Set SIGNAL_CALLBACKS = table
	
	# Now store the callback function
	var callback_ref = next_callback_ref
	next_callback_ref += 1
	
	vm.lua_pushinteger(callback_ref) # Key
	vm.lua_pushvalue(2) # Value (the callback function)
	vm.lua_rawset(-3) # Set callbacks[callback_ref] = function
	
	vm.lua_pop(1) # Pop the callbacks table
	
	# Connect the callback
	var connection_id = lua_signal.connect_callback(callback_ref, vm)
	
	# Return connection object
	vm.lua_newtable()
	vm.lua_pushinteger(connection_id)
	vm.lua_setfield(-2, "_connection_id")
	vm.lua_pushinteger(signal_id)
	vm.lua_setfield(-2, "_signal_id")
	
	vm.lua_pushcallable(connection_disconnect_handler, "connection:disconnect")
	vm.lua_setfield(-2, "disconnect")
	
	return 1

# signal:fire(...) method
static func signal_fire_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	# Get signal ID
	vm.lua_getfield(1, "_signal_id")
	var signal_id: int = vm.lua_tointeger(-1)
	vm.lua_pop(1)
	
	var lua_signal = signals_registry.get(signal_id) as LuaSignal
	if not lua_signal:
		return 0
	
	# Collect arguments (everything after the signal table)
	var args: Array = []
	var arg_count = vm.lua_gettop() - 1 # Subtract 1 for the signal table itself
	for i in range(2, arg_count + 2): # Start from index 2 (after signal table)
		args.append(vm.lua_tovariant(i))
	
	# Fire the signal with the signal table reference
	lua_signal.fire_signal(args)
	
	return 0

# signal:disconnect() method - disconnects all connections
static func signal_disconnect_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	# Get signal ID
	vm.lua_getfield(1, "_signal_id")
	var signal_id: int = vm.lua_tointeger(-1)
	vm.lua_pop(1)
	
	var lua_signal = signals_registry.get(signal_id) as LuaSignal
	if lua_signal:
		lua_signal.disconnect_all(vm)
	
	return 0

# connection:disconnect() method - disconnects specific connection
static func connection_disconnect_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	# Get connection ID and signal ID
	vm.lua_getfield(1, "_connection_id")
	var connection_id: int = vm.lua_tointeger(-1)
	vm.lua_pop(1)
	
	vm.lua_getfield(1, "_signal_id")
	var signal_id: int = vm.lua_tointeger(-1)
	vm.lua_pop(1)
	
	var lua_signal = signals_registry.get(signal_id) as LuaSignal
	if lua_signal:
		lua_signal.disconnect_callback(connection_id, vm)
	
	return 0

static func setup_signal_api(vm: LuauVM) -> void:
	# Create Signal table
	vm.lua_newtable()
	
	# Add Signal.new constructor
	vm.lua_pushcallable(signal_new_handler, "Signal.new")
	vm.lua_setfield(-2, "new")
	
	# Set as global Signal
	vm.lua_setglobal("Signal")
