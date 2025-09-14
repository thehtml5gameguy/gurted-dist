class_name LuaTweenUtils
extends RefCounted

class LuaTweenInstance:
	var tween: Tween
	var target_element: HTMLParser.HTMLElement
	var target_dom_node: Node
	var lua_api: LuaAPI
	var dom_parser: HTMLParser
	var tween_chain: Array = []
	var is_parallel: bool = false
	var callback_function: Callable
	var default_duration: float = 1.0
	var default_easing: String = "easeInOut"
	var default_transition: String = "transLinear"
	var steps_count: int = 1
	var current_tween_config: Dictionary = {}
	
	func _init(element: HTMLParser.HTMLElement, dom_node: Node, api: LuaAPI, parser: HTMLParser):
		target_element = element
		target_dom_node = dom_node
		lua_api = api
		dom_parser = parser
		
		# Don't create tween here - will be created on main thread when needed
		tween = null
		is_parallel = false

static func create_element_tween(vm: LuauVM, lua_api: LuaAPI) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_element_id")
	var element_id: String = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var element = lua_api.dom_parser.find_by_id(element_id)
	if not element:
		vm.lua_pushnil()
		return 1
	
	var dom_node = lua_api.dom_parser.parse_result.dom_nodes.get(element_id, null)
	if not dom_node:
		vm.lua_pushnil()
		return 1
	
	var tween_instance = LuaTweenInstance.new(element, dom_node, lua_api, lua_api.dom_parser)
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	
	add_tween_methods(vm)
	
	return 1

static func add_tween_methods(vm: LuauVM):
	# Animation methods
	vm.lua_pushcallable(_tween_to_wrapper, "tween.to")
	vm.lua_setfield(-2, "to")
	
	vm.lua_pushcallable(_tween_from_wrapper, "tween.from")
	vm.lua_setfield(-2, "from")
	
	# Configuration methods
	vm.lua_pushcallable(_tween_duration_wrapper, "tween.duration")
	vm.lua_setfield(-2, "duration")
	
	vm.lua_pushcallable(_tween_easing_wrapper, "tween.easing")
	vm.lua_setfield(-2, "easing")
	
	vm.lua_pushcallable(_tween_transition_wrapper, "tween.transition")
	vm.lua_setfield(-2, "transition")
	
	# Control methods
	vm.lua_pushcallable(_tween_play_wrapper, "tween.play")
	vm.lua_setfield(-2, "play")
	
	vm.lua_pushcallable(_tween_parallel_wrapper, "tween.parallel")
	vm.lua_setfield(-2, "parallel")
	
	vm.lua_pushcallable(_tween_chain_wrapper, "tween.chain")
	vm.lua_setfield(-2, "chain")
	
	vm.lua_pushcallable(_tween_loops_wrapper, "tween.loops")
	vm.lua_setfield(-2, "loops")
	
	vm.lua_pushcallable(_tween_callback_wrapper, "tween.callback")
	vm.lua_setfield(-2, "callback")
	
	# Playback control
	vm.lua_pushcallable(_tween_stop_wrapper, "tween.stop")
	vm.lua_setfield(-2, "stop")
	
	vm.lua_pushcallable(_tween_pause_wrapper, "tween.pause")
	vm.lua_setfield(-2, "pause")
	
	vm.lua_pushcallable(_tween_resume_wrapper, "tween.resume")
	vm.lua_setfield(-2, "resume")
	
	# Kill method
	vm.lua_pushcallable(_tween_kill_wrapper, "tween.kill")
	vm.lua_setfield(-2, "kill")

static func _tween_to_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	var property: String = vm.luaL_checkstring(2)
	var target_value = vm.lua_tovariant(3)
	
	var tween_op = {
		"type": "to",
		"property": property,
		"target_value": target_value,
		"duration": tween_instance.default_duration,
		"easing": tween_instance.default_easing,
		"transition": tween_instance.default_transition
	}
	tween_instance.tween_chain.append(tween_op)
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_from_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	var property: String = vm.luaL_checkstring(2)
	var start_value = vm.lua_tovariant(3)
	
	tween_instance.current_tween_config = {
		"type": "from",
		"property": property,
		"start_value": start_value,
		"duration": tween_instance.default_duration,
		"easing": tween_instance.default_easing,
		"transition": tween_instance.default_transition
	}
	tween_instance.tween_chain.append(tween_instance.current_tween_config)
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	
	# Re-add all tween methods to the new table
	add_tween_methods(vm)
	
	return 1

static func _tween_duration_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	var duration: float = vm.luaL_checknumber(2)
	
	if tween_instance.tween_chain.size() > 0:
		tween_instance.tween_chain[-1]["duration"] = duration
	else:
		tween_instance.default_duration = duration
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_easing_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	var easing: String = vm.luaL_checkstring(2)
	
	if tween_instance.tween_chain.size() > 0:
		tween_instance.tween_chain[-1]["easing"] = easing
	else:
		tween_instance.default_easing = easing
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_transition_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	var transition: String = vm.luaL_checkstring(2)
	
	if tween_instance.tween_chain.size() > 0:
		tween_instance.tween_chain[-1]["transition"] = transition
	else:
		tween_instance.default_transition = transition
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_play_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	if not is_instance_valid(tween_instance.target_dom_node):
		return 0
	
	var operations_to_execute = tween_instance.tween_chain.duplicate()
	var is_parallel = tween_instance.is_parallel
	var steps_count = tween_instance.steps_count
	var callback_func = tween_instance.callback_function
	
	# Clear chain after copying
	tween_instance.tween_chain.clear()
	
	_execute_tween_on_main_thread.call_deferred(tween_instance.target_dom_node, operations_to_execute, is_parallel, callback_func, steps_count)
	
	return 0

static func _tween_parallel_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	tween_instance.is_parallel = true
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_chain_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	tween_instance.is_parallel = false
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_loops_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	var loops: int = vm.luaL_checkint(2)
	
	# Store loops count for execution
	tween_instance.steps_count = loops
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_callback_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	vm.luaL_checktype(2, vm.LUA_TFUNCTION)
	
	var callback_ref = vm.lua_ref(2) # Reference function at index 2
	
	tween_instance.callback_function = LuaTweenUtils.execute_lua_callback.bind(vm, callback_ref)
	
	vm.lua_newtable()
	vm.lua_pushobject(tween_instance)
	vm.lua_setfield(-2, "_tween_instance")
	add_tween_methods(vm)
	return 1

static func _tween_stop_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	if tween_instance.tween and is_instance_valid(tween_instance.tween):
		tween_instance.tween.stop()
	
	return 0

static func _tween_pause_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	if tween_instance.tween and is_instance_valid(tween_instance.tween):
		tween_instance.tween.pause()
	
	return 0

static func _tween_resume_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	if tween_instance.tween and is_instance_valid(tween_instance.tween):
		tween_instance.tween.play()
	return 0

static func _tween_kill_wrapper(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	vm.lua_getfield(1, "_tween_instance")
	var tween_instance = vm.lua_toobject(-1) as LuaTweenInstance
	vm.lua_pop(1)
	if not tween_instance:
		return 0
	
	if tween_instance.tween and is_instance_valid(tween_instance.tween):
		tween_instance.tween.kill()
	return 0


static func parse_easing(easing_name: String) -> Tween.EaseType:
	match easing_name.to_lower():
		"in", "easein":
			return Tween.EASE_IN
		"out", "easeout":
			return Tween.EASE_OUT
		"inout", "easeinout":
			return Tween.EASE_IN_OUT
		"outin", "easeoutin":
			return Tween.EASE_OUT_IN
		_:
			return Tween.EASE_IN_OUT

static func parse_transition(transition_name: String) -> Tween.TransitionType:
	match transition_name.to_lower():
		"linear", "translinear":
			return Tween.TRANS_LINEAR
		"quad", "transquad":
			return Tween.TRANS_QUAD
		"cubic", "transcubic":
			return Tween.TRANS_CUBIC
		"quart", "transquart":
			return Tween.TRANS_QUART
		"quint", "transquint":
			return Tween.TRANS_QUINT
		"sine", "transsine":
			return Tween.TRANS_SINE
		"expo", "transexpo":
			return Tween.TRANS_EXPO
		"circ", "transcirc":
			return Tween.TRANS_CIRC
		"elastic", "transelastic":
			return Tween.TRANS_ELASTIC
		"back", "transback":
			return Tween.TRANS_BACK
		"bounce", "transbounce":
			return Tween.TRANS_BOUNCE
		_:
			return Tween.TRANS_LINEAR

# Main thread execution of tween operations
static func _execute_tween_on_main_thread(dom_node: Node, operations: Array, is_parallel: bool, callback_func: Callable = Callable(), steps: int = 1):
	if not is_instance_valid(dom_node):
		return
	
	var tween = dom_node.create_tween()
	if not tween:
		return
	
	tween.set_parallel(is_parallel)
	
	if steps > 1:
		tween.set_loops(steps)
	
	if callback_func.is_valid():
		tween.finished.connect(callback_func, CONNECT_ONE_SHOT)
	
	for i in range(operations.size()):
		var tween_op = operations[i]
		execute_single_tween_operation(dom_node, tween, tween_op)

static func execute_single_tween_operation(dom_node: Node, tween: Tween, tween_op: Dictionary):
	var property = tween_op.property
	var duration = tween_op.duration
	var easing = parse_easing(tween_op.get("easing", "easeInOut"))
	var transition = parse_transition(tween_op.get("transition", "transLinear"))
	
	match tween_op.type:
		"to":
			var target_value = tween_op.target_value
			animate_property_direct(dom_node, tween, property, target_value, duration, easing, transition)
		
		"from":
			var start_value = tween_op.start_value
			var current_value = get_property_value_direct(dom_node, property)
			set_property_value_direct(dom_node, property, start_value)
			animate_property_direct(dom_node, tween, property, current_value, duration, easing, transition)

static func animate_property_direct(dom_node: Node, tween: Tween, property: String, target_value, duration: float, easing: Tween.EaseType, transition: Tween.TransitionType = Tween.TRANS_LINEAR):
	match property:
		"opacity":
			var alpha_value = float(target_value)
			if dom_node is Control:
				var tweener = tween.tween_property(dom_node, "modulate:a", alpha_value, duration)
				tweener.set_ease(easing).set_trans(transition)
		
		"backgroundColor":
			var color_value = ColorUtils.parse_color(target_value)
			if dom_node is PanelContainer:
				var style_box = dom_node.get_theme_stylebox("panel")
				if style_box and style_box is StyleBoxFlat:
					tween.tween_property(style_box, "bg_color", color_value, duration).set_ease(easing).set_trans(transition)
					return
			elif dom_node is MarginContainer:
				var panel_child = null
				for child in dom_node.get_children():
					if child is PanelContainer:
						panel_child = child
						break
				if panel_child:
					var style_box = panel_child.get_theme_stylebox("panel")
					if style_box and style_box is StyleBoxFlat:
						tween.tween_property(style_box, "bg_color", color_value, duration).set_ease(easing).set_trans(transition)
						return
				tween.tween_property(dom_node, "modulate", color_value, duration).set_ease(easing).set_trans(transition)
			# Try Control as fallback
			elif dom_node is Control:
				tween.tween_property(dom_node, "modulate", color_value, duration).set_ease(easing).set_trans(transition)
		
		"color", "textColor":
			var color_value = ColorUtils.parse_color(target_value)
			if dom_node is RichTextLabel:
				tween.tween_property(dom_node, "modulate", color_value, duration).set_ease(easing).set_trans(transition)
			elif dom_node.has_method("get_node_or_null"):
				var rtl = dom_node.get_node_or_null("RichTextLabel")
				if rtl:
					tween.tween_property(rtl, "modulate", color_value, duration).set_ease(easing).set_trans(transition)
		
		"width":
			var width_value = float(target_value)
			if dom_node is Control:
				tween.tween_property(dom_node, "custom_minimum_size:x", width_value, duration).set_ease(easing).set_trans(transition)
		
		"height":
			var height_value = float(target_value)
			if dom_node is Control:
				tween.tween_property(dom_node, "custom_minimum_size:y", height_value, duration).set_ease(easing).set_trans(transition)
		
		"x", "position.x":
			var x_value = float(target_value)
			if dom_node is Control:
				tween.tween_property(dom_node, "position:x", x_value, duration).set_ease(easing).set_trans(transition)
		
		"y", "position.y":
			var y_value = float(target_value)
			if dom_node is Control:
				tween.tween_property(dom_node, "position:y", y_value, duration).set_ease(easing).set_trans(transition)
		
		"scale":
			var scale_value = float(target_value)
			if dom_node is Control:
				var scale_vec = Vector2(scale_value, scale_value)
				tween.tween_property(dom_node, "scale", scale_vec, duration).set_ease(easing).set_trans(transition)
		
		"rotation":
			var rotation_value = deg_to_rad(float(target_value))
			if dom_node is Control:
				tween.tween_property(dom_node, "rotation", rotation_value, duration).set_ease(easing).set_trans(transition)

static func set_property_value_direct(dom_node: Node, property: String, value):
	match property:
		"opacity":
			if dom_node is Control:
				dom_node.modulate.a = float(value)
		"backgroundColor":
			var color_value = ColorUtils.parse_color(value)
			if dom_node is PanelContainer:
				var style_box = dom_node.get_theme_stylebox("panel")
				if style_box and style_box is StyleBoxFlat:
					style_box.bg_color = color_value
			elif dom_node is MarginContainer:
				var panel_child = null
				for child in dom_node.get_children():
					if child is PanelContainer:
						panel_child = child
						break
				if panel_child:
					var style_box = panel_child.get_theme_stylebox("panel")
					if style_box and style_box is StyleBoxFlat:
						style_box.bg_color = color_value
				else:
					dom_node.modulate = color_value
			elif dom_node is Control:
				dom_node.modulate = color_value
		"color", "textColor":
			var color_value = ColorUtils.parse_color(value)
			if dom_node is RichTextLabel:
				dom_node.modulate = color_value
			elif dom_node.has_method("get_node_or_null"):
				var rtl = dom_node.get_node_or_null("RichTextLabel")
				if rtl:
					rtl.modulate = color_value
		"width":
			var width_value = float(value)
			if dom_node is Control:
				dom_node.custom_minimum_size.x = width_value
		"height":
			var height_value = float(value)
			if dom_node is Control:
				dom_node.custom_minimum_size.y = height_value
		"x", "position.x":
			if dom_node is Control:
				dom_node.position.x = float(value)
		"y", "position.y":
			if dom_node is Control:
				dom_node.position.y = float(value)
		"scale":
			var scale_value = float(value)
			if dom_node is Control:
				var scale_vec = Vector2(scale_value, scale_value)
				dom_node.scale = scale_vec
		"rotation":
			var rotation_value = deg_to_rad(float(value))
			if dom_node is Control:
				dom_node.rotation = rotation_value

static func get_property_value_direct(dom_node: Node, property: String):
	match property:
		"opacity":
			if dom_node is Control:
				return dom_node.modulate.a
		"backgroundColor":
			if dom_node is PanelContainer:
				var style_box = dom_node.get_theme_stylebox("panel")
				if style_box and style_box is StyleBoxFlat:
					return style_box.bg_color
			elif dom_node is MarginContainer:
				var panel_child = null
				for child in dom_node.get_children():
					if child is PanelContainer:
						panel_child = child
						break
				if panel_child:
					var style_box = panel_child.get_theme_stylebox("panel")
					if style_box and style_box is StyleBoxFlat:
						return style_box.bg_color
				else:
					return dom_node.modulate
			elif dom_node is Control:
				return dom_node.modulate
		"color", "textColor":
			if dom_node is RichTextLabel:
				return dom_node.modulate
			elif dom_node.has_method("get_node_or_null"):
				var rtl = dom_node.get_node_or_null("RichTextLabel")
				if rtl:
					return rtl.modulate
		"width":
			if dom_node is Control:
				return dom_node.custom_minimum_size.x
		"height":
			if dom_node is Control:
				return dom_node.custom_minimum_size.y
		"x", "position.x":
			if dom_node is Control:
				return dom_node.position.x
		"y", "position.y":
			if dom_node is Control:
				return dom_node.position.y
		"scale":
			if dom_node is Control:
				return dom_node.scale.x
		"rotation":
			if dom_node is Control:
				return rad_to_deg(dom_node.rotation)
	
	return 0

static func execute_lua_callback(vm: LuauVM, callback_ref: int):
	if not vm or not is_instance_valid(vm):
		return
	
	vm.lua_getref(callback_ref)
	
	if vm.lua_isfunction(-1):
		var result = vm.lua_pcall(0, 0, 0)
		if result != vm.LUA_OK:
			vm.lua_pop(1)
	else:
		vm.lua_pop(1)
	
	vm.lua_unref(callback_ref)
