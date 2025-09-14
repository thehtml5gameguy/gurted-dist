class_name HTMLButton
extends HBoxContainer

var current_element: HTMLParser.HTMLElement
var current_parser: HTMLParser

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	current_element = element
	current_parser = parser
	var button_node: Button = $ButtonNode
	button_node.disabled = element.has_attribute("disabled")
	
	var button_text = element.text_content.strip_edges()
	if button_text.length() == 0:
		button_text = element.get_bbcode_formatted_text(parser)
	
	if button_text.length() > 0:
		button_node.text = button_text
	
	# Set container to shrink to fit content
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# Let button size itself naturally
	button_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button_node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	apply_button_styles(element, parser)
	
	parser.register_dom_node(element, self)

func apply_button_styles(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	if not element or not parser:
		return

	var styles = parser.get_element_styles_with_inheritance(element, "", [])
	var hover_styles = parser.get_element_styles_with_inheritance(element, "hover", [])
	var active_styles = parser.get_element_styles_with_inheritance(element, "active", [])
	var button_node = $ButtonNode
	
	if styles.has("cursor"):
		var cursor_shape = StyleManager.get_cursor_shape_from_type(styles["cursor"])
		mouse_default_cursor_shape = cursor_shape
		button_node.mouse_default_cursor_shape = cursor_shape
	
	if styles.has("font-size"):
		var font_size = int(styles["font-size"])
		button_node.add_theme_font_size_override("font_size", font_size)
	
	# Apply text color with state-dependent colors
	apply_button_text_color(button_node, styles, hover_styles, active_styles)
	
	# Apply transform properties with hover support
	apply_button_transforms(button_node, styles, hover_styles)
	
	# Apply background color (hover: + active:)
	if styles.has("background-color"):
		var normal_color: Color = styles["background-color"]
		var hover_color = normal_color  # Default to normal color
		var active_color = normal_color  # Default to normal color
		
		# Check if background color comes from inline styles
		var inline_style = element.get_attribute("style")
		var inline_normal_styles = parser.parse_inline_style_with_event(inline_style, "")
		var has_inline_bg = inline_normal_styles.has("background-color")
		
		if has_inline_bg:
			# If user set inline bg, only use inline hover/active, ignore global ones
			var inline_hover_styles = parser.parse_inline_style_with_event(inline_style, "hover")
			var inline_active_styles = parser.parse_inline_style_with_event(inline_style, "active")
			
			if inline_hover_styles.has("background-color"):
				hover_color = inline_hover_styles["background-color"]
			if inline_active_styles.has("background-color"):
				active_color = inline_active_styles["background-color"]
			elif inline_hover_styles.has("background-color"):
				# Fallback: if hover is defined but active isn't, use hover for active
				active_color = hover_color
		else:
			# No inline bg, use global CSS hover/active if available
			if hover_styles.has("background-color"):
				hover_color = hover_styles["background-color"]
			if active_styles.has("background-color"):
				active_color = active_styles["background-color"]
			elif hover_styles.has("background-color"):
				# Fallback: if hover is defined but active isn't, use hover for active
				active_color = hover_color
			
		apply_button_color_with_states(button_node, normal_color, hover_color, active_color, styles)

	var width = null
	var height = null

	if styles.has("width"):
		width = SizingUtils.parse_size_value(styles["width"])
	if styles.has("height"):
		height = SizingUtils.parse_size_value(styles["height"])

	# Apply explicit sizing if provided
	if width != null or height != null:
		apply_size_and_flags(button_node, width, height)
		# Container will automatically resize to fit the button

func apply_button_text_color(button: Button, normal_styles: Dictionary, hover_styles: Dictionary, active_styles: Dictionary) -> void:
	var normal_color = normal_styles.get("color", Color.WHITE)
	var hover_color = hover_styles.get("color", normal_color)
	var active_color = active_styles.get("color", hover_color)
	
	button.add_theme_color_override("font_color", normal_color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", active_color)
	button.add_theme_color_override("font_focus_color", normal_color)
	
	if button.disabled:
		button.add_theme_color_override("font_disabled_color", normal_color)

func apply_button_color_with_states(button: Button, normal_color: Color, hover_color: Color, active_color: Color, styles: Dictionary = {}) -> void:
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()
	
	var radius: int = 0
	if styles.has("border-radius"):
		radius = StyleManager.parse_radius(styles["border-radius"])
	
	style_normal.set_corner_radius_all(radius)
	style_hover.set_corner_radius_all(radius)
	style_pressed.set_corner_radius_all(radius)
	
	# Apply padding to all style boxes
	apply_padding_to_stylebox(style_normal, styles)
	apply_padding_to_stylebox(style_hover, styles)
	apply_padding_to_stylebox(style_pressed, styles)

	# Set normal color
	style_normal.bg_color = normal_color

	# Set hover: color
	# If hover isn't default, use it
	if hover_color != Color():
		style_hover.bg_color = hover_color
	else:
		# If no hover, fallback to normal color
		style_hover.bg_color = normal_color
	
	# Set active: color
	if active_color != Color():
		style_pressed.bg_color = active_color
	elif hover_color != Color():
		style_pressed.bg_color = hover_color # Fallback to hover if defined
	else:
		style_pressed.bg_color = normal_color # Final fallback to normal
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)

func apply_padding_to_stylebox(style_box: StyleBoxFlat, styles: Dictionary) -> void:
	# Apply general padding first
	if styles.has("padding"):
		var padding_val = StyleManager.parse_size(styles["padding"])
		if padding_val != null:
			style_box.content_margin_top = padding_val
			style_box.content_margin_right = padding_val
			style_box.content_margin_bottom = padding_val
			style_box.content_margin_left = padding_val
	
	# Apply individual padding overrides
	if styles.has("padding-top"):
		var padding_val = StyleManager.parse_size(styles["padding-top"])
		if padding_val != null:
			style_box.content_margin_top = padding_val
	
	if styles.has("padding-right"):
		var padding_val = StyleManager.parse_size(styles["padding-right"])
		if padding_val != null:
			style_box.content_margin_right = padding_val
	
	if styles.has("padding-bottom"):
		var padding_val = StyleManager.parse_size(styles["padding-bottom"])
		if padding_val != null:
			style_box.content_margin_bottom = padding_val
	
	if styles.has("padding-left"):
		var padding_val = StyleManager.parse_size(styles["padding-left"])
		if padding_val != null:
			style_box.content_margin_left = padding_val

func apply_size_and_flags(ctrl: Control, width: Variant, height: Variant) -> void:
	if width != null or height != null:
		var new_width = 0
		var new_height = 0
		
		if width != null:
			if SizingUtils.is_percentage(width):
				new_width = SizingUtils.calculate_percentage_size(width, SizingUtils.DEFAULT_VIEWPORT_WIDTH)
			else:
				new_width = width
		
		if height != null:
			if SizingUtils.is_percentage(height):
				new_height = SizingUtils.calculate_percentage_size(height, SizingUtils.DEFAULT_VIEWPORT_HEIGHT)
			else:
				new_height = height
		
		ctrl.custom_minimum_size = Vector2(new_width, new_height)
		
		if width != null:
			ctrl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if height != null:
			ctrl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func apply_button_transforms(button: Button, normal_styles: Dictionary, hover_styles: Dictionary) -> void:
	# Apply normal transforms to the parent HBoxContainer (self)
	StyleManager.apply_transform_properties_direct(self, normal_styles)
	
	# Set pivot point to center of the container
	self.pivot_offset = self.size / 2
	
	# Set up hover transforms if present
	var has_hover_transforms = hover_styles.has("scale-x") or hover_styles.has("scale-y") or hover_styles.has("rotate")
	if has_hover_transforms:
		# Store original and hover values
		var original_scale = Vector2(
			normal_styles.get("scale-x", 1.0),
			normal_styles.get("scale-y", 1.0)
		)
		var original_rotation = normal_styles.get("rotate", 0.0)
		
		var hover_scale = Vector2(
			hover_styles.get("scale-x", original_scale.x),
			hover_styles.get("scale-y", original_scale.y)
		)
		var hover_rotation = hover_styles.get("rotate", original_rotation)
		
		# Get transition duration
		var duration = StyleManager.get_transition_duration(normal_styles)
		if duration == 0:
			duration = StyleManager.get_transition_duration(hover_styles)
		
		# Connect hover events to the button but apply transforms to self
		button.mouse_entered.connect(func():
			# Update pivot point in case size changed
			self.pivot_offset = self.size / 2
			if duration > 0:
				StyleManager.animate_transform(self, hover_scale, hover_rotation, duration)
			else:
				self.scale = hover_scale
				self.rotation = hover_rotation
		)
		
		button.mouse_exited.connect(func():
			# Update pivot point in case size changed
			self.pivot_offset = self.size / 2
			if duration > 0:
				StyleManager.animate_transform(self, original_scale, original_rotation, duration)
			else:
				self.scale = original_scale
				self.rotation = original_rotation
		)
