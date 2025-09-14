class_name CSSParser
extends RefCounted

class CSSRule:
	var selector: String
	var event_prefix: String = ""
	var properties: Dictionary = {}
	var specificity: int = 0
	var selector_type: String = "simple" # simple, descendant, child, adjacent_sibling, general_sibling, attribute
	var selector_parts: Array = [] # For complex selectors
	var is_user_css: bool = false
	
	func init(sel: String = ""):
		selector = sel
		parse_selector()
		calculate_specificity()
	
	func parse_selector():
		if selector.contains(":"):
			var parts = selector.split(":", false, 1)
			if parts.size() == 2:
				selector = parts[0]
				event_prefix = parts[1]
		
		# Parse complex selectors
		if selector.contains(" > "):
			selector_type = "child"
			selector_parts = selector.split(" > ")
		elif selector.contains(" + "):
			selector_type = "adjacent_sibling"
			selector_parts = selector.split(" + ")
		elif selector.contains(" ~ "):
			selector_type = "general_sibling"
			selector_parts = selector.split(" ~ ")
		elif selector.contains("["):
			selector_type = "attribute"
			parse_attribute_selector()
		elif selector.contains(" "):
			selector_type = "descendant"
			selector_parts = selector.split(" ")
		else:
			selector_type = "simple"
			selector_parts = [selector]
	
	func parse_attribute_selector():
		var bracket_start = selector.find("[")
		var bracket_end = selector.find("]")
		if bracket_start != -1 and bracket_end != -1:
			var element_part = selector.substr(0, bracket_start)
			var attribute_part = selector.substr(bracket_start + 1, bracket_end - bracket_start - 1)
			selector_parts = [element_part, attribute_part]
	
	func calculate_specificity():
		specificity = 1
		if selector.begins_with("."):
			specificity += 20
		if selector.contains("["):
			specificity += 10
		match selector_type:
			"child":
				specificity += 8
			"adjacent_sibling":
				specificity += 7
			"attribute":
				specificity += 6
			"general_sibling":
				specificity += 5
			"descendant":
				specificity += 4
		if event_prefix.length() > 0:
			specificity += 10
		
		if is_user_css:
			specificity += 100
		

class CSSStylesheet:
	var rules: Array[CSSRule] = []
	
	func add_rule(rule: CSSRule):
		rules.append(rule)
	
	func find_rule_by_selector(selector: String) -> CSSRule:
		for rule in rules:
			if rule.selector == selector and rule.event_prefix == "":
				return rule
		
		for rule in rules:
			if rule.selector == selector:
				return rule
		return null
	
	func get_styles_for_element(event: String = "", element: HTMLParser.HTMLElement = null) -> Dictionary:
		var styles = {}
		
		# Sort rules by specificity
		var applicable_rules: Array[CSSRule] = []
		for rule in rules:
			if selector_matches(rule, event, element):
				applicable_rules.append(rule)
		
		applicable_rules.sort_custom(func(a, b): return a.specificity < b.specificity)
		
		# Apply styles in order of specificity
		for rule in applicable_rules:
			for property in rule.properties:
				styles[property] = rule.properties[property]
		
		return styles
	
	func selector_matches(rule: CSSRule, event: String = "", element: HTMLParser.HTMLElement = null) -> bool:
		if rule.event_prefix.length() > 0:
			if rule.event_prefix != event:
				return false
		elif event.length() > 0:
			return false
		
		match rule.selector_type:
			"simple":
				return matches_simple_selector_with_element(rule.selector_parts[0], element)
			"descendant":
				return matches_descendant_selector(rule.selector_parts, element)
			"child":
				return matches_child_selector(rule.selector_parts, element)
			"adjacent_sibling":
				return matches_adjacent_sibling_selector(rule.selector_parts, element)
			"general_sibling":
				return matches_general_sibling_selector(rule.selector_parts, element)
			"attribute":
				return matches_attribute_selector(rule.selector_parts, element)
		
		return false
	
	func matches_simple_selector(selector: String, tag_name: String, cls_names: Array[String]) -> bool:
		if selector.begins_with("."):
			var cls = selector.substr(1)
			return cls in cls_names
		elif selector.begins_with("#"):
			# need access to the element to check its ID
			return false  # will be handled by matches_simple_selector_with_element
		else:
			return selector == tag_name
	
	func matches_simple_selector_with_element(selector: String, element: HTMLParser.HTMLElement) -> bool:
		if not element:
			return false
			
		if selector.begins_with("."):
			var cls = selector.substr(1)
			var cls_names = HTMLParser.extract_class_names(element)
			return cls in cls_names
		elif selector.begins_with("#"):
			var element_id = selector.substr(1)
			return element.get_attribute("id") == element_id
		else:
			return selector == element.tag_name
	
	func matches_descendant_selector(parts: Array, element: HTMLParser.HTMLElement) -> bool:
		if not element or parts.size() < 2:
			return false
		
		# Last part should match current element
		var last_part = parts[-1].strip_edges()
		if not matches_simple_selector_with_element(last_part, element):
			return false
		
		# Check ancestors for remaining parts
		var current_element = element.parent
		var part_index = parts.size() - 2
		
		while current_element and part_index >= 0:
			var part = parts[part_index].strip_edges()
			if matches_simple_selector_with_element(part, current_element):
				part_index -= 1
				if part_index < 0:
					return true
			current_element = current_element.parent
		
		return false
	
	func matches_child_selector(parts: Array, element: HTMLParser.HTMLElement) -> bool:
		if not element or not element.parent or parts.size() != 2:
			return false
		
		var child_part = parts[1].strip_edges()
		var parent_part = parts[0].strip_edges()
		
		# Element must match the child part
		if not matches_simple_selector_with_element(child_part, element):
			return false
		
		# Parent must match the parent part
		return matches_simple_selector_with_element(parent_part, element.parent)
	
	func matches_adjacent_sibling_selector(parts: Array, element: HTMLParser.HTMLElement) -> bool:
		if not element or not element.parent or parts.size() != 2:
			return false
		
		var second_part = parts[1].strip_edges()
		var first_part = parts[0].strip_edges()
		
		if not matches_simple_selector_with_element(second_part, element):
			return false
		
		# Find previous sibling
		var siblings = element.parent.children
		var element_index = siblings.find(element)
		if element_index <= 0:
			return false
		
		var prev_sibling = siblings[element_index - 1]
		return matches_simple_selector_with_element(first_part, prev_sibling)
	
	func matches_general_sibling_selector(parts: Array, element: HTMLParser.HTMLElement) -> bool:
		if not element or not element.parent or parts.size() != 2:
			return false
		
		var second_part = parts[1].strip_edges()
		var first_part = parts[0].strip_edges()
		
		if not matches_simple_selector_with_element(second_part, element):
			return false
		
		# Check all previous siblings
		var siblings = element.parent.children
		var element_index = siblings.find(element)
		
		for i in range(element_index):
			var sibling = siblings[i]
			if matches_simple_selector_with_element(first_part, sibling):
				return true
		
		return false
	
	func matches_attribute_selector(parts: Array, element: HTMLParser.HTMLElement) -> bool:
		if not element or parts.size() != 2:
			return false
		
		var element_part = parts[0].strip_edges()
		var attribute_part = parts[1].strip_edges()
		
		# Check if element matches
		if element_part != "" and not matches_simple_selector_with_element(element_part, element):
			return false
		
		# Parse attribute condition
		if attribute_part.contains("="):
			var parsed = {}
			var element_value = ""
			
			if attribute_part.contains("^="):
				# Starts with
				parsed = parse_attribute_value(attribute_part, "^=")
				element_value = element.get_attribute(parsed.name)
				return element_value.begins_with(parsed.value)
			elif attribute_part.contains("$="):
				# Ends with
				parsed = parse_attribute_value(attribute_part, "$=")
				element_value = element.get_attribute(parsed.name)
				return element_value.ends_with(parsed.value)
			elif attribute_part.contains("*="):
				# Contains
				parsed = parse_attribute_value(attribute_part, "*=")
				element_value = element.get_attribute(parsed.name)
				return element_value.contains(parsed.value)
			else:
				# Exact match
				parsed = parse_attribute_value(attribute_part, "=")
				element_value = element.get_attribute(parsed.name)
				return element_value == parsed.value
		else:
			# Just check if attribute exists
			return element.has_attribute(attribute_part)
	
	func parse_attribute_value(attribute_part: String, operator: String) -> Dictionary:
		var attr_parts = attribute_part.split(operator)
		var attr_name = attr_parts[0].strip_edges()
		var attr_value = attr_parts[1].strip_edges()
		
		# Remove quotes
		if attr_value.begins_with('"') and attr_value.ends_with('"'):
			attr_value = attr_value.substr(1, attr_value.length() - 2)
		elif attr_value.begins_with("'") and attr_value.ends_with("'"):
			attr_value = attr_value.substr(1, attr_value.length() - 2)
		
		return {"name": attr_name, "value": attr_value}

var stylesheet: CSSStylesheet
var css_text: String

func init(css_content: String = ""):
	stylesheet = CSSStylesheet.new()
	css_text = css_content

func parse(is_user_css: bool = false) -> void:
	if css_text.is_empty():
		return
	
	var cleaned_css = preprocess_css(css_text)
	var rules = extract_rules(cleaned_css)
	
	for rule_data in rules:
		var rule = parse_rule(rule_data, is_user_css)
		if rule:
			stylesheet.add_rule(rule)

func preprocess_css(css: String) -> String:
	# Remove comments
	var regex = RegEx.new()
	regex.compile("/\\*.*?\\*/")
	css = regex.sub(css, "", true)
	
	# Normalize whitespace
	regex.compile("\\s+")
	css = regex.sub(css, " ", true)
	
	return css.strip_edges()

func extract_rules(css: String) -> Array:
	var rules = []
	var current_pos = 0
	
	while current_pos < css.length():
		var brace_start = css.find("{", current_pos)
		if brace_start == -1:
			break
		
		var brace_end = find_matching_brace(css, brace_start)
		if brace_end == -1:
			break
		
		var selector_part = css.substr(current_pos, brace_start - current_pos).strip_edges()
		var properties_part = css.substr(brace_start + 1, brace_end - brace_start - 1).strip_edges()
		
		# Handle multiple selectors separated by commas
		var selectors = selector_part.split(",")
		for selector in selectors:
			rules.append({
				"selector": selector.strip_edges(),
				"properties": properties_part
			})
		
		current_pos = brace_end + 1
	
	return rules

func find_matching_brace(css: String, start_pos: int) -> int:
	var brace_count = 0
	var pos = start_pos
	
	while pos < css.length():
		match css[pos]:
			"{":
				brace_count += 1
			"}":
				brace_count -= 1
				if brace_count == 0:
					return pos
		pos += 1
	
	return -1

func parse_rule(rule_data: Dictionary, is_user_css: bool = false) -> CSSRule:
	var rule = CSSRule.new()
	rule.selector = rule_data.selector
	rule.is_user_css = is_user_css
	rule.init(rule.selector)
	var properties_text = rule_data.properties
	
	var utility_classes = properties_text.split(" ")
	
	var base_utilities = []
	var pseudo_utilities = []
	
	for utility_name in utility_classes:
		utility_name = utility_name.strip_edges()
		if utility_name.is_empty():
			continue
		
		if utility_name.begins_with("hover:") or utility_name.begins_with("active:"):
			pseudo_utilities.append(utility_name)
		else:
			base_utilities.append(utility_name)
	
	for utility_name in base_utilities:
		parse_utility_class_internal(rule, utility_name)
	
	for utility_name in pseudo_utilities:
		parse_utility_class(rule, utility_name)
	
	return rule

func parse_utility_class(rule: CSSRule, utility_name: String) -> void:
	var pseudo_classes = ["hover", "active"]

	for pseudo in pseudo_classes:
		var prefix = pseudo + ":"
		if utility_name.begins_with(prefix):
			var actual_utility = utility_name.substr(prefix.length())
			var pseudo_rule = CSSRule.new()
			
			pseudo_rule.selector = rule.selector
			pseudo_rule.event_prefix = pseudo
			pseudo_rule.selector_type = rule.selector_type
			pseudo_rule.selector_parts = rule.selector_parts.duplicate()
			pseudo_rule.is_user_css = rule.is_user_css
			pseudo_rule.calculate_specificity()
			pseudo_rule.specificity += 100
			
			for property in rule.properties:
				pseudo_rule.properties[property] = rule.properties[property]
			
			parse_utility_class_internal(pseudo_rule, actual_utility)
			stylesheet.add_rule(pseudo_rule)
			return

	# Fallback to normal parsing
	rule.calculate_specificity()
	rule.specificity += 50
	parse_utility_class_internal(rule, utility_name)

# Parses a utility class (e.g. "text-red-500") and adds properties to the rule (e.g. "color: red")
# Used as a translation layer for Tailwind-like utility classes, as it becomes easier to manage these programmatically
static func parse_utility_class_internal(rule: CSSRule, utility_name: String) -> void:
	# Handle font size classes like text-[16px] or color classes like text-[#ff0000]
	if utility_name.begins_with("text-[") and utility_name.ends_with("]"):
		var bracket_content = SizeUtils.extract_bracket_content(utility_name, 5)  # after 'text-'
		
		# Check if it's a font size by looking for size units or being a valid number
		if bracket_content.ends_with("px") or bracket_content.ends_with("em") or bracket_content.ends_with("rem") or bracket_content.is_valid_int() or bracket_content.is_valid_float():
			var font_size_value = SizingUtils.parse_size_value(bracket_content)
			if font_size_value != null and typeof(font_size_value) != TYPE_STRING:
				rule.properties["font-size"] = font_size_value
				return
		
		# Parse as color
		var parsed_color = ColorUtils.parse_color(bracket_content)
		rule.properties["color"] = parsed_color
		return
	
	# Handle standard text color classes like text-white, text-black, etc.
	# But exclude text alignment and font size classes
	if utility_name.begins_with("text-") and not utility_name in ["text-left", "text-center", "text-right", "text-justify", "text-xs", "text-sm", "text-base", "text-lg", "text-xl", "text-2xl", "text-3xl", "text-4xl", "text-5xl", "text-6xl"]:
		var color_name = utility_name.substr(5)  # after 'text-'
		var color = ColorUtils.get_color(color_name)
		if color != null:
			rule.properties["color"] = color
			return

	# Handle background color classes like bg-[#ff0000]
	if utility_name.begins_with("bg-[") and utility_name.ends_with("]"):
		var color_value = SizeUtils.extract_bracket_content(utility_name, 3)  # after 'bg-'
		var color = ColorUtils.parse_color(color_value)
		rule.properties["background-color"] = color
		return
	
	# Handle standard background color classes like bg-white, bg-black, etc.
	if utility_name.begins_with("bg-"):
		var color_name = utility_name.substr(3)  # after 'bg-'
		var color = ColorUtils.get_color(color_name)
		if color != null:
			rule.properties["background-color"] = color
			return

	# e.g. max-w-[123px], w-[50%], h-[2rem]
	if utility_name.match("^max-w-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["max-width"] = val
		return
	if utility_name.match("^max-h-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["max-height"] = val
		return
	if utility_name.match("^min-w-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["min-width"] = val
		return
	if utility_name.match("^min-h-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 6)
		rule.properties["min-height"] = val
		return
	if utility_name.match("^w-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 2)
		rule.properties["width"] = val
		return
	if utility_name.match("^h-\\[.*\\]$"):
		var val = SizeUtils.extract_bracket_content(utility_name, 2)
		rule.properties["height"] = val
		return

	# Handle font weight
	if utility_name == "font-thin":
		rule.properties["font-thin"] = true
		return
	if utility_name == "font-extralight":
		rule.properties["font-extralight"] = true
		return
	if utility_name == "font-light":
		rule.properties["font-light"] = true
		return
	if utility_name == "font-normal":
		rule.properties["font-normal"] = true
		return
	if utility_name == "font-medium":
		rule.properties["font-medium"] = true
		return
	if utility_name == "font-semibold":
		rule.properties["font-semibold"] = true
		return
	if utility_name == "font-bold":
		rule.properties["font-bold"] = true
		return
	if utility_name == "font-extrabold":
		rule.properties["font-extrabold"] = true
		return
	if utility_name == "font-black":
		rule.properties["font-black"] = true
		return

	# Handle font family
	if utility_name == "font-sans":
		rule.properties["font-family"] = "sans-serif"
		return
	if utility_name == "font-serif":
		rule.properties["font-family"] = "serif"
		return
	if utility_name == "font-mono":
		rule.properties["font-family"] = "monospace"
		rule.properties["font-mono"] = true
		return
	
	var reserved_font_styles = ["font-sans", "font-serif", "font-mono", "font-thin", "font-extralight", "font-light", "font-normal", "font-medium", "font-semibold", "font-bold", "font-extrabold", "font-black", "font-italic"]
	# Handle custom font families like font-roboto
	if utility_name.begins_with("font-") and not utility_name in reserved_font_styles:
		var font_name = utility_name.substr(5)  # after 'font-'
		rule.properties["font-family"] = font_name
		return

	# Handle font style italic
	if utility_name == "font-italic":
		rule.properties["font-italic"] = true
		return

	# Handle underline
	if utility_name == "underline":
		rule.properties["underline"] = true
		return

	# Handle text size classes
	match utility_name:
		"text-xs": rule.properties["font-size"] = 18   # 12px web equivalent
		"text-sm": rule.properties["font-size"] = 21   # 14px web equivalent
		"text-base": rule.properties["font-size"] = 24  # 16px web equivalent
		"text-lg": rule.properties["font-size"] = 27   # 18px web equivalent
		"text-xl": rule.properties["font-size"] = 30   # 20px web equivalent
		"text-2xl": rule.properties["font-size"] = 36  # 24px web equivalent
		"text-3xl": rule.properties["font-size"] = 45  # 30px web equivalent
		"text-4xl": rule.properties["font-size"] = 54  # 36px web equivalent
		"text-5xl": rule.properties["font-size"] = 72  # 48px web equivalent
		"text-6xl": rule.properties["font-size"] = 90  # 60px web equivalent
		
		# Handle text alignment classes
		"text-left": rule.properties["text-align"] = "left"
		"text-center": rule.properties["text-align"] = "center"
		"text-right": rule.properties["text-align"] = "right"
		"text-justify": rule.properties["text-align"] = "justify"
	
	# Width
	if utility_name.begins_with("w-"):
		var val = utility_name.substr(2)
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		rule.properties["width"] = SizeUtils.parse_size(val)
		return
	# Height
	if utility_name.begins_with("h-"):
		# Skip h-full for flex containers as it conflicts with Yoga layout
		if utility_name == "h-full" and rule.properties.has("display") and (rule.properties["display"] == "flex" or rule.properties["display"] == "inline-flex"):
			return
		var val = utility_name.substr(2)
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		rule.properties["height"] = SizeUtils.parse_size(val)
		return
	# Min width
	if utility_name.begins_with("min-w-"):
		var val = utility_name.substr(6)
		rule.properties["min-width"] = SizeUtils.parse_size(val)
		return
	# Min height
	if utility_name.begins_with("min-h-"):
		var val = utility_name.substr(6)
		rule.properties["min-height"] = SizeUtils.parse_size(val)
		return
	# Max width
	if utility_name.begins_with("max-w-"):
		var val = utility_name.substr(6)
		rule.properties["max-width"] = SizeUtils.parse_size(val)
		return
	# Max height
	if utility_name.begins_with("max-h-"):
		var val = utility_name.substr(6)
		rule.properties["max-height"] = SizeUtils.parse_size(val)
		return

	# Flex container
	if utility_name == "flex":
		rule.properties["display"] = "flex"
		return
	if utility_name == "inline-flex":
		rule.properties["display"] = "inline-flex"
		return
	
	if utility_name == "grid":
		rule.properties["display"] = "grid"
		return
	if utility_name == "inline-grid":
		rule.properties["display"] = "inline-grid"
		return

	# Flex direction
	match utility_name:
		"flex-row": rule.properties["flex-direction"] = "row"; return
		"flex-row-reverse": rule.properties["flex-direction"] = "row-reverse"; return
		"flex-col": rule.properties["flex-direction"] = "column"; return
		"flex-col-reverse": rule.properties["flex-direction"] = "column-reverse"; return

	# Flex wrap
	match utility_name:
		"flex-nowrap": rule.properties["flex-wrap"] = "nowrap"; return
		"flex-wrap": rule.properties["flex-wrap"] = "wrap"; return
		"flex-wrap-reverse": rule.properties["flex-wrap"] = "wrap-reverse"; return

	# Justify content
	match utility_name:
		"justify-start": rule.properties["justify-content"] = "flex-start"; return
		"justify-end": rule.properties["justify-content"] = "flex-end"; return
		"justify-center": rule.properties["justify-content"] = "center"; return
		"justify-between": rule.properties["justify-content"] = "space-between"; return
		"justify-around": rule.properties["justify-content"] = "space-around"; return
		"justify-evenly": rule.properties["justify-content"] = "space-evenly"; return

	# Align items
	match utility_name:
		"items-start": rule.properties["align-items"] = "flex-start"; return
		"items-end": rule.properties["align-items"] = "flex-end"; return
		"items-center": rule.properties["align-items"] = "center"; return
		"items-baseline": rule.properties["align-items"] = "baseline"; return
		"items-stretch": rule.properties["align-items"] = "stretch"; return

	# Align content
	match utility_name:
		"content-start": rule.properties["align-content"] = "flex-start"; return
		"content-end": rule.properties["align-content"] = "flex-end"; return
		"content-center": rule.properties["align-content"] = "center"; return
		"content-between": rule.properties["align-content"] = "space-between"; return
		"content-around": rule.properties["align-content"] = "space-around"; return
		"content-stretch": rule.properties["align-content"] = "stretch"; return

	# Gap
	if utility_name.begins_with("gap-"):
		var val = utility_name.substr(4)
		rule.properties["gap"] = SizeUtils.parse_size(val)
		return
	if utility_name.begins_with("row-gap-"):
		var val = utility_name.substr(8)
		rule.properties["row-gap"] = SizeUtils.parse_size(val)
		return
	if utility_name.begins_with("col-gap-"):
		var val = utility_name.substr(8)
		rule.properties["column-gap"] = SizeUtils.parse_size(val)
		return

	if utility_name.begins_with("grid-cols-"):
		var val = utility_name.substr(10)
		if val.is_valid_int():
			rule.properties["grid-template-columns"] = val.to_int()
		else:
			rule.properties["grid-template-columns"] = val
		return
	if utility_name.begins_with("grid-rows-"):
		var val = utility_name.substr(10)
		if val.is_valid_int():
			rule.properties["grid-template-rows"] = val.to_int()
		else:
			rule.properties["grid-template-rows"] = val
		return
	
	if utility_name.begins_with("col-span-"):
		var val = utility_name.substr(9)
		if val == "full":
			rule.properties["grid-column"] = "1 / -1"
		elif val.is_valid_int():
			rule.properties["grid-column"] = "span " + val
		return
	if utility_name.begins_with("row-span-"):
		var val = utility_name.substr(9)
		if val == "full":
			rule.properties["grid-row"] = "1 / -1"
		elif val.is_valid_int():
			rule.properties["grid-row"] = "span " + val
		return
	
	match utility_name:
		"grid-cols-1": rule.properties["grid-template-columns"] = 1; return
		"grid-cols-2": rule.properties["grid-template-columns"] = 2; return
		"grid-cols-3": rule.properties["grid-template-columns"] = 3; return
		"grid-cols-4": rule.properties["grid-template-columns"] = 4; return
		"grid-cols-5": rule.properties["grid-template-columns"] = 5; return
		"grid-cols-6": rule.properties["grid-template-columns"] = 6; return
		"grid-cols-12": rule.properties["grid-template-columns"] = 12; return
		"col-span-1": rule.properties["grid-column"] = "span 1"; return
		"col-span-2": rule.properties["grid-column"] = "span 2"; return
		"col-span-3": rule.properties["grid-column"] = "span 3"; return
		"col-span-4": rule.properties["grid-column"] = "span 4"; return
		"col-span-5": rule.properties["grid-column"] = "span 5"; return
		"col-span-6": rule.properties["grid-column"] = "span 6"; return
		"col-span-full": rule.properties["grid-column"] = "1 / -1"; return

	# FLEX ITEM PROPERTIES
	if utility_name.begins_with("flex-grow-"):
		var val = utility_name.substr(10)
		rule.properties["flex-grow"] = val.to_float()
		return
	if utility_name.begins_with("flex-shrink-"):
		var val = utility_name.substr(12)
		rule.properties["flex-shrink"] = val.to_float()
		return
	if utility_name.begins_with("basis-"):
		var val = utility_name.substr(6)
		rule.properties["flex-basis"] = SizeUtils.parse_size(val)
		return

	# Align self
	match utility_name:
		"self-auto": rule.properties["align-self"] = "auto"; return
		"self-start": rule.properties["align-self"] = "flex-start"; return
		"self-end": rule.properties["align-self"] = "flex-end"; return
		"self-center": rule.properties["align-self"] = "center"; return
		"self-stretch": rule.properties["align-self"] = "stretch"; return
		"self-baseline": rule.properties["align-self"] = "baseline"; return

	# Order
	if utility_name.begins_with("order-"):
		var val = utility_name.substr(6)
		rule.properties["order"] = val.to_int()
		return

	if utility_name == "rounded":
		rule.properties["border-radius"] = "4px"  # Default rounded
		return

	# Handle padding classes like p-8, px-4, py-2, p-[20px], etc.
	if utility_name.begins_with("p-[") and utility_name.ends_with("]"):
		var val = SizeUtils.extract_bracket_content(utility_name, 2)  # after 'p-'
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-left"] = padding_value
		rule.properties["padding-right"] = padding_value
		rule.properties["padding-top"] = padding_value
		rule.properties["padding-bottom"] = padding_value
		return
	if utility_name.begins_with("p-"):
		var val = utility_name.substr(2)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-left"] = padding_value
		rule.properties["padding-right"] = padding_value
		rule.properties["padding-top"] = padding_value
		rule.properties["padding-bottom"] = padding_value
		return
	if utility_name.begins_with("px-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-left"] = padding_value
		rule.properties["padding-right"] = padding_value
		return
	if utility_name.begins_with("py-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-top"] = padding_value
		rule.properties["padding-bottom"] = padding_value
		return
	if utility_name.begins_with("pt-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-top"] = padding_value
		return
	if utility_name.begins_with("pr-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-right"] = padding_value
		return
	if utility_name.begins_with("pb-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-bottom"] = padding_value
		return
	if utility_name.begins_with("pl-"):
		var val = utility_name.substr(3)
		var padding_value = SizeUtils.parse_size(val)
		rule.properties["padding-left"] = padding_value
		return

	# Handle border radius classes like rounded, rounded-lg, rounded-[12px]
	if utility_name == "rounded":
		rule.properties["border-radius"] = "4px"
		return
	if utility_name == "rounded-none":
		rule.properties["border-radius"] = "0px"
		return
	if utility_name == "rounded-sm":
		rule.properties["border-radius"] = "2px"
		return
	if utility_name == "rounded-md":
		rule.properties["border-radius"] = "6px"
		return
	if utility_name == "rounded-lg":
		rule.properties["border-radius"] = "8px"
		return
	if utility_name == "rounded-xl":
		rule.properties["border-radius"] = "12px"
		return
	if utility_name == "rounded-2xl":
		rule.properties["border-radius"] = "16px"
		return
	if utility_name == "rounded-3xl":
		rule.properties["border-radius"] = "24px"
		return
	if utility_name == "rounded-full":
		rule.properties["border-radius"] = "9999px"
		return
	
	# Handle custom border radius like rounded-[12px]
	if utility_name.begins_with("rounded-[") and utility_name.ends_with("]"):
		var radius_value = SizeUtils.extract_bracket_content(utility_name, 8)  # after 'rounded-'
		rule.properties["border-radius"] = radius_value
		return

	# Handle numeric border radius classes like rounded-8, rounded-12, etc.
	if utility_name.begins_with("rounded-"):
		var val = utility_name.substr(8)
		if val.is_valid_int():
			rule.properties["border-radius"] = str(int(val)) + "px"
			return

	# Handle margin classes like m-8, mx-4, my-2, m-[10px], etc.
	if utility_name.begins_with("m-[") and utility_name.ends_with("]"):
		var val = SizeUtils.extract_bracket_content(utility_name, 2)  # after 'm-'
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin"] = margin_value
		return
	if utility_name.begins_with("m-"):
		var val = utility_name.substr(2)
		if val == "auto":
			rule.properties["mx-auto"] = true
			rule.properties["my-auto"] = true
			return
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin"] = margin_value
		return
	if utility_name.begins_with("mx-"):
		var val = utility_name.substr(3)
		if val == "auto":
			rule.properties["mx-auto"] = true
			return
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin-left"] = margin_value
		rule.properties["margin-right"] = margin_value
		return
	if utility_name.begins_with("my-"):
		var val = utility_name.substr(3)
		if val == "auto":
			rule.properties["my-auto"] = true
			return
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin-top"] = margin_value
		rule.properties["margin-bottom"] = margin_value
		return
	if utility_name.begins_with("mt-"):
		var val = utility_name.substr(3)
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin-top"] = margin_value
		return
	if utility_name.begins_with("mr-"):
		var val = utility_name.substr(3)
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin-right"] = margin_value
		return
	if utility_name.begins_with("mb-"):
		var val = utility_name.substr(3)
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin-bottom"] = margin_value
		return
	if utility_name.begins_with("ml-"):
		var val = utility_name.substr(3)
		var margin_value = SizeUtils.parse_size(val)
		rule.properties["margin-left"] = margin_value
		return
	
	# Apply border properties
	var apply_border = func(side: String, width: String = "", color = null, style: String = "solid"):
		var prefix = "border" + ("-" + side if side != "" else "")
		if width != "":
			rule.properties[prefix + "-width"] = width
		if color != null:
			rule.properties[prefix + "-color"] = color
		if style != "":
			rule.properties[prefix + "-style"] = style
	
	# Handle border utilities
	if utility_name == "border":
		apply_border.call("", "1px", Color.BLACK)
		return
	
	if utility_name == "border-none":
		rule.properties["border-style"] = "none"
		return
	
	# Individual border sides - pattern: border-{side}-{value}
	var border_sides = ["t", "r", "b", "l"]
	var side_map = {"t": "top", "r": "right", "b": "bottom", "l": "left"}
	
	for side in border_sides:
		var short_side = side
		var full_side = side_map[side]
		
		# Basic side border (e.g., border-t)
		if utility_name == "border-" + short_side:
			apply_border.call(full_side, "1px")
			return
		
		# Side with value (e.g., border-t-2, border-t-red-500)
		if utility_name.begins_with("border-" + short_side + "-"):
			var val = utility_name.substr(9)  # after "border-X-"
			
			# Check for bracket notation first
			if utility_name.begins_with("border-" + short_side + "-[") and utility_name.ends_with("]"):
				var value = SizeUtils.extract_bracket_content(utility_name, 9)
				var parsed_color = ColorUtils.parse_color(value)
				if parsed_color != null:
					apply_border.call(full_side, "", parsed_color)
				else:
					apply_border.call(full_side, value)
				return
			
			# Check if it's a numeric width
			if val.is_valid_int():
				apply_border.call(full_side, str(int(val)) + "px")
				return
			
			# Check if it's a color
			var color = ColorUtils.get_color(val)
			if color != null:
				apply_border.call(full_side, "", color)
				return
	
	# General border width (e.g., border-2)
	if utility_name.begins_with("border-"):
		var val = utility_name.substr(7)
		
		# Custom border width like border-[2px]
		if utility_name.begins_with("border-[") and utility_name.ends_with("]"):
			var value = SizeUtils.extract_bracket_content(utility_name, 7)
			var parsed_color = ColorUtils.parse_color(value)
			if parsed_color != null:
				apply_border.call("", "", parsed_color)
			else:
				apply_border.call("", value)
			return
		
		# Numeric width
		if val.is_valid_int():
			apply_border.call("", str(int(val)) + "px")
			return
		
		# Color name
		var color = ColorUtils.get_color(val)
		if color != null:
			apply_border.call("", "", color)
			return

	# Handle cursor classes like cursor-pointer, cursor-default, cursor-text, etc.
	if utility_name.begins_with("cursor-"):
		var cursor_type = utility_name.substr(7)  # after 'cursor-'
		rule.properties["cursor"] = cursor_type
		return
	
	# Handle z-index classes like z-10, z-50, z-[999]
	if utility_name.begins_with("z-"):
		var val = utility_name.substr(2)
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
		rule.properties["z-index"] = val.to_int()
		return
	
	# Handle opacity classes like opacity-50, opacity-75, opacity-[0.5]
	if utility_name.begins_with("opacity-"):
		var val = utility_name.substr(8)  # after 'opacity-'
		if val.begins_with("[") and val.ends_with("]"):
			val = val.substr(1, val.length() - 2)
			rule.properties["opacity"] = val.to_float()
		elif val.is_valid_int():
			# Convert percentage (0-100) to decimal (0.0-1.0)
			rule.properties["opacity"] = val.to_int() / 100.0
		return

	# Handle object-fit classes for images
	match utility_name:
		"object-none": rule.properties["object-fit"] = "none"; return
		"object-fill": rule.properties["object-fit"] = "fill"; return
		"object-contain": rule.properties["object-fit"] = "contain"; return
		"object-cover": rule.properties["object-fit"] = "cover"; return

	if utility_name.begins_with("scale-") or utility_name.begins_with("scale-x-") or utility_name.begins_with("scale-y-"):
		var transform_properties = TransformUtils.parse_scale_utility(utility_name)
		for property in transform_properties:
			rule.properties[property] = transform_properties[property]
		return
	
	if utility_name.begins_with("rotate-") or utility_name.begins_with("rotate-x-") or utility_name.begins_with("rotate-y-"):
		var transform_properties = TransformUtils.parse_rotation_utility(utility_name)
		for property in transform_properties:
			rule.properties[property] = transform_properties[property]
		return
	
	if utility_name in ["transition", "transition-colors", "transition-opacity", "transition-transform"]:
		rule.properties[utility_name] = "200ms"
		return

	if utility_name == "hidden":
		rule.properties["display"] = "none"
		return

	# Handle more utility classes as needed
	# Add more cases here for other utilities

static func parse_inline_style(style_string: String) -> Dictionary:
	var rule = CSSRule.new()
	rule.selector = ""
	rule.init(rule.selector)
	
	var utility_classes = smart_split_utility_classes(style_string)
	for utility_name in utility_classes:
		utility_name = utility_name.strip_edges()
		if utility_name.is_empty():
			continue
		parse_utility_class_internal(rule, utility_name)
	
	return rule.properties

static func smart_split_utility_classes(style_string: String) -> Array[String]:
	var result: Array[String] = []
	var current_class = ""
	var bracket_depth = 0
	var in_brackets = false
	
	for i in range(style_string.length()):
		# char
		var c = style_string[i]
		
		if c == "[":
			bracket_depth += 1
			in_brackets = true
			current_class += c
		elif c == "]":
			bracket_depth -= 1
			if bracket_depth == 0:
				in_brackets = false
			current_class += c
		elif c == " " and not in_brackets:
			# Split here
			if current_class.strip_edges().length() > 0:
				result.append(current_class.strip_edges())
			current_class = ""
		else:
			current_class += c
	
	# Add the last class if any
	if current_class.strip_edges().length() > 0:
		result.append(current_class.strip_edges())
	
	return result
