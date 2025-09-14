extends Control

const BROWSER_TEXT = preload("res://Scenes/Styles/BrowserText.tres")

var _element: HTMLParser.HTMLElement
var _parser: HTMLParser

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	_element = element
	_parser = parser
	var option_button: OptionButton = $OptionButton
	
	var selected_index = -1
	var option_index = 0

	# find <option>s
	for child_element in element.children:
		if child_element.tag_name == "option":
			var option_text = child_element.text_content.strip_edges()
			var option_value = child_element.get_attribute("value")

			# If no value attribute is specified, use the text content as the value
			if option_value.is_empty():
				option_value = option_text
			
			option_button.add_item(option_text, option_index)
			option_button.set_item_metadata(option_index, option_value)
			
			# Check if this option is selected
			if child_element.has_attribute("selected") and selected_index == -1:
				selected_index = option_index
			
			# Check if this option is disabled
			option_button.set_item_disabled(option_index, child_element.has_attribute("disabled"))
			
			option_index += 1
	
	# Set the selected item
	if selected_index >= 0:
		option_button.selected = selected_index
	
	custom_minimum_size = option_button.size
	
	apply_select_styles(element, parser)
	
	parser.register_dom_node(element, option_button)


func apply_select_styles(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	if not element or not parser:
		return
	
	StyleManager.apply_element_styles(self, element, parser)
	
	var normal_styles = parser.get_element_styles_with_inheritance(element, "", [])
	var hover_styles = parser.get_element_styles_with_inheritance(element, "hover", [])
	var active_styles = parser.get_element_styles_with_inheritance(element, "active", [])

	var option_button: OptionButton = $OptionButton
	
	apply_select_text_colors(option_button, normal_styles, hover_styles, active_styles)
	apply_select_background_styles(option_button, normal_styles, hover_styles, active_styles)
	
	if normal_styles.has("width"):
		if normal_styles["width"] == "100%":
			size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			var width = StyleManager.parse_size(normal_styles["width"])
			if width:
				custom_minimum_size.x = width
				option_button.custom_minimum_size.x = width
				size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				option_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func apply_select_text_colors(option_button: OptionButton, normal_styles: Dictionary, hover_styles: Dictionary, active_styles: Dictionary) -> void:
	var normal_color = normal_styles.get("color", Color.WHITE)
	var hover_color = hover_styles.get("color", normal_color)
	var active_color = active_styles.get("color", hover_color)
	
	option_button.add_theme_color_override("font_color", normal_color)
	option_button.add_theme_color_override("font_hover_color", hover_color)
	option_button.add_theme_color_override("font_pressed_color", active_color)
	option_button.add_theme_color_override("font_hover_pressed_color", active_color)
	option_button.add_theme_color_override("font_focus_color", normal_color)

func apply_select_background_styles(option_button: OptionButton, normal_styles: Dictionary, hover_styles: Dictionary, active_styles: Dictionary) -> void:
	var normal_merged = normal_styles.duplicate()
	var hover_merged = normal_styles.duplicate()
	var active_merged = normal_styles.duplicate()
	
	for key in hover_styles:
		hover_merged[key] = hover_styles[key]
	
	for key in active_styles:
		active_merged[key] = active_styles[key]
	
	if BackgroundUtils.needs_background_wrapper(normal_merged):
		var normal_stylebox = create_select_stylebox(normal_merged)
		option_button.add_theme_stylebox_override("normal", normal_stylebox)
		
	if BackgroundUtils.needs_background_wrapper(hover_merged):
		var hover_stylebox = create_select_stylebox(hover_merged)
		option_button.add_theme_stylebox_override("hover", hover_stylebox)
		
	if BackgroundUtils.needs_background_wrapper(active_merged):
		var active_stylebox = create_select_stylebox(active_merged)
		option_button.add_theme_stylebox_override("pressed", active_stylebox)

func create_select_stylebox(styles: Dictionary) -> StyleBoxFlat:
	var style_box = BackgroundUtils.create_stylebox_from_styles(styles)
	
	var has_left_padding = styles.has("padding") or styles.has("padding-left")
	var has_right_padding = styles.has("padding") or styles.has("padding-right")
	var has_top_padding = styles.has("padding") or styles.has("padding-top")
	var has_bottom_padding = styles.has("padding") or styles.has("padding-bottom")
	
	if not has_left_padding:
		style_box.content_margin_left = 5.0
	if not has_right_padding:
		style_box.content_margin_right = 20.0 # More space for dropdown arrow
	if not has_top_padding:
		style_box.content_margin_top = 2.0
	if not has_bottom_padding:
		style_box.content_margin_bottom = 2.0
	
	return style_box
