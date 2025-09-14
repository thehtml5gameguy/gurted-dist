class_name BaseListContainer
extends VBoxContainer

const BROWSER_TEXT = preload("res://Scenes/Styles/BrowserText.tres")

var list_type: String
var marker_width: float
var parser_ref: HTMLParser = null
var is_ordered: bool = false

func _ready():
	child_entered_tree.connect(_on_child_added)
	child_exiting_tree.connect(_on_child_removed)

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	list_type = element.get_attribute("type").to_lower()
	if list_type == "": 
		list_type = "disc" if not is_ordered else "decimal"
	parser_ref = parser
	
	marker_width = await calculate_marker_width(element)
	
	var index = 1
	for child_element in element.children:
		if child_element.tag_name == "li":
			var li_node = create_li_node(child_element, index, parser)
			if li_node:
				add_child(li_node)
			index += 1

func calculate_marker_width(element: HTMLParser.HTMLElement) -> float:
	var temp_label = RichTextLabel.new()
	temp_label.bbcode_enabled = true
	temp_label.fit_content = true
	temp_label.scroll_active = false
	temp_label.theme = BROWSER_TEXT
	add_child(temp_label)
	
	var sample_text = ""
	if is_ordered:
		var item_count = 0
		for child_element in element.children:
			if child_element.tag_name == "li":
				item_count += 1
		sample_text = str(item_count) + "." 
	else:
		match list_type:
			"circle":
				sample_text = "◦"
			"disc":
				sample_text = "•"
			"square":
				sample_text = "■"
			"none":
				sample_text = " "
			_:
				sample_text = "•"
	
	StyleManager.apply_styles_to_label(temp_label, {}, null, null, sample_text)
	
	await get_tree().process_frame
	
	var width = temp_label.get_content_width() + 5
	
	remove_child(temp_label)
	temp_label.queue_free()
	
	return max(width, 20.0 if not is_ordered else 30.0)

func create_li_node(element: HTMLParser.HTMLElement, index: int, parser: HTMLParser) -> Control:
	var li_container = HBoxContainer.new()
	
	# Create marker
	var marker_label = RichTextLabel.new()
	marker_label.custom_minimum_size = Vector2(marker_width, 0)
	marker_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	marker_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marker_label.bbcode_enabled = true
	marker_label.fit_content = true
	marker_label.scroll_active = false
	marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker_label.theme = BROWSER_TEXT
	
	var marker_text = get_marker_text(index)
	var marker_styles = parser.get_element_styles_with_inheritance(element, "", []) if parser else {}
	StyleManager.apply_styles_to_label(marker_label, marker_styles, element, parser, marker_text)
	
	# Create content
	var content_label = RichTextLabel.new()
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_label.bbcode_enabled = true
	content_label.fit_content = true
	content_label.scroll_active = false
	content_label.theme = BROWSER_TEXT
	
	var content_text = element.get_bbcode_formatted_text(parser)
	var content_styles = parser.get_element_styles_with_inheritance(element, "", []) if parser else {}
	StyleManager.apply_styles_to_label(content_label, content_styles, element, parser, content_text)
	
	li_container.add_theme_constant_override("separation", 0)
	li_container.add_child(marker_label)
	li_container.add_child(content_label)
	
	# Store element metadata on the container for renumbering
	li_container.set_meta("html_element", element)
	
	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	if BackgroundUtils.needs_background_wrapper(styles):
		var panel_container = BackgroundUtils.create_panel_container_with_background(styles)
		panel_container.name = "Li"
		# Store element metadata on the panel container too
		panel_container.set_meta("html_element", element)
		# Get the VBoxContainer inside PanelContainer and replace it with our HBoxContainer
		var vbox = panel_container.get_child(0)
		panel_container.remove_child(vbox)
		vbox.queue_free()
		panel_container.add_child(li_container)
		return panel_container
	else:
		return li_container

func _on_child_added(child: Node):
	if child.has_meta("html_element"):
		var element = child.get_meta("html_element")
		if element is HTMLParser.HTMLElement and element.tag_name == "li":

			call_deferred("_process_dynamic_li", child, element)

func _process_dynamic_li(child: Node, element: HTMLParser.HTMLElement):
	child_entered_tree.disconnect(_on_child_added)
	
	# Get the correct index for this new item
	var current_li_count = 0
	for existing_child in get_children():
		if existing_child != child:
			current_li_count += 1
	
	# Remove the basic li node and replace with properly formatted one
	if child.get_parent() == self:
		remove_child(child)
		var li_node = create_li_node(element, current_li_count + 1, parser_ref)
		if li_node:
			var element_id = element.get_attribute("id")
			if parser_ref and element_id:
				parser_ref.parse_result.dom_nodes[element_id] = li_node
			add_child(li_node)
		child.queue_free()
	
	# Reconnect signal
	child_entered_tree.connect(_on_child_added)

func _on_child_removed(_child: Node):
	if is_ordered:  # Only OL needs renumbering
		call_deferred("_renumber_list")

func _renumber_list():
	# Temporarily disconnect signals to avoid recursion
	child_entered_tree.disconnect(_on_child_added)
	child_exiting_tree.disconnect(_on_child_removed)
	
	# Get all current li children
	var li_children = []
	for child in get_children():
		var is_li = false
		if child is HBoxContainer:
			is_li = true
		elif child is PanelContainer and child.get_child_count() > 0:
			var inner_child = child.get_child(0)
			if inner_child is HBoxContainer:
				is_li = true
		
		if is_li:
			li_children.append(child)
	
	# Renumber all existing items
	for i in range(li_children.size()):
		var child = li_children[i]
		var marker_label = null
		
		# Find the marker label within the child structure
		if child is HBoxContainer and child.get_child_count() > 0:
			marker_label = child.get_child(0)
		elif child is PanelContainer and child.get_child_count() > 0:
			var hbox = child.get_child(0)
			if hbox is HBoxContainer and hbox.get_child_count() > 0:
				marker_label = hbox.get_child(0)
		
		# Update the marker text - recreate it completely to avoid BBCode corruption
		if marker_label and marker_label is RichTextLabel:
			var index = i + 1
			var new_marker_text = get_marker_text(index)
			# Get the HTMLElement from the li container to reapply styles properly
			var element = null
			if child.has_meta("html_element"):
				element = child.get_meta("html_element")
			elif child is PanelContainer and child.get_child_count() > 0:
				var hbox = child.get_child(0)
				if hbox.has_meta("html_element"):
					element = hbox.get_meta("html_element")
			
			if element and parser_ref:
				var marker_styles = parser_ref.get_element_styles_with_inheritance(element, "", [])
				StyleManager.apply_styles_to_label(marker_label, marker_styles, element, parser_ref, new_marker_text)
			else:
				# Fallback - just set the text
				marker_label.text = new_marker_text
	
	# Reconnect signals
	child_entered_tree.connect(_on_child_added)
	child_exiting_tree.connect(_on_child_removed)

func refresh_list():
	# Force refresh of all li children for dynamically added content
	var children_to_process = []
	for child in get_children():
		if child.has_meta("html_element"):
			var element = child.get_meta("html_element")
			if element is HTMLParser.HTMLElement and element.tag_name == "li":
				children_to_process.append([child, element])
	
	# Clear all children first
	for child_data in children_to_process:
		var child = child_data[0]
		remove_child(child)
		child.queue_free()
	
	# Recalculate marker width if needed
	var new_count = children_to_process.size()
	if new_count > 0 and is_ordered:
		marker_width = await calculate_marker_width(children_to_process[0][1])
		
	# Re-add with correct indices
	for i in range(children_to_process.size()):
		var element = children_to_process[i][1]
		var li_node = create_li_node(element, i + 1, parser_ref)
		if li_node:
			add_child(li_node)

func int_to_roman(num: int) -> String:
	var values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	var result = ""
	
	for i in range(values.size()):
		while num >= values[i]:
			result += symbols[i]
			num -= values[i]
	
	return result

func get_marker_text(index: int) -> String:
	if is_ordered:
		match list_type:
			"decimal":
				return str(index) + "."
			"zero-lead":
				return "%02d." % index
			"lower-alpha":
				return char(96 + index) + "."
			"lower-roman":
				return int_to_roman(index).to_lower() + "."
			"upper-alpha":
				return char(64 + index) + "."
			"upper-roman":
				return int_to_roman(index) + "."
			"none":
				return ""
			_:
				return str(index) + "."
	else:
		match list_type:
			"circle":
				return "◦"
			"disc":
				return "•"
			"square":
				return "■"
			"none":
				return " "
			_:
				return "•"
