class_name SizingUtils
extends RefCounted

# Utility functions for handling sizes in the UI

const DEFAULT_VIEWPORT_WIDTH = 800.0
const DEFAULT_VIEWPORT_HEIGHT = 600.0

static func parse_size_value(val):
	if val == null: return null
	if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
		return float(val)
	if val.ends_with("px"):
		return float(val.replace("px", ""))
	if val.ends_with("rem"):
		return float(val.replace("rem", "")) * 16.0
	if val.ends_with("%") or (val.ends_with("]") and "%" in val):
		var clean_val = val.replace("[", "").replace("]", "")
		return clean_val
	if val == "full":
		return null
	return float(val)

static func should_skip_sizing(node: Control, element, parser) -> bool:
	var element_styles = parser.get_element_styles_internal(element, "")
	
	# Button sizing rules: Skip sizing only when button has no explicit size 
	# AND parent doesn't have explicit width (auto-inherited sizing)
	if node is HTMLButton:
		# If button has explicit size, don't skip sizing
		if element_styles.has("width") or element_styles.has("height"):
			return false
		
		# Check if width is being inherited from parent with explicit size
		var parent_element = element.parent
		if parent_element:
			var parent_styles = parser.get_element_styles_internal(parent_element, "")
			var parent_has_explicit_width = parent_styles.has("width")
			# Skip only if parent doesn't have explicit width (auto-inherited)
			return not parent_has_explicit_width
		
		return true
	
	# Span sizing rules: Always skip sizing for spans since they're inline elements
	# (flex containers use AutoSizingFlexContainer, not span.gd)
	elif node is HTMLSpan:
		return true

	return false

static func apply_container_dimension_sizing(node: Control, width, height, styles: Dictionary = {}) -> void:
	if width != null:
		if is_percentage(width):
			node.set_meta("container_percentage_width", width)
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			# Don't call immediately - will be called later when parent is available
		else:
			node.custom_minimum_size.x = width
			node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	if height != null:
		if is_percentage(height):
			node.set_meta("container_percentage_height", height)
			node.size_flags_vertical = Control.SIZE_EXPAND_FILL
			apply_container_percentage_sizing(node)
		else:
			node.custom_minimum_size.y = height
			node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	apply_size_constraints_and_flags(node, styles)

static func apply_regular_control_sizing(node: Control, width, height, styles: Dictionary = {}) -> void:
	if width != null:
		if is_percentage(width):
			var estimated_width = calculate_percentage_size(width, DEFAULT_VIEWPORT_WIDTH)
			node.custom_minimum_size.x = estimated_width
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			node.custom_minimum_size.x = width
			node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	if height != null:
		if is_percentage(height):
			var estimated_height = calculate_percentage_size(height, DEFAULT_VIEWPORT_HEIGHT)
			node.custom_minimum_size.y = estimated_height
			node.size_flags_vertical = Control.SIZE_EXPAND_FILL
		else:
			node.custom_minimum_size.y = height
			node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	apply_size_constraints_and_flags(node, styles)

static func is_percentage(value) -> bool:
	return typeof(value) == TYPE_STRING and value.ends_with("%")

static func calculate_percentage_size(percentage_str: String, fallback_size: float) -> float:
	var clean_percentage = percentage_str.replace("%", "")
	var percentage = float(clean_percentage) / 100.0
	return fallback_size * percentage

static func apply_container_percentage_sizing(node: Control) -> void:
	var parent = node.get_parent()
	if not parent:
		return

	var new_min_size = node.custom_minimum_size
	
	if node.has_meta("container_percentage_width"):
		var percentage_str = node.get_meta("container_percentage_width")
		var parent_width = get_parent_dimension(parent, true, 0)
		if parent_width > 0:
			new_min_size.x = calculate_percentage_size(percentage_str, parent_width)
			node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		else:
			# Parent size not available yet, defer sizing by using SIZE_EXPAND_FILL
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var percentage_value = float(percentage_str.replace("%", "")) / 100.0
			node.size_flags_stretch_ratio = percentage_value
	
	if node.has_meta("container_percentage_height"):
		var percentage_str = node.get_meta("container_percentage_height")
		var parent_height = get_parent_dimension(parent, false, 0)
		if parent_height > 0:
			new_min_size.y = calculate_percentage_size(percentage_str, parent_height)
		else:
			# Parent size not available yet, defer sizing by using SIZE_EXPAND_FILL
			node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	node.custom_minimum_size = new_min_size

static func apply_size_constraints_and_flags(node: Control, styles: Dictionary) -> void:	
	# Apply min/max width constraints
	if styles.has("min-width"):
		var min_width = parse_size_value(styles["min-width"])
		if min_width != null and typeof(min_width) != TYPE_STRING:
			node.custom_minimum_size.x = max(node.custom_minimum_size.x, min_width)
	
	if styles.has("max-width"):
		var max_width = parse_size_value(styles["max-width"])
		if max_width != null and typeof(max_width) != TYPE_STRING:
			if node.custom_minimum_size.x > max_width:
				node.custom_minimum_size.x = max_width
			# Prevent expansion beyond max width
			if node.size_flags_horizontal == Control.SIZE_EXPAND_FILL:
				node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	# Apply min/max height constraints  
	if styles.has("min-height"):
		var min_height = parse_size_value(styles["min-height"])
		if min_height != null and typeof(min_height) != TYPE_STRING:
			node.custom_minimum_size.y = max(node.custom_minimum_size.y, min_height)
	
	if styles.has("max-height"):
		var max_height = parse_size_value(styles["max-height"])
		if max_height != null and typeof(max_height) != TYPE_STRING:
			if node.custom_minimum_size.y > max_height:
				node.custom_minimum_size.y = max_height
			# Prevent expansion beyond max height
			if node.size_flags_vertical == Control.SIZE_EXPAND_FILL:
				node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Handle intrinsic sizing for elements with constraints but no explicit size
	if not styles.has("width") and (styles.has("min-width") or styles.has("max-width")):
		node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if not styles.has("height") and (styles.has("min-height") or styles.has("max-height")):
		node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

static func get_parent_dimension(parent: Control, is_width: bool, fallback: float) -> float:
	var size_value = parent.size.x if is_width else parent.size.y
	if size_value > 0:
		return size_value
	
	var rect_size = parent.get_rect().size.x if is_width else parent.get_rect().size.y
	if rect_size > 0:
		return rect_size
	
	var min_size = parent.custom_minimum_size.x if is_width else parent.custom_minimum_size.y
	if min_size > 0:
		return min_size
	
	return fallback
