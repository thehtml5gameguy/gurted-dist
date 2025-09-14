class_name TransformUtils
extends RefCounted

# Utility functions for parsing CSS transform values (scale and rotation)

# Parse scale values - returns a Vector2 with x and y scale factors
static func parse_scale(val: String) -> Vector2:
	if val == null or val.is_empty():
		return Vector2.ONE
	
	# Named scale values
	var named = {
		"0": Vector2.ZERO,
		"50": Vector2(0.5, 0.5),
		"75": Vector2(0.75, 0.75),
		"90": Vector2(0.9, 0.9),
		"95": Vector2(0.95, 0.95),
		"100": Vector2.ONE,
		"105": Vector2(1.05, 1.05),
		"110": Vector2(1.1, 1.1),
		"125": Vector2(1.25, 1.25),
		"150": Vector2(1.5, 1.5),
		"200": Vector2(2.0, 2.0)
	}
	
	if named.has(val):
		return named[val]
	
	# Direct numeric value (treat as percentage: 100 = 1.0, 50 = 0.5, etc.)
	if val.is_valid_int():
		var scale_factor = float(val) / 100.0
		return Vector2(scale_factor, scale_factor)
	
	# Direct decimal value
	if val.is_valid_float():
		var scale_factor = float(val)
		return Vector2(scale_factor, scale_factor)
	
	return Vector2.ONE

# Parse rotation values - returns rotation in radians
static func parse_rotation(val: String) -> float:
	if val == null or val.is_empty():
		return 0.0
	
	# Named rotation values (in degrees, converted to radians)
	var named = {
		"0": 0.0,
		"1": deg_to_rad(1.0),
		"2": deg_to_rad(2.0),
		"3": deg_to_rad(3.0),
		"6": deg_to_rad(6.0),
		"12": deg_to_rad(12.0),
		"45": deg_to_rad(45.0),
		"90": deg_to_rad(90.0),
		"180": deg_to_rad(180.0),
		"270": deg_to_rad(270.0)
	}
	
	if named.has(val):
		return named[val]
	
	# Handle explicit unit specifications
	if val.ends_with("deg"):
		var degrees = float(val.replace("deg", ""))
		return deg_to_rad(degrees)
	elif val.ends_with("rad"):
		return float(val.replace("rad", ""))
	elif val.ends_with("turn"):
		var turns = float(val.replace("turn", ""))
		return turns * 2.0 * PI
	
	# Direct numeric value - assume degrees
	if val.is_valid_float():
		return deg_to_rad(float(val))
	
	return 0.0

# Parse arbitrary value from brackets like [1.7] or [45deg] or [3.5rad]
static func parse_bracket_value(bracket_content: String, value_type: String):
	if bracket_content.is_empty():
		return null
	
	match value_type:
		"scale":
			return parse_scale(bracket_content)
		"rotation":
			return parse_rotation(bracket_content)
		_:
			return null

# Extract bracket content for transform utilities
static func extract_bracket_content(string: String, start_idx: int) -> String:
	var open_idx = string.find("[", start_idx)
	if open_idx == -1:
		return ""
	var close_idx = string.find("]", open_idx)
	if close_idx == -1:
		return ""
	return string.substr(open_idx + 1, close_idx - open_idx - 1)

# Parse scale utility and return the appropriate property name and value
static func parse_scale_utility(utility_name: String) -> Dictionary:
	var result = {}
	
	if utility_name.begins_with("scale-x-"):
		var val = utility_name.substr(8)  # after "scale-x-"
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		var scale_vec = parse_scale(val)
		result["scale-x"] = scale_vec.x
		return result
	elif utility_name.begins_with("scale-y-"):
		var val = utility_name.substr(8)  # after "scale-y-"
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		var scale_vec = parse_scale(val)
		result["scale-y"] = scale_vec.y
		return result
	elif utility_name.begins_with("scale-"):
		var val = utility_name.substr(6)  # after "scale-"
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		var scale_vec = parse_scale(val)
		result["scale-x"] = scale_vec.x
		result["scale-y"] = scale_vec.y
		return result
	
	return result

# Parse rotation utility and return the appropriate property name and value
static func parse_rotation_utility(utility_name: String) -> Dictionary:
	var result = {}
	
	if utility_name.begins_with("rotate-"):
		var val = utility_name.substr(7)  # after "rotate-"
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		var rotation = parse_rotation(val)
		result["rotate"] = rotation
		return result
	
	return result

