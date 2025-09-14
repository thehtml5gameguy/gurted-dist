class_name LuaTimeoutManager
extends RefCounted

var active_timeouts: Dictionary = {}
var next_timeout_id: int = 1
var threaded_vm: ThreadedLuaVM = null

class TimeoutInfo:
	var id: int
	var callback_ref: int
	var vm: LuauVM  
	var timer: Timer
	var timeout_manager: LuaTimeoutManager
	var is_interval: bool = false
	var delay_ms: int = 0
	
	func _init(timeout_id: int, cb_ref: int, lua_vm: LuauVM, manager: LuaTimeoutManager, interval: bool = false, delay: int = 0):
		id = timeout_id
		callback_ref = cb_ref
		vm = lua_vm
		timeout_manager = manager
		is_interval = interval
		delay_ms = delay

func set_timeout_handler(vm: LuauVM, parent_node: Node) -> int:
	vm.luaL_checktype(1, vm.LUA_TFUNCTION)
	var delay_ms: int = vm.luaL_checkint(2)
	
	var timeout_id = next_timeout_id
	next_timeout_id += 1
	
	# Store callback in isolated registry table
	vm.lua_pushstring("GURT_TIMEOUTS")
	vm.lua_rawget(vm.LUA_REGISTRYINDEX)
	if vm.lua_isnil(-1):
		vm.lua_pop(1)
		vm.lua_newtable()
		vm.lua_pushstring("GURT_TIMEOUTS")
		vm.lua_pushvalue(-2)
		vm.lua_rawset(vm.LUA_REGISTRYINDEX)
	
	vm.lua_pushinteger(timeout_id)
	vm.lua_pushvalue(1)
	vm.lua_rawset(-3)
	vm.lua_pop(1)
	
	# Create timeout info
	var timeout_info = TimeoutInfo.new(timeout_id, timeout_id, vm, self)
	
	# Create and configure timer
	var timer = Timer.new()
	timer.wait_time = delay_ms / 1000.0
	timer.one_shot = true
	timer.timeout.connect(_on_timeout_triggered.bind(timeout_info))
	
	timeout_info.timer = timer
	active_timeouts[timeout_id] = timeout_info
	
	# Add timer to scene tree
	parent_node.add_child(timer)
	timer.start()
	
	vm.lua_pushinteger(timeout_id)
	return 1

func set_interval_handler(vm: LuauVM, parent_node: Node) -> int:
	vm.luaL_checktype(1, vm.LUA_TFUNCTION)
	var delay_ms: int = vm.luaL_checkint(2)
	
	var timeout_id = next_timeout_id
	next_timeout_id += 1
	
	# Store callback in isolated registry table
	vm.lua_pushstring("GURT_TIMEOUTS")
	vm.lua_rawget(vm.LUA_REGISTRYINDEX)
	if vm.lua_isnil(-1):
		vm.lua_pop(1)
		vm.lua_newtable()
		vm.lua_pushstring("GURT_TIMEOUTS")
		vm.lua_pushvalue(-2)
		vm.lua_rawset(vm.LUA_REGISTRYINDEX)
	
	vm.lua_pushinteger(timeout_id)
	vm.lua_pushvalue(1)
	vm.lua_rawset(-3)
	vm.lua_pop(1)
	
	# Create interval info
	var timeout_info = TimeoutInfo.new(timeout_id, timeout_id, vm, self, true, delay_ms)
	
	# Create and configure timer for intervals
	var timer = Timer.new()
	timer.wait_time = delay_ms / 1000.0
	timer.one_shot = false  # This is the key difference - repeating timer
	timer.timeout.connect(_on_timeout_triggered.bind(timeout_info))
	
	timeout_info.timer = timer
	active_timeouts[timeout_id] = timeout_info
	
	# Add timer to scene tree
	parent_node.add_child(timer)
	timer.start()
	
	vm.lua_pushinteger(timeout_id)
	return 1

func set_threaded_timeout_handler(vm: LuauVM, parent_node: Node, threaded_vm_ref: ThreadedLuaVM) -> int:
	threaded_vm = threaded_vm_ref
	return set_timeout_handler(vm, parent_node)

func set_threaded_interval_handler(vm: LuauVM, parent_node: Node, threaded_vm_ref: ThreadedLuaVM) -> int:
	threaded_vm = threaded_vm_ref
	return set_interval_handler(vm, parent_node)

func _create_timer_on_main_thread(timeout_info: TimeoutInfo, delay_ms: int, parent_node: Node):
	var timer = Timer.new()
	timer.wait_time = delay_ms / 1000.0
	timer.one_shot = true
	timer.timeout.connect(_on_timeout_triggered.bind(timeout_info))
	
	timeout_info.timer = timer
	parent_node.add_child(timer)
	timer.start()

func clear_timeout_handler(vm: LuauVM) -> int:
	var timeout_id: int = vm.luaL_checkint(1)
	
	# If we have a threaded VM, defer the cleanup to main thread
	if threaded_vm:
		call_deferred("_cleanup_timeout_on_main_thread", timeout_id)
	else:
		_cleanup_timeout_immediately(timeout_id)
	
	return 0

func _cleanup_timeout_on_main_thread(timeout_id: int):
	# This runs on the main thread - safe to access timers
	_cleanup_timeout_immediately(timeout_id)

func _cleanup_timeout_immediately(timeout_id: int):
	var timeout_info = active_timeouts.get(timeout_id, null)
	if timeout_info:
		# Stop and remove timer
		if timeout_info.timer:
			timeout_info.timer.stop()
			timeout_info.timer.queue_free()
		
		# Remove from active timeouts
		active_timeouts.erase(timeout_id)

func clear_interval_handler(vm: LuauVM) -> int:
	return clear_timeout_handler(vm)

func _on_timeout_triggered(timeout_info: TimeoutInfo) -> void:
	if not active_timeouts.has(timeout_info.id):
		return
	
	if threaded_vm:
		_execute_threaded_timeout_callback(timeout_info.id)
	
	# For intervals, don't clean up - let them keep running
	# For timeouts, clean up after execution
	if not timeout_info.is_interval:
		timeout_info.timer.queue_free()
		active_timeouts.erase(timeout_info.id)

func cleanup_all_timeouts():
	# Clean up all active timeouts
	for timeout_id in active_timeouts:
		var timeout_info = active_timeouts[timeout_id]
		if timeout_info.timer:
			timeout_info.timer.stop()
			timeout_info.timer.queue_free()

		# Release Lua callback reference
		if timeout_info.vm and timeout_info.callback_ref:
			timeout_info.vm.lua_pushstring("GURT_TIMEOUTS")
			timeout_info.vm.lua_rawget(timeout_info.vm.LUA_REGISTRYINDEX)
			if not timeout_info.vm.lua_isnil(-1):
				timeout_info.vm.lua_pushinteger(timeout_info.callback_ref)
				timeout_info.vm.lua_pushnil()
				timeout_info.vm.lua_rawset(-3)
			timeout_info.vm.lua_pop(1)
	active_timeouts.clear()

func _execute_threaded_timeout_callback(timeout_id: int) -> void:
	if threaded_vm and threaded_vm.lua_thread and threaded_vm.lua_thread.is_alive():
		threaded_vm.execute_timeout_callback_async(timeout_id)
	else:
		active_timeouts.erase(timeout_id)
