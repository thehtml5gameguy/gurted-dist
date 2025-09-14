extends Control
static var button_groups: Dictionary = {}

const BROWSER_TEXT: Theme = preload("res://Scenes/Styles/BrowserText.tres")

var custom_hex_input: LineEdit
var _file_text_content: String = ""
var _file_binary_content: PackedByteArray = PackedByteArray()
var _file_info: Dictionary = {}
var _element: HTMLParser.HTMLElement
var _parser: HTMLParser

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	_element = element
	_parser = parser
	var color_picker_button: ColorPickerButton = $ColorPickerButton
	var picker: ColorPicker = color_picker_button.get_picker()

	picker.sliders_visible = false
	picker.presets_visible = false
	picker.color_modes_visible = false
	picker.hex_visible = false

	# Create custom hex input
	custom_hex_input = LineEdit.new()
	custom_hex_input.placeholder_text = "#RRGGBB"
	
	# Apply custom unique theme
	var picker_theme = BROWSER_TEXT.duplicate()
	picker_theme.set_color("font_color", "LineEdit", Color.WHITE)
	picker_theme.set_color("font_placeholder_color", "LineEdit", Color(1, 1, 1, 0.6))
	picker_theme.set_color("caret_color", "LineEdit", Color.WHITE)

	var normal_style = picker_theme.get_stylebox("normal", "LineEdit").duplicate()
	var focus_style = picker_theme.get_stylebox("focus", "LineEdit").duplicate()
	normal_style.border_color = Color.WHITE
	focus_style.border_color = Color.WHITE
	picker_theme.set_stylebox("normal", "LineEdit", normal_style)
	picker_theme.set_stylebox("focus", "LineEdit", focus_style)

	custom_hex_input.theme = picker_theme
	picker.add_child(custom_hex_input)

	# Connect signals for two-way binding of Hex
	picker.color_changed.connect(_on_picker_color_changed)
	custom_hex_input.text_submitted.connect(_on_custom_hex_submitted)
	# Set initial hex value
	_on_picker_color_changed(picker.color)

	picker.theme = picker_theme
	color_picker_button.get_popup().theme = picker_theme

	var input_type = element.get_attribute("type").to_lower()
	var placeholder = element.get_attribute("placeholder")
	var value = element.get_attribute("value")
	var group = element.get_attribute("group")
	var minlength = element.get_attribute("minlength")
	var maxlength = element.get_attribute("maxlength")
	var pattern = element.get_attribute("pattern")
	var min_attr = element.get_attribute("min")
	var max_attr = element.get_attribute("max")
	var step_attr = element.get_attribute("step")
	var accept = element.get_attribute("accept")

	# Define which child should be active for each input type
	var active_child_map = {
		"checkbox": "CheckBox",
		"radio": "CheckBox", 
		"color": "ColorPickerButton",
		"password": "LineEdit",
		"date": "DateButton",
		"range": "HSlider",
		"number": "SpinBox",
		"file": "FileContainer"
	}
	
	var active_child_name = active_child_map.get(input_type, "LineEdit")
	remove_unused_children(active_child_name)
	
	if not has_node(active_child_name):
		return
	
	var active_child = get_node(active_child_name)
	active_child.visible = true

	match input_type:
		"checkbox":
			var checkbox = active_child as CheckBox
			if value and value == "true": 
				checkbox.button_pressed = true
				
		"radio":
			var radio = active_child as CheckBox
			radio.toggle_mode = true
			if value and value == "true": 
				radio.button_pressed = true
			
			if group.length() > 0:
				if not button_groups.has(group):
					button_groups[group] = ButtonGroup.new()
				radio.button_group = button_groups[group]
				
		"color":
			var color_button = active_child as ColorPickerButton
			if value and value.length() > 0:
				var color = Color.from_string(value, Color.WHITE)
				color_button.color = color
				
		"password":
			var line_edit = active_child as LineEdit
			line_edit.secret = true
			setup_text_input(line_edit, placeholder, value, minlength, maxlength, pattern)
			
		"date":
			var date_button = active_child as DateButton
			if value and value.length() > 0:
				date_button.init_with_date(value)
			else:
				date_button.init()
		
		"range":
			var slider = active_child as HSlider
			setup_range_input(slider, value, min_attr, max_attr, step_attr)
		
		"number":
			var spin_box = active_child as SpinBox
			setup_number_input(spin_box, value, min_attr, max_attr, step_attr, placeholder)
		
		"file":
			var file_container = active_child as Control
			setup_file_input(file_container, accept)
			
		_: # Default case (text input)
			var line_edit = active_child as LineEdit
			line_edit.secret = false
			setup_text_input(line_edit, placeholder, value, minlength, maxlength, pattern)
	
	apply_input_styles(element, parser)
	
	# Handle disabled and readonly attributes
	if element.has_attribute("disabled"):
		active_child.set("disabled", true)
	if element.has_attribute("readonly") and active_child.has_method("set_editable"):
		active_child.set_editable(false)
	
	# Enable focus mode for text inputs to support change events on focus lost
	if active_child is LineEdit:
		active_child.focus_mode = Control.FOCUS_ALL
	
	if input_type == "file":
		var file_dialog = active_child.get_node("FileDialog")
		parser.register_dom_node(element, file_dialog)
	elif input_type == "date":
		parser.register_dom_node(element, active_child)
	else:
		parser.register_dom_node(element, active_child)
	
	if active_child is LineEdit:
		active_child.focus_entered.connect(_on_input_focus_entered)
		active_child.focus_exited.connect(_on_input_focus_exited)
	elif active_child is SpinBox:
		var line_edit = active_child.get_line_edit()
		if line_edit:
			line_edit.focus_entered.connect(_on_input_focus_entered)
			line_edit.focus_exited.connect(_on_input_focus_exited)

func remove_unused_children(keep_child_name: String) -> void:
	for child in get_children():
		if child.name != keep_child_name:
			child.visible = false
			child.queue_free()
		else:
			child.visible = true

func setup_text_input(line_edit: LineEdit, placeholder: String, value: String, minlength: String, maxlength: String, pattern: String) -> void:
	if placeholder: line_edit.placeholder_text = placeholder
	if value: line_edit.text = value

	line_edit.max_length = maxlength.to_int()

	if minlength.length() > 0 or pattern.length() > 0:
		line_edit.text_changed.connect(_on_text_changed.bind(minlength, pattern))

func _on_text_changed(new_text: String, minlength: String, pattern: String) -> void:
	var line_edit = get_node("LineEdit") as LineEdit
	var is_valid = true

	if minlength.length() > 0 and minlength.is_valid_int():
		var min_len = minlength.to_int()
		if new_text.length() < min_len and new_text.length() > 0:
			is_valid = false

	if pattern.length() > 0 and new_text.length() > 0:
		var regex = RegEx.new()
		if regex.compile(pattern) == OK:
			if not regex.search(new_text):
				is_valid = false

	if is_valid:
		if line_edit.has_focus():
			apply_active_styles()
		else:
			apply_normal_styles()
	else:
		var normal_style = get_current_or_create_style(line_edit, "normal")
		var focus_style = get_current_or_create_style(line_edit, "focus")
		
		normal_style.border_color = Color.RED
		normal_style.border_width_left = max(normal_style.border_width_left, 2)
		normal_style.border_width_right = max(normal_style.border_width_right, 2)
		normal_style.border_width_top = max(normal_style.border_width_top, 2)
		normal_style.border_width_bottom = max(normal_style.border_width_bottom, 2)
		
		focus_style.border_color = Color.RED
		focus_style.border_width_left = max(focus_style.border_width_left, 2)
		focus_style.border_width_right = max(focus_style.border_width_right, 2)
		focus_style.border_width_top = max(focus_style.border_width_top, 2)
		focus_style.border_width_bottom = max(focus_style.border_width_bottom, 2)

		line_edit.add_theme_stylebox_override("normal", normal_style)
		line_edit.add_theme_stylebox_override("focus", focus_style)

func get_current_or_create_style(line_edit: LineEdit, style_name: String) -> StyleBoxFlat:
	if line_edit.has_theme_stylebox_override(style_name):
		var current_style = line_edit.get_theme_stylebox(style_name)
		if current_style is StyleBoxFlat:
			return (current_style as StyleBoxFlat).duplicate()
	
	var theme_style = line_edit.get_theme_stylebox(style_name)
	if theme_style is StyleBoxFlat:
		return (theme_style as StyleBoxFlat).duplicate()
	
	return StyleBoxFlat.new()

func create_red_border_style_from_theme(line_edit: LineEdit, style_name: String) -> StyleBoxFlat:
	var original_style: StyleBoxFlat = line_edit.get_theme_stylebox(style_name)
	var style: StyleBoxFlat = original_style.duplicate()
	style.border_color = Color.RED
	return style

func _on_picker_color_changed(new_color: Color) -> void:
	var hex_string = "#" + new_color.to_html(false)
	custom_hex_input.text = hex_string

func _on_custom_hex_submitted(new_text: String) -> void:
	var cleaned_text = new_text.strip_edges()
	if not cleaned_text.begins_with("#"):
		cleaned_text = "#" + cleaned_text
	
	var new_color = Color.from_string(cleaned_text, Color.WHITE)
	
	var picker = ($ColorPickerButton as ColorPickerButton).get_picker()
	picker.set_pick_color(new_color)
	$ColorPickerButton.color = new_color

func setup_range_input(slider: HSlider, value: String, min_attr: String, max_attr: String, step_attr: String) -> void:
	var min_val = min_attr.to_float() if min_attr.length() > 0 else 0.0
	var max_val = max_attr.to_float() if max_attr.length() > 0 else 100.0
	var step_val = step_attr.to_float() if step_attr.length() > 0 else 1.0
	
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = value.to_float() if value.length() > 0 else min_val

func setup_number_input(spin_box: SpinBox, value: String, min_attr: String, max_attr: String, step_attr: String, placeholder: String) -> void:
	var min_val = min_attr.to_float() if min_attr.length() > 0 else -99999.0
	var max_val = max_attr.to_float() if max_attr.length() > 0 else 99999.0
	var step_val = step_attr.to_float() if step_attr.length() > 0 else 1.0
	
	spin_box.min_value = min_val
	spin_box.max_value = max_val
	spin_box.step = step_val
	spin_box.value = value.to_float() if value.length() > 0 else min_val
	
	var line_edit = spin_box.get_line_edit()
	line_edit.placeholder_text = placeholder

func setup_file_input(file_container: Control, accept: String = "") -> void:
	var file_button = file_container.get_node("FileButton") as Button
	var file_label = file_container.get_node("FileLabel") as Label
	var file_dialog = file_container.get_node("FileDialog") as FileDialog
	
	if accept.length() > 0:
		setup_file_filters(file_dialog, accept)
	
	file_button.pressed.connect(_on_file_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	file_label.text = "No file chosen"

func setup_file_filters(file_dialog: FileDialog, accept: String) -> void:
	file_dialog.clear_filters()
	
	var filters = accept.split(",")
	var image_extensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp", "svg"]
	var audio_extensions = ["mp3", "wav", "ogg", "m4a", "flac"]
	var video_extensions = ["mp4", "avi", "mov", "wmv", "flv", "webm"]
	
	for filter in filters:
		filter = filter.strip_edges()
		
		if filter == "image/*":
			for ext in image_extensions:
				file_dialog.add_filter("*." + ext, "Image Files")
		elif filter == "audio/*":
			for ext in audio_extensions:
				file_dialog.add_filter("*." + ext, "Audio Files")
		elif filter == "video/*":
			for ext in video_extensions:
				file_dialog.add_filter("*." + ext, "Video Files")
		elif filter.begins_with("."):
			# Individual file extension
			var ext = filter.substr(1)
			file_dialog.add_filter("*" + filter, ext.to_upper() + " Files")
		elif filter.contains("/"):
			# MIME type - convert to common extensions
			match filter:
				"text/plain":
					file_dialog.add_filter("*.txt", "Text Files")
				"application/pdf":
					file_dialog.add_filter("*.pdf", "PDF Files")
				"application/json":
					file_dialog.add_filter("*.json", "JSON Files")
				"text/html":
					file_dialog.add_filter("*.html", "HTML Files")
				"text/css":
					file_dialog.add_filter("*.css", "CSS Files")
				"application/javascript":
					file_dialog.add_filter("*.js", "JavaScript Files")

	# If no valid filters were added, allow all files
	if file_dialog.filters.size() == 0:
		file_dialog.add_filter("*", "All Files")

func _on_file_button_pressed() -> void:
	var file_dialog = get_node("FileContainer/FileDialog") as FileDialog
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String) -> void:
	var file_label = get_node("FileContainer/FileLabel") as Label
	var file_name = path.get_file()
	file_label.text = file_name
	
	_process_file_data(path)

func _process_file_data(file_path: String) -> void:
	var file_name = file_path.get_file()
	var file_extension = file_path.get_extension().to_lower()
	var file_size = 0
	var mime_type = _get_mime_type(file_extension)
	var is_image = _is_image_file(file_extension)
	var is_text = _is_text_file(file_extension)
	
	# Read file contents
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		file_size = file.get_length()
		_file_binary_content = file.get_buffer(file.get_length())
		file.close()
	
	_file_info = {
		"fileName": file_name,
		"size": file_size,
		"type": mime_type,
		"binary": _file_binary_content,
		"isImage": is_image,
		"isText": is_text
	}
	
	# Add text content only for text files
	if is_text:
		_file_text_content = _file_binary_content.get_string_from_utf8()
		_file_info["text"] = _file_text_content
	
	# Add base64 data URL for images
	if is_image:
		var base64_data = Marshalls.raw_to_base64(_file_binary_content)
		_file_info["dataURL"] = "data:" + mime_type + ";base64," + base64_data

func get_file_info() -> Dictionary:
	return _file_info

func _get_mime_type(extension: String) -> String:
	match extension:
		"png": return "image/png"
		"jpg", "jpeg": return "image/jpeg" 
		"gif": return "image/gif"
		"webp": return "image/webp"
		"svg": return "image/svg+xml"
		"bmp": return "image/bmp"
		"txt": return "text/plain"
		"html", "htm": return "text/html"
		"css": return "text/css"
		"js": return "application/javascript"
		"json": return "application/json"
		"pdf": return "application/pdf"
		"mp3": return "audio/mpeg"
		"wav": return "audio/wav"
		"ogg": return "audio/ogg"
		"mp4": return "video/mp4"
		"avi": return "video/x-msvideo"
		"mov": return "video/quicktime"
		_: return "application/octet-stream"

func _is_image_file(extension: String) -> bool:
	return extension in ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp"]

func _is_text_file(extension: String) -> bool:
	return extension in ["txt", "html", "htm", "css", "js", "json", "xml", "csv", "md", "gd"]

func apply_input_styles(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	if not element or not parser:
		return
	
	StyleManager.apply_element_styles(self, element, parser)
	
	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	
	# Apply text color to the active input control
	var active_child = null
	for child in get_children():
		if child.visible:
			active_child = child
			break
	
	if active_child:
		# Apply text color
		if styles.has("color"):
			var text_color = styles["color"] as Color
			if active_child is LineEdit:
				active_child.add_theme_color_override("font_color", text_color)
				active_child.add_theme_color_override("caret_color", text_color)
				# Also set placeholder color with reduced opacity
				var placeholder_color = Color(text_color.r, text_color.g, text_color.b, text_color.a * 0.6)
				active_child.add_theme_color_override("font_placeholder_color", placeholder_color)
			elif active_child is SpinBox:
				active_child.add_theme_color_override("font_color", text_color)
				# Also apply to the LineEdit inside SpinBox
				var line_edit = active_child.get_line_edit()
				if line_edit:
					line_edit.add_theme_color_override("font_color", text_color)
					line_edit.add_theme_color_override("caret_color", text_color)
					var placeholder_color = Color(text_color.r, text_color.g, text_color.b, text_color.a * 0.6)
					line_edit.add_theme_color_override("font_placeholder_color", placeholder_color)
		
		if styles.has("font-size"):
			var font_size = int(styles["font-size"])
			if active_child is LineEdit:
				active_child.add_theme_font_size_override("font_size", font_size)
			elif active_child is SpinBox:
				active_child.add_theme_font_size_override("font_size", font_size)
				var line_edit = active_child.get_line_edit()
				if line_edit:
					line_edit.add_theme_font_size_override("font_size", font_size)
		
		# Apply stylebox for borders, background, padding, etc.
		if BackgroundUtils.needs_background_wrapper(styles) or active_child is SpinBox:
			apply_stylebox_to_input(active_child, styles)
	
	var width = null
	var height = null
	
	if styles.has("width"):
		width = SizingUtils.parse_size_value(styles["width"])

	if styles.has("height"):
		height = SizingUtils.parse_size_value(styles["height"])
	
	if active_child:
		if width or height:
			# Explicit sizing from CSS
			var new_width = active_child.custom_minimum_size.x
			var new_height = max(active_child.custom_minimum_size.y, active_child.size.y)
			
			if width:
				if typeof(width) == TYPE_STRING and (width == "100%" or width == "full"):
					active_child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					size_flags_horizontal = Control.SIZE_EXPAND_FILL
					new_width = 0
				elif typeof(width) == TYPE_STRING and SizingUtils.is_percentage(width):
					new_width = SizingUtils.calculate_percentage_size(width, SizingUtils.DEFAULT_VIEWPORT_WIDTH)
				else:
					new_width = width
			
			if height:
				if typeof(height) == TYPE_STRING and SizingUtils.is_percentage(height):
					new_height = SizingUtils.calculate_percentage_size(height, SizingUtils.DEFAULT_VIEWPORT_HEIGHT)
				else:
					new_height = height
			
			var new_child_size = Vector2(new_width, new_height)
			
			active_child.custom_minimum_size = new_child_size
			
			if width and not (typeof(width) == TYPE_STRING and (width == "100%" or width == "full")):
				active_child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			if height:
				active_child.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			
			if active_child.size.x < new_child_size.x or (new_child_size.y > 0 and active_child.size.y < new_child_size.y):
				active_child.size = new_child_size
			
			custom_minimum_size = new_child_size
			
			# Root Control adjusts size flags to match child
			if width and not (typeof(width) == TYPE_STRING and (width == "100%" or width == "full")):
				size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			else:
				size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if height:
				size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			else:
				size_flags_vertical = Control.SIZE_SHRINK_CENTER
		else:
			# No explicit CSS sizing - sync root Control with child's natural size
			var child_natural_size = active_child.get_combined_minimum_size()
			if child_natural_size == Vector2.ZERO:
				child_natural_size = active_child.size
			
			custom_minimum_size = child_natural_size
			size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  
			size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		if active_child.name == "DateButton":
			active_child.anchors_preset = Control.PRESET_TOP_LEFT
			active_child.position = Vector2.ZERO

func _on_input_focus_entered() -> void:
	apply_active_styles()

func _on_input_focus_exited() -> void:
	apply_normal_styles()

func apply_active_styles() -> void:
	if not _element or not _parser:
		return
	
	# Get both normal and active styles, then merge them
	var normal_styles = _parser.get_element_styles_with_inheritance(_element, "", [])
	var active_styles = _parser.get_element_styles_with_inheritance(_element, "active", [])
	
	
	# Merge normal styles with active styles (active styles override normal)
	var merged_styles = normal_styles.duplicate()
	for key in active_styles:
		merged_styles[key] = active_styles[key]
	
	
	# Find the active input control
	var active_child = null
	for child in get_children():
		if child.visible:
			active_child = child
			break
	
	if not active_child:
		return
	
	if BackgroundUtils.needs_background_wrapper(merged_styles):
		apply_stylebox_to_input(active_child, merged_styles)
	elif active_child is SpinBox:
		apply_stylebox_to_input(active_child, merged_styles)

func apply_normal_styles() -> void:
	if not _element or not _parser:
		return
	
	var normal_styles = _parser.get_element_styles_with_inheritance(_element, "", [])
	
	var active_child = null
	for child in get_children():
		if child.visible:
			active_child = child
			break
	
	if not active_child:
		return
	
	if BackgroundUtils.needs_background_wrapper(normal_styles):
		apply_stylebox_to_input(active_child, normal_styles)
	elif active_child is SpinBox:
		apply_stylebox_to_input(active_child, normal_styles)
	else:
		if active_child is LineEdit:
			active_child.remove_theme_stylebox_override("normal")
			active_child.remove_theme_stylebox_override("focus")
		elif active_child is SpinBox:
			active_child.remove_theme_stylebox_override("normal")
			active_child.remove_theme_stylebox_override("updown")
			var line_edit = active_child.get_line_edit()
			if line_edit:
				line_edit.remove_theme_stylebox_override("normal")
				line_edit.remove_theme_stylebox_override("focus")
		elif active_child is Button:
			active_child.remove_theme_stylebox_override("normal")

func apply_stylebox_to_input(control: Control, styles: Dictionary) -> void:
	var style_box = BackgroundUtils.create_stylebox_from_styles(styles)
	
	var has_left_padding = styles.has("padding") or styles.has("padding-left")
	var has_right_padding = styles.has("padding") or styles.has("padding-right")
	var has_top_padding = styles.has("padding") or styles.has("padding-top")
	var has_bottom_padding = styles.has("padding") or styles.has("padding-bottom")
	
	
	if not has_left_padding:
		style_box.content_margin_left = 5.0
	if not has_right_padding:
		style_box.content_margin_right = 5.0
	if not has_top_padding:
		style_box.content_margin_top = 2.0
	if not has_bottom_padding:
		style_box.content_margin_bottom = 2.0
	
	var hover_styles = _parser.get_element_styles_with_inheritance(_element, "hover", [])
	var active_styles = _parser.get_element_styles_with_inheritance(_element, "active", [])
	var hover_style_box = null
	var active_style_box = null
	
	if not hover_styles.is_empty():
		hover_style_box = BackgroundUtils.create_stylebox_from_styles(hover_styles)
		if not hover_styles.has("padding") and not hover_styles.has("padding-left"):
			hover_style_box.content_margin_left = 5.0
		if not hover_styles.has("padding") and not hover_styles.has("padding-right"):
			hover_style_box.content_margin_right = 5.0
		if not hover_styles.has("padding") and not hover_styles.has("padding-top"):
			hover_style_box.content_margin_top = 2.0
		if not hover_styles.has("padding") and not hover_styles.has("padding-bottom"):
			hover_style_box.content_margin_bottom = 2.0
	
	if not active_styles.is_empty():
		active_style_box = BackgroundUtils.create_stylebox_from_styles(active_styles)
		if not active_styles.has("padding") and not active_styles.has("padding-left"):
			active_style_box.content_margin_left = 5.0
		if not active_styles.has("padding") and not active_styles.has("padding-right"):
			active_style_box.content_margin_right = 5.0
		if not active_styles.has("padding") and not active_styles.has("padding-top"):
			active_style_box.content_margin_top = 2.0
		if not active_styles.has("padding") and not active_styles.has("padding-bottom"):
			active_style_box.content_margin_bottom = 2.0
	
	if control is LineEdit:
		control.add_theme_stylebox_override("normal", style_box)
		control.add_theme_stylebox_override("focus", style_box)
		if hover_style_box:
			control.add_theme_stylebox_override("hover", hover_style_box)
		if active_style_box:
			control.add_theme_stylebox_override("pressed", active_style_box)
	elif control is SpinBox:
		# NOTE: currently broken, it goes over the buttons, dont have time to fix
		#style_box.expand_margin_right += 32.0 # More space for stepper buttons
		
		var line_edit = control.get_line_edit()
		if line_edit:
			line_edit.add_theme_stylebox_override("normal", style_box)
			line_edit.add_theme_stylebox_override("focus", style_box)
			if hover_style_box:
				line_edit.add_theme_stylebox_override("hover", hover_style_box)
			if active_style_box:
				line_edit.add_theme_stylebox_override("pressed", active_style_box)
		
	elif control is Button:
		control.add_theme_stylebox_override("normal", style_box)
		if hover_style_box:
			control.add_theme_stylebox_override("hover", hover_style_box)
		if active_style_box:
			control.add_theme_stylebox_override("pressed", active_style_box)
