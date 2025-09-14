class_name CodeEditUtils

static func create_code_edit(options: Dictionary = {}) -> CodeEdit:
	var code_edit = CodeEdit.new()
	
	# Default configuration
	var defaults = {
		"text": "",
		"editable": true,
		"size_flags_horizontal": Control.SIZE_EXPAND_FILL,
		"size_flags_vertical": Control.SIZE_EXPAND_FILL,
		"scroll_fit_content_height": false,
		"context_menu_enabled": true,
		"shortcut_keys_enabled": true,
		"selecting_enabled": true,
		"deselect_on_focus_loss_enabled": true,
		"drag_and_drop_selection_enabled": false,
		"virtual_keyboard_enabled": false,
		"middle_mouse_paste_enabled": false,
		"show_line_numbers": false,
		"syntax_highlighter": null,
		"transparent_background": false,
		"block_editing_signals": false
	}
	
	# Merge user options with defaults
	for key in defaults:
		if options.has(key):
			defaults[key] = options[key]
	
	# Apply basic properties
	code_edit.text = defaults.text
	code_edit.size_flags_horizontal = defaults.size_flags_horizontal
	code_edit.size_flags_vertical = defaults.size_flags_vertical
	code_edit.scroll_fit_content_height = defaults.scroll_fit_content_height
	code_edit.context_menu_enabled = defaults.context_menu_enabled
	code_edit.shortcut_keys_enabled = defaults.shortcut_keys_enabled
	code_edit.selecting_enabled = defaults.selecting_enabled
	code_edit.deselect_on_focus_loss_enabled = defaults.deselect_on_focus_loss_enabled
	code_edit.drag_and_drop_selection_enabled = defaults.drag_and_drop_selection_enabled
	code_edit.virtual_keyboard_enabled = defaults.virtual_keyboard_enabled
	code_edit.middle_mouse_paste_enabled = defaults.middle_mouse_paste_enabled
	
	# Line numbers
	if defaults.show_line_numbers:
		code_edit.gutters_draw_line_numbers = true
	
	# Syntax highlighter
	if defaults.syntax_highlighter:
		code_edit.syntax_highlighter = defaults.syntax_highlighter
	
	# Transparent background styling
	if defaults.transparent_background:
		var code_style_normal = StyleBoxFlat.new()
		code_style_normal.bg_color = Color.TRANSPARENT
		code_style_normal.border_width_left = 0
		code_style_normal.border_width_top = 0
		code_style_normal.border_width_right = 0
		code_style_normal.border_width_bottom = 0
		code_style_normal.content_margin_bottom = 8
		code_edit.add_theme_stylebox_override("normal", code_style_normal)
		code_edit.add_theme_stylebox_override("focus", code_style_normal)
	
	# Block editing
    # This is because Godot applies some transparency when we simply set editable=false, which I cant be bothered to fix
	if defaults.block_editing_signals and defaults.editable:
		code_edit.gui_input.connect(_block_editing_input)
	
	return code_edit

static func _block_editing_input(event: InputEvent):
	# Block text modification events while allowing selection and copy
	if event is InputEventKey:
		var key_event = event as InputEventKey
		# Allow Ctrl+C (copy), Ctrl+A (select all), arrow keys, etc.
		if key_event.pressed:
			# Allow copy operations
			if key_event.ctrl_pressed and key_event.keycode == KEY_C:
				return
			if key_event.ctrl_pressed and key_event.keycode == KEY_A:
				return
			# Allow navigation
			if key_event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN]:
				return
			# Block all other key inputs
			if key_event.keycode != KEY_ESCAPE:
				event.set_input_as_handled()

static func create_readonly_code_edit(text: String, options: Dictionary = {}) -> CodeEdit:
	var readonly_options = options.duplicate()
	readonly_options["text"] = text
	readonly_options["editable"] = false
	readonly_options["block_editing_signals"] = false
	return create_code_edit(readonly_options)
