extends TextEdit

@onready var resize_handle = TextureRect.new()
var is_resizing = false
var resize_start_pos = Vector2()
var original_size = Vector2()

var min_size = Vector2(100, 50)

func _ready():
	# Create resize handle as TextureRect child of TextEdit
	resize_handle.texture = load("res://Assets/Icons/resize-handle.svg")
	resize_handle.size = Vector2(32, 32)
	resize_handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	resize_handle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(resize_handle)
	
	# Position handle in bottom-right corner
	_update_handle_position()
	
	# Connect signals
	resize_handle.gui_input.connect(_on_resize_handle_input)
	resized.connect(_update_handle_position)

func _gui_input(event):
	if event is InputEventMouseButton and get_global_rect().has_point(get_viewport().get_mouse_position()):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_v_scroll(get_v_scroll() - 2)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_v_scroll(get_v_scroll() + 2)
			accept_event()

func _update_handle_position():
	if resize_handle:
		resize_handle.position = Vector2(size.x - 32, size.y - 32)

func _on_resize_handle_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_resizing = true
				resize_start_pos = event.global_position
				original_size = size
			else:
				is_resizing = false
	
	elif event is InputEventMouseMotion and is_resizing:
		var delta = event.global_position - resize_start_pos
		var new_size = original_size + delta
		new_size.x = max(new_size.x, min_size.x)
		new_size.y = max(new_size.y, min_size.y)
		
		size = new_size
		
		# Sync parent Control size
		var parent_control = get_parent() as Control
		if parent_control:
			parent_control.size = new_size
			parent_control.custom_minimum_size = new_size
		if parent_control:
			parent_control.size = new_size
			parent_control.custom_minimum_size = new_size
		
