extends VBoxContainer

var form_element: HTMLParser.HTMLElement
var form_parser: HTMLParser

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	form_element = element
	form_parser = parser
	
	parser.register_dom_node(element, self)

func submit_form() -> Dictionary:
	var form_data = {}
	
	if not form_element:
		return form_data
	
	var form_inputs = collect_form_elements(form_element)
	
	for input_element in form_inputs:
		# Use 'key' attribute as primary identifier for form field mapping
		var key_attr = input_element.get_attribute("key")
		var name_attr = input_element.get_attribute("name")
		var id_attr = input_element.get_attribute("id")
		
		# Priority: key > name > id > tag_name
		var key = key_attr if not key_attr.is_empty() else name_attr if not name_attr.is_empty() else id_attr if not id_attr.is_empty() else input_element.tag_name
		
		# Get the DOM node for this element
		if form_parser:
			var element_id = input_element.get_attribute("id")
			if element_id.is_empty():
				element_id = input_element.tag_name
			var dom_node = form_parser.parse_result.dom_nodes.get(element_id, null)
			if dom_node:
				var value = get_input_value(input_element.tag_name, dom_node)
				if value != null:
					form_data[key] = value
	
	return form_data

func collect_form_elements(element: HTMLParser.HTMLElement) -> Array:
	var form_inputs = []
	
	# Check if current element is an input element
	if element.tag_name in ["input", "textarea", "select"]:
		form_inputs.append(element)
	
	# Recursively check children
	for child in element.children:
		form_inputs.append_array(collect_form_elements(child))
	
	return form_inputs

func get_input_value(tag_name: String, dom_node: Node):
	match tag_name:
		"input":
			if dom_node.has_method("get_text"):
				return dom_node.get_text()
			elif dom_node.has_method("is_pressed"):
				return dom_node.is_pressed()
			elif dom_node is ColorPickerButton:
				return "#" + dom_node.color.to_html()
			elif dom_node is SpinBox:
				return dom_node.value
			elif dom_node is HSlider:
				return dom_node.value
		"textarea":
			if dom_node is TextEdit:
				return dom_node.text
		"select":
			if dom_node is OptionButton:
				return dom_node.get_item_metadata(dom_node.selected)
	
	return null
