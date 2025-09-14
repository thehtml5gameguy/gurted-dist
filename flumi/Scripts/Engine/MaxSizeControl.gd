@tool
class_name MaxSizeControl
extends Control

@export var max_size: Vector2 = Vector2(-1, -1):
	set(value):
		max_size = value
		_enforce_size_limits()

var content_node: Control

func _ready():
	# Auto-detect content node
	if get_child_count() > 0:
		setup_content_node(get_child(0))
	
	# Connect to our own resize
	resized.connect(_on_resized)

func setup_content_node(node: Control):
	content_node = node
	if content_node:
		# Make content fill the container initially
		content_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Connect to content changes
		if not content_node.minimum_size_changed.is_connected(_on_content_changed):
			content_node.minimum_size_changed.connect(_on_content_changed)
		
		_enforce_size_limits()

func _on_content_changed():
	_enforce_size_limits()

func _on_resized():
	_enforce_size_limits()

func _enforce_size_limits():
	if not content_node:
		return
	
	var target_width = max_size.x if max_size.x > 0 else content_node.get_combined_minimum_size().x
	var target_height = max_size.y if max_size.y > 0 else content_node.get_combined_minimum_size().y

	custom_minimum_size = Vector2(target_width, target_height)
	
	# Set children's minimum size to match the constrained size
	for child in get_children():
		if child is Control:
			child.custom_minimum_size = Vector2(target_width, target_height)
	
	# Force the content to fit within our bounds and enable clipping
	content_node.size = Vector2(target_width, target_height)
	content_node.position = Vector2.ZERO
	
	# Always enable clipping if max_size is set
	var needs_clipping = max_size.x > 0 or max_size.y > 0
	content_node.clip_contents = needs_clipping
	clip_contents = true

func _get_minimum_size() -> Vector2:
	# Only use max_size, ignore content's natural size
	var final_size = Vector2.ZERO
	if max_size.x > 0:
		final_size.x = max_size.x
	if max_size.y > 0:
		final_size.y = max_size.y
	return final_size
