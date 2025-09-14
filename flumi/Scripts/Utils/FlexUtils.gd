class_name FlexUtils
extends RefCounted

static func apply_flex_container_properties(node, styles: Dictionary) -> void:
	# Flex direction - default to row if not specified
	if styles.has("flex-direction"):
		match styles["flex-direction"]:
			"row": node.flex_direction = FlexContainer.FlexDirection.Row
			"row-reverse": node.flex_direction = FlexContainer.FlexDirection.RowReverse
			"column": node.flex_direction = FlexContainer.FlexDirection.Column
			"column-reverse": node.flex_direction = FlexContainer.FlexDirection.ColumnReverse
	else:
		node.flex_direction = FlexContainer.FlexDirection.Row
	# Flex wrap
	if styles.has("flex-wrap"):
		match styles["flex-wrap"]:
			"nowrap": 
				node.flex_wrap = FlexContainer.FlexWrap.NoWrap
			"wrap": 
				node.flex_wrap = FlexContainer.FlexWrap.Wrap
				# this is probably not needed but i dont feel like testing it
				node.flex_property_changed("flex_wrap", FlexContainer.FlexWrap.Wrap)
			"wrap-reverse": 
				node.flex_wrap = FlexContainer.FlexWrap.WrapReverse
	# Justify content
	if styles.has("justify-content"):
		match styles["justify-content"]:
			"flex-start": node.justify_content = FlexContainer.JustifyContent.FlexStart
			"flex-end": node.justify_content = FlexContainer.JustifyContent.FlexEnd
			"center": node.justify_content = FlexContainer.JustifyContent.Center
			"space-between": node.justify_content = FlexContainer.JustifyContent.SpaceBetween
			"space-around": node.justify_content = FlexContainer.JustifyContent.SpaceAround
			"space-evenly": node.justify_content = FlexContainer.JustifyContent.SpaceEvenly
	# Align items
	if styles.has("align-items"):
		match styles["align-items"]:
			"flex-start": node.align_items = FlexContainer.AlignItems.FlexStart
			"flex-end": node.align_items = FlexContainer.AlignItems.FlexEnd
			"center": node.align_items = FlexContainer.AlignItems.Center
			"stretch": node.align_items = FlexContainer.AlignItems.Stretch
			"baseline": node.align_items = FlexContainer.AlignItems.Baseline
	# Align content
	if styles.has("align-content"):
		match styles["align-content"]:
			"flex-start": node.align_content = FlexContainer.AlignContent.FlexStart
			"flex-end": node.align_content = FlexContainer.AlignContent.FlexEnd
			"center": node.align_content = FlexContainer.AlignContent.Center
			"stretch": node.align_content = FlexContainer.AlignContent.Stretch
			"space-between": node.align_content = FlexContainer.AlignContent.SpaceBetween
			"space-around": node.align_content = FlexContainer.AlignContent.SpaceAround
	# Gap
	if styles.has("gap"):
		# YGGutterAll = 2
		node._root.set_gap(2, parse_flex_value(styles["gap"]))
	if styles.has("row-gap"):
		# YGGutterRow = 1
		node._root.set_gap(1, parse_flex_value(styles["row-gap"]))
	if styles.has("column-gap"):
		# YGGutterColumn = 0
		node._root.set_gap(0, parse_flex_value(styles["column-gap"]))
	
	if styles.has("width"):
		var width_val = styles["width"]
		if width_val == "full" or width_val == "100%":
			# For flex containers, w-full should expand to fill parent
			node.set_meta("should_fill_horizontal", true)
			node.set_meta("size_flags_set_by_style_manager", true)
		elif typeof(width_val) == TYPE_STRING and width_val.ends_with("%"):
			node.set_meta("custom_css_width_percentage", width_val)
		else:
			node.set_meta("custom_css_width", SizingUtils.parse_size_value(width_val))
	if styles.has("height"):
		var height_val = styles["height"]
		if height_val == "full":
			# For flex containers, h-full should expand to fill parent
			node.set_meta("should_fill_vertical", true)
			node.set_meta("size_flags_set_by_style_manager", true)
		elif typeof(height_val) == TYPE_STRING and height_val.ends_with("%"):
			node.set_meta("custom_css_height_percentage", height_val)
		else:
			node.set_meta("custom_css_height", SizingUtils.parse_size_value(height_val))
	if styles.has("background-color"):
		node.set_meta("custom_css_background_color", styles["background-color"])
	
	node.update_layout()

static func apply_flex_item_properties(node: Control, styles: Dictionary) -> void:
	var properties: Dictionary = node.get_meta("flex_metas", {}).duplicate(true)
	var changed = false

	if styles.has("flex-grow"):
		properties["grow"] = float(styles["flex-grow"])
		changed = true
	if styles.has("flex-shrink"):
		properties["shrink"] = float(styles["flex-shrink"])
		changed = true
	if styles.has("flex-basis"):
		properties["basis"] = parse_flex_value(styles["flex-basis"])
		changed = true
	if styles.has("align-self"):
		var align_self_value = -1
		match styles["align-self"]:
			"auto": align_self_value = FlexContainer.AlignItems.Auto
			"flex-start": align_self_value = FlexContainer.AlignItems.FlexStart
			"flex-end": align_self_value = FlexContainer.AlignItems.FlexEnd
			"center": align_self_value = FlexContainer.AlignItems.Center
			"stretch": align_self_value = FlexContainer.AlignItems.Stretch
			"baseline": align_self_value = FlexContainer.AlignItems.Baseline
		
		if align_self_value != -1:
			properties["align_self"] = align_self_value
			changed = true

	if changed:
		node.set_meta("flex_metas", properties)
		var parent = node.get_parent()
		if parent is FlexContainer:
			parent.update_layout()

static func parse_flex_value(val):
	if val is float or val is int:
		return float(val)

	if val is String:
		var s_val = val.strip_edges()
		if s_val.is_valid_float():
			return s_val.to_float()
		if s_val.ends_with("%"):
			return s_val.trim_suffix("%").to_float() / 100.0
		if s_val.ends_with("px"):
			return s_val.trim_suffix("px").to_float()
		if s_val == "auto":
			return "auto"

	return null
