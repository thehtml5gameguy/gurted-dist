class_name GridUtils
extends RefCounted

static func apply_grid_container_properties(node: GridContainer, styles: Dictionary) -> void:
	if styles.has("grid-template-columns"):
		var cols = styles["grid-template-columns"]
		if cols is int:
			node.columns = cols
		elif cols is String:
			var parts = cols.split(" ")
			node.columns = parts.size()
	
	if styles.has("gap"):
		var gap_value = parse_grid_value(styles["gap"])
		if gap_value is int or gap_value is float:
			node.add_theme_constant_override("h_separation", int(gap_value))
			node.add_theme_constant_override("v_separation", int(gap_value))
	
	if styles.has("column-gap"):
		var gap_value = parse_grid_value(styles["column-gap"])
		if gap_value is int or gap_value is float:
			node.add_theme_constant_override("h_separation", int(gap_value))
	
	if styles.has("row-gap"):
		var gap_value = parse_grid_value(styles["row-gap"])
		if gap_value is int or gap_value is float:
			node.add_theme_constant_override("v_separation", int(gap_value))

static func apply_grid_item_properties(node: Control, styles: Dictionary) -> void:
	var grid_properties: Dictionary = node.get_meta("grid_properties", {})
	var changed = false
	
	if styles.has("grid-column"):
		grid_properties["grid-column"] = styles["grid-column"]
		changed = true
		
		if styles["grid-column"].begins_with("span "):
			var span_count = styles["grid-column"].substr(5).to_int()
			if span_count > 1:
				node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				node.set_meta("grid_column_span", span_count)
		elif styles["grid-column"] == "1 / -1":
			# Full span
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			node.set_meta("grid_column_span", -1)
	
	if styles.has("grid-row"):
		grid_properties["grid-row"] = styles["grid-row"]
		changed = true
	
	if changed:
		node.set_meta("grid_properties", grid_properties)

static func parse_grid_value(val):
	if val is float or val is int:
		return val

	if val is String:
		var s_val = val.strip_edges()
		if s_val.is_valid_float():
			return s_val.to_float()
		if s_val.ends_with("px"):
			return s_val.trim_suffix("px").to_float()
		if s_val == "auto":
			return "auto"

	return null

static func get_grid_item_span(span_property: String) -> Dictionary:
	var result = {"start": -1, "end": -1, "span": 1}
	
	if span_property.begins_with("span "):
		var span_count = span_property.substr(5).to_int()
		result["span"] = max(1, span_count)
	elif span_property == "1 / -1":
		# Full span
		result["span"] = -1
	else:
		var parts = span_property.split(" / ")
		if parts.size() == 2:
			result["start"] = parts[0].to_int()
			result["end"] = parts[1].to_int()
	
	return result