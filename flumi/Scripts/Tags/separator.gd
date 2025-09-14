extends Control

var separator_node: Separator

func init(element: HTMLParser.HTMLElement, _parser: HTMLParser) -> void:
	var direction = element.get_attribute("direction")

	if direction == "vertical":
		separator_node = VSeparator.new()
		separator_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
		separator_node.custom_minimum_size.x = 2
		separator_node.layout_mode = 1
		separator_node.anchors_preset = Control.PRESET_LEFT_WIDE
	else:
		separator_node = HSeparator.new()
		separator_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		separator_node.custom_minimum_size.y = 2
		separator_node.layout_mode = 1
		separator_node.anchors_preset = Control.PRESET_FULL_RECT
	
	add_child(separator_node)
	
	# Make the parent control also expand to fill available space
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if direction == "vertical":
		size_flags_vertical = Control.SIZE_EXPAND_FILL
