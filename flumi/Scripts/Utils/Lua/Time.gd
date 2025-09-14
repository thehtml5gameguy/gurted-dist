class_name LuaTimeUtils
extends RefCounted

static func time_now_handler(vm: LuauVM) -> int:
	var current_time = Time.get_unix_time_from_system()
	vm.lua_pushnumber(current_time)
	return 1

static func time_format_handler(vm: LuauVM) -> int:
	var format_string: String = "%H:%M:%S"
	var datetime: Dictionary

	if vm.lua_gettop() >= 1 and vm.lua_isnumber(1):
		var timestamp: float = vm.lua_tonumber(1)
		
		var local_now_dict = Time.get_datetime_dict_from_system(false)
		var utc_now_dict = Time.get_datetime_dict_from_system(true)
		var offset_seconds = Time.get_unix_time_from_datetime_dict(local_now_dict) - Time.get_unix_time_from_datetime_dict(utc_now_dict)
		
		datetime = Time.get_datetime_dict_from_unix_time(int(timestamp) + offset_seconds)
	else:
		datetime = Time.get_datetime_dict_from_system(false)
	
	if vm.lua_gettop() >= 2 and vm.lua_isstring(2):
		format_string = vm.lua_tostring(2)
	
	var formatted_time = format_datetime(datetime, format_string)
	
	vm.lua_pushstring(formatted_time)
	return 1

static func time_date_handler(vm: LuauVM) -> int:
	var datetime: Dictionary
	
	if vm.lua_gettop() >= 1 and vm.lua_isnumber(1):
		var timestamp = vm.lua_tonumber(1)

		var local_now_dict = Time.get_datetime_dict_from_system(false)
		var utc_now_dict = Time.get_datetime_dict_from_system(true)
		var offset_seconds = Time.get_unix_time_from_datetime_dict(local_now_dict) - Time.get_unix_time_from_datetime_dict(utc_now_dict)
		
		datetime = Time.get_datetime_dict_from_unix_time(int(timestamp) + offset_seconds)
	else:
		datetime = Time.get_datetime_dict_from_system(false)
	
	vm.lua_newtable()
	vm.lua_pushinteger(datetime.year)
	vm.lua_setfield(-2, "year")
	vm.lua_pushinteger(datetime.month)
	vm.lua_setfield(-2, "month")
	vm.lua_pushinteger(datetime.day)
	vm.lua_setfield(-2, "day")
	vm.lua_pushinteger(datetime.hour)
	vm.lua_setfield(-2, "hour")
	vm.lua_pushinteger(datetime.minute)
	vm.lua_setfield(-2, "minute")
	vm.lua_pushinteger(datetime.second)
	vm.lua_setfield(-2, "second")
	vm.lua_pushinteger(datetime.weekday)
	vm.lua_setfield(-2, "weekday")
	
	return 1

static func time_sleep_handler(vm: LuauVM) -> int:
	vm.luaL_checknumber(1)
	var seconds = vm.lua_tonumber(1)
	
	if seconds > 0:
		var target_time = Time.get_ticks_msec() + (seconds * 1000.0)
		while Time.get_ticks_msec() < target_time:
			OS.delay_msec(1)
			
	return 0

static func time_benchmark_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TFUNCTION)
	
	var start_time = Time.get_ticks_msec()
	
	vm.lua_pushvalue(1)
	if vm.lua_pcall(0, 0, 0) != vm.LUA_OK:
		var error_msg = vm.lua_tostring(-1)
		vm.lua_pop(1)
		
		var end = Time.get_ticks_msec()
		var elapsed = end - start_time
		
		vm.lua_pushnumber(elapsed / 1000.0)
		vm.lua_pushstring("Error: " + error_msg)
		return 2
	
	var end_time = Time.get_ticks_msec()
	var elapsed_ms = end_time - start_time
	
	vm.lua_pushnumber(elapsed_ms / 1000.0)
	return 1

static func time_timer_handler(vm: LuauVM) -> int:
	var start_time = Time.get_ticks_msec()
	
	vm.lua_newtable()
	vm.lua_pushnumber(start_time)
	vm.lua_setfield(-2, "_start_time")
	
	vm.lua_pushcallable(timer_elapsed_handler, "timer:elapsed")
	vm.lua_setfield(-2, "elapsed")
	
	vm.lua_pushcallable(timer_reset_handler, "timer:reset")
	vm.lua_setfield(-2, "reset")
	
	return 1

static func timer_elapsed_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_start_time")
	var start_time = vm.lua_tonumber(-1)
	vm.lua_pop(1)
	
	var current_time = Time.get_ticks_msec()
	var elapsed = (current_time - start_time) / 1000.0
	
	vm.lua_pushnumber(elapsed)
	return 1

static func timer_reset_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	var current_time = Time.get_ticks_msec()
	vm.lua_pushnumber(current_time)
	vm.lua_setfield(1, "_start_time")
	
	return 0

static func time_delay_handler(vm: LuauVM) -> int:
	vm.luaL_checknumber(1)
	var seconds = vm.lua_tonumber(1)
	var end_time = Time.get_ticks_msec() + (seconds * 1000)
	
	vm.lua_newtable()
	vm.lua_pushnumber(end_time)
	vm.lua_setfield(-2, "_end_time")
	
	vm.lua_pushcallable(delay_is_complete_handler, "delay:complete")
	vm.lua_setfield(-2, "complete")
	
	vm.lua_pushcallable(delay_remaining_handler, "delay:remaining")
	vm.lua_setfield(-2, "remaining")
	
	return 1

static func delay_is_complete_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_end_time")
	var end_time = vm.lua_tonumber(-1)
	vm.lua_pop(1)
	
	var current_time = Time.get_ticks_msec()
	var is_complete = current_time >= end_time
	
	vm.lua_pushboolean(is_complete)
	return 1

static func delay_remaining_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_end_time")
	var end_time = vm.lua_tonumber(-1)
	vm.lua_pop(1)
	
	var current_time = Time.get_ticks_msec()
	var remaining = max(0.0, (end_time - current_time) / 1000.0)
	
	vm.lua_pushnumber(remaining)
	return 1

static func format_datetime(datetime: Dictionary, format_string: String) -> String:
	var result = format_string
	
	var local_datetime = datetime
	if not local_datetime.has("weekday"):
		var unix_time = Time.get_unix_time_from_datetime_dict(local_datetime)
		local_datetime = Time.get_datetime_dict_from_unix_time(unix_time)
	
	var ampm = ""
	var hour12 = local_datetime.hour
	if local_datetime.hour >= 12:
		ampm = "pm"
		if local_datetime.hour > 12:
			hour12 = local_datetime.hour - 12
	else:
		ampm = "am"
		if local_datetime.hour == 0:
			hour12 = 12
	
	result = result.replace("%Y", "%04d" % local_datetime.year)
	result = result.replace("%y", "%02d" % (local_datetime.year % 100))
	result = result.replace("%m", "%02d" % local_datetime.month)
	result = result.replace("%d", "%02d" % local_datetime.day)
	result = result.replace("%H", "%02d" % local_datetime.hour)
	result = result.replace("%I", "%02d" % hour12)
	result = result.replace("%M", "%02d" % local_datetime.minute)
	result = result.replace("%S", "%02d" % local_datetime.second)
	result = result.replace("%p", ampm)
	
	var weekday_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
	var weekday_abbrev = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	if local_datetime.weekday >= 0 and local_datetime.weekday <= 6:
		result = result.replace("%A", weekday_names[local_datetime.weekday])
		result = result.replace("%a", weekday_abbrev[local_datetime.weekday])
	
	var month_names = ["January", "February", "March", "April", "May", "June","July", "August", "September", "October", "November", "December"]
	var month_abbrev = ["Jan", "Feb", "Mar", "Apr", "May", "Jun","Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	if local_datetime.month >= 1 and local_datetime.month <= 12:
		result = result.replace("%B", month_names[local_datetime.month - 1])
		result = result.replace("%b", month_abbrev[local_datetime.month - 1])
	
	return result

static func setup_time_api(vm: LuauVM) -> void:
	vm.lua_newtable()
	
	vm.lua_pushcallable(time_now_handler, "Time.now")
	vm.lua_setfield(-2, "now")
	
	vm.lua_pushcallable(time_format_handler, "Time.format")
	vm.lua_setfield(-2, "format")
	
	vm.lua_pushcallable(time_date_handler, "Time.date")
	vm.lua_setfield(-2, "date")
	
	vm.lua_pushcallable(time_sleep_handler, "Time.sleep")
	vm.lua_setfield(-2, "sleep")
	
	vm.lua_pushcallable(time_benchmark_handler, "Time.benchmark")
	vm.lua_setfield(-2, "benchmark")
	
	vm.lua_pushcallable(time_timer_handler, "Time.timer")
	vm.lua_setfield(-2, "timer")
	
	vm.lua_pushcallable(time_delay_handler, "Time.delay")
	vm.lua_setfield(-2, "delay")
	
	vm.lua_setglobal("Time")
