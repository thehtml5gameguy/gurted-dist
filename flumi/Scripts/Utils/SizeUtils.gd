class_name SizeUtils
extends RefCounted

# Utility functions for parsing CSS size values

static func parse_size(val: String) -> String:
	if val == null or val.is_empty():
		return "0px"

	var named = {
		"0": "0px", "1": "4px", "2": "8px", "3": "12px", "4": "16px", "5": "20px", "6": "24px", "8": "32px", "10": "40px",
		"12": "48px", "16": "64px", "20": "80px", "24": "96px", "28": "112px", "32": "128px", "36": "144px", "40": "160px",
		"44": "176px", "48": "192px", "52": "208px", "56": "224px", "60": "240px", "64": "256px", "72": "288px", "80": "320px", "96": "384px",
		"3xs": "256px", "2xs": "288px", "xs": "320px", "sm": "384px", "md": "448px", "lg": "512px",
		"xl": "576px", "2xl": "672px", "3xl": "768px", "4xl": "896px", "5xl": "1024px", "6xl": "1152px", "7xl": "1280px",
		"full": "100%"
	}
	if named.has(val):
		return named[val]
	# Fractional (e.g. 1/2, 1/3)
	if val.find("/") != -1:
		var parts = val.split("/")
		if parts.size() == 2 and \
		parts[1].is_valid_int() and \
		parts[0].is_valid_int() and \
		int(parts[1]) != 0:
			var frac = float(parts[0]) / float(parts[1])
			return str(frac * 100.0) + "%"

	if val.is_valid_int():
		return str(int(val) * 16) + "px"
	return val

static func extract_bracket_content(string: String, start_idx: int) -> String:
	var open_idx = string.find("[", start_idx)
	if open_idx == -1:
		return ""
	var close_idx = string.find("]", open_idx)
	if close_idx == -1:
		return ""
	return string.substr(open_idx + 1, close_idx - open_idx - 1)

static func parse_radius(radius_str: String) -> int:
	if radius_str.ends_with("px"):
		return int(radius_str.replace("px", ""))
	elif radius_str.ends_with("rem"):
		return int(radius_str.replace("rem", "")) * 16
	elif radius_str.is_valid_float():
		return int(radius_str)
	else:
		return 0
