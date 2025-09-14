class_name NetworkRequestItem
extends PanelContainer

@onready var icon: TextureRect = $HBoxContainer/IconContainer/Icon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var status_label: Label = $HBoxContainer/StatusLabel
@onready var type_label: Label = $HBoxContainer/TypeLabel
@onready var size_label: Label = $HBoxContainer/SizeLabel
@onready var time_label: Label = $HBoxContainer/TimeLabel

var request: NetworkRequest
var network_tab: NetworkTab

@onready var normal_style: StyleBox = get_meta("normal_style")
@onready var selected_style: StyleBox = get_meta("selected_style")

@onready var success_color: Color = status_label.get_meta("success_color")
@onready var error_color: Color = status_label.get_meta("error_color")
@onready var pending_color: Color = status_label.get_meta("pending_color")

signal item_clicked(request: NetworkRequest)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	gui_input.connect(_on_gui_input)

func init(network_request: NetworkRequest, parent_tab: NetworkTab):
	request = network_request
	network_tab = parent_tab
	if is_node_ready():
		update_display()
	else:
		call_deferred("update_display")

func update_display():
	if not request:
		return
	
	if icon == null:
		icon = get_node_or_null("HBoxContainer/IconContainer/Icon") as TextureRect
	if name_label == null:
		name_label = get_node_or_null("HBoxContainer/NameLabel") as Label
	if status_label == null:
		status_label = get_node_or_null("HBoxContainer/StatusLabel") as Label
	if type_label == null:
		type_label = get_node_or_null("HBoxContainer/TypeLabel") as Label
	if size_label == null:
		size_label = get_node_or_null("HBoxContainer/SizeLabel") as Label
	if time_label == null:
		time_label = get_node_or_null("HBoxContainer/TimeLabel") as Label
	
	if icon == null or name_label == null or status_label == null or type_label == null or size_label == null or time_label == null:
		call_deferred("update_display")
		return
	
	# Update icon
	icon.texture = request.get_icon_texture()
	
	# Update labels
	name_label.text = request.name
	status_label.text = request.get_status_display()
	type_label.text = request.get_type_display()
	size_label.text = NetworkRequest.format_bytes(request.size)
	time_label.text = request.get_time_display()
	
	# Color code status
	match request.status:
		NetworkRequest.RequestStatus.SUCCESS:
			status_label.add_theme_color_override("font_color", Color.GREEN)
		NetworkRequest.RequestStatus.ERROR:
			status_label.add_theme_color_override("font_color", Color.RED)
		NetworkRequest.RequestStatus.PENDING:
			status_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			item_clicked.emit(request)

func set_selected(selected: bool):
	if selected:
		add_theme_stylebox_override("panel", selected_style)
	else:
		add_theme_stylebox_override("panel", normal_style)

func hide_columns(should_hide: bool):
	status_label.visible = !should_hide
	type_label.visible = !should_hide
	size_label.visible = !should_hide
	time_label.visible = !should_hide
