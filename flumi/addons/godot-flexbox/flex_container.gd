@tool
class_name FlexContainer
extends Container

@export var debug_draw = false

var _draw_rects = []

const EDGES = [1, 2, 3, 0]
const _PADDING_WRAPPER_NAME = "__FlexPaddingWrapper"


enum FlexDirection {Column,ColumnReverse,Row,RowReverse}
enum FlexWrap {NoWrap,Wrap,WrapReverse}
enum JustifyContent {FlexStart,Center,FlexEnd,SpaceBetween,SpaceAround,SpaceEvenly}
enum AlignItems {Auto,FlexStart,Center,FlexEnd,Stretch,Baseline,SpaceBetween,SpaceAround}
enum AlignContent {Auto,FlexStart,Center,FlexEnd,Stretch,Baseline,SpaceBetween,SpaceAround}

const DEFAULT_VALUE = {
	reverse = 0,
	flex_wrap = FlexWrap.NoWrap,
	flex_direction = FlexDirection.Row,
	justify_content = JustifyContent.FlexStart,
	align_items = AlignItems.Stretch, # Note: Stretch is the default
	align_content = AlignContent.FlexStart
}

var _root: Flexbox
var _initialized = false

var _flex_list = []
enum FlexDataType { CID = 0, FLEXBOX, CONTROL }

var direction_reverse = DEFAULT_VALUE.reverse
@export var flex_direction:FlexDirection = DEFAULT_VALUE.flex_direction
@export var flex_wrap:FlexWrap = DEFAULT_VALUE.flex_wrap
@export var justify_content:JustifyContent = DEFAULT_VALUE.justify_content
@export var align_items:AlignItems = DEFAULT_VALUE.align_items
@export var align_content:AlignContent = DEFAULT_VALUE.align_content


var state:Dictionary = {flex_direction=null, flex_wrap=null,justify_content=null,align_items=null,align_content=null}

func _init():
	_root = Flexbox.new()
	update_state()


func update_state():
	for property in state:
		var value = get(property)
		state[property] = value


func _ready() -> void:
	_root.set_flex_direction(get("flex_direction"))
	_root.set_flex_wrap(get("flex_wrap"))
	_root.set_justify_content(get("justify_content"))
	_root.set_align_items(get("align_items"))
	_root.set_align_content(get("align_content"))
	update_state()
	set_process_input(false)
	_initialized = true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SORT_CHILDREN:
			_resort()
		[NOTIFICATION_TRANSLATION_CHANGED, NOTIFICATION_LAYOUT_DIRECTION_CHANGED]:
			queue_sort()


func _resort() -> void:
	if not is_instance_valid(_root):
		return

	_root.remove_all_children()
	_flex_list.clear()

	var root_size = get_size()
	_root.set_width(root_size.x)
	_root.set_height(root_size.y)

	if debug_draw:
		_draw_rects.clear()
		_draw_debug_rect(Rect2(Vector2.ZERO, root_size), Color(0, 0.8, 0.5, 1))

	for i in range(get_child_count()):
		var c = get_child(i)
		if not c.is_class("Control") or c.is_set_as_top_level() or not c.is_visible_in_tree():
			continue

		var flexbox = Flexbox.new()
		_root.insert_child(flexbox, _flex_list.size())
		_flex_list.append([c.get_instance_id(), flexbox, c])

		_set_control_min_size(c, flexbox)
		var flex_metas = c.get_meta("flex_metas", {})
		if flex_metas.size():
			apply_flex_meta(flexbox, flex_metas)
			if flex_metas.has("padding"):
				padding_wrapper(c, flex_metas.get("padding"))

	_root.mark_dirty_and_propogate()

	_root.calculate_layout(root_size.x, root_size.y, 1)

	for flex_data in _flex_list:
		var flexbox = flex_data[FlexDataType.FLEXBOX]
		var c = flex_data[FlexDataType.CONTROL]

		if not is_instance_valid(c):
			continue

		var offset = Vector2(flexbox.get_computed_left(), flexbox.get_computed_top())
		var size = Vector2(flexbox.get_computed_width(), flexbox.get_computed_height())
		_fit_child_in_rect(c, Rect2(offset, size))

		if debug_draw:
			_draw_debug_rect(Rect2(offset, size), Color(1, 0, 0, 0.8))

	queue_redraw()


func padding_wrapper(node:Control,spacing_value:Array):
	var wrapper_node = node.get_node_or_null(_PADDING_WRAPPER_NAME)
	if not wrapper_node:
		wrapper_node = MarginContainer.new()
		wrapper_node.name = _PADDING_WRAPPER_NAME
		var children_to_wrap = node.get_children()
		for child in children_to_wrap:
			if child != wrapper_node:
				child.reparent(wrapper_node)
		node.add_child(wrapper_node)
	wrapper_node.add_theme_constant_override("margin_left", spacing_value[0])
	wrapper_node.add_theme_constant_override("margin_top", spacing_value[1])
	wrapper_node.add_theme_constant_override("margin_right", spacing_value[2])
	wrapper_node.add_theme_constant_override("margin_bottom", spacing_value[3])


func _find_index_from_flex_list(flex_list: Array, cid: int) -> int:
	for i in range(flex_list.size()):
		if flex_list[i][FlexDataType.CID] == cid:
			return i
	return -1


func _set_control_min_size(c: Control, flexbox: Flexbox):
	var min_size = c.get_combined_minimum_size()
	flexbox.set_min_width(min_size.x)
	flexbox.set_min_height(min_size.y)


func _fit_child_in_rect(child: Control, rect: Rect2) -> void:
	if not is_instance_valid(child):
		return
	child.set_position(rect.position)
	child.set_size(rect.size)
	child.set_rotation(0)
	child.set_scale(Vector2.ONE)


func apply_flex_meta(node, metas):
	for key in metas:
		var value = metas[key]
		apply_child_property(node, key, value)


func apply_child_property(node, prop, value):
	match prop:
		"basis":
			if typeof(value) == TYPE_STRING and value == "auto":
				node.set_flex_basis_auto()
			else:
				node.set_flex_basis(value)
		"grow":
			node.set_flex_grow(value)
		"padding":
			for i in range(4):
				var edge = EDGES[i]
				node.set_padding(edge, value[i])
		"margin":
			for i in range(4):
				var edge = EDGES[i]
				var value1 = value[i]
				if typeof(value1) == TYPE_STRING and value1 == "auto":
					node.set_margin_auto(edge)
				else:
					node.set_margin(edge, value1)
		"align_self":
			node.set_align_self(value)


func flex_property_changed(property, value):
	value = process_value(property, value)
	state[property] = value
	set(property, value)
	match property:
		"flex_direction":
			_root.set_flex_direction(value)
		"flex_wrap":
			_root.set_flex_wrap(value)
		"justify_content":
			_root.set_justify_content(value)
		"align_items":
			_root.set_align_items(value)
		"align_content":
			_root.set_align_content(value)


func update_layout():
	queue_sort()


func edit_set_state(p_state):
	for property in p_state:
		var value = p_state[property]
		flex_property_changed(property, value)
	update_layout()


func edit_get_state():
	return state.duplicate()


func _draw():
	for r in _draw_rects:
		draw_rect(r.rect, r.color, false, 2)


func _draw_debug_rect(rect, color):
	_draw_rects.append({rect = rect, color = color})


func process_value(key, value):
	if DEFAULT_VALUE.has(key) && value == -1:
		return DEFAULT_VALUE[key]
	return value


func get_class():
	return "FlexContainer"
