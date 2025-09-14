extends HBoxContainer
signal checkbox_toggle
signal entry_clicked(url: String)

@onready var check_box: CheckBox = $CheckBox
@onready var time_label: RichTextLabel = $RichTextLabel
@onready var icon: TextureRect = $TextureRect
@onready var title_label: RichTextLabel = $RichTextLabel2
@onready var domain_label: RichTextLabel = $DomainLabel

var entry_url: String = ""
var entry_title: String = ""

func reset() -> void:
	check_box.set_pressed_no_signal(false)

func _on_check_box_toggled(toggled_on: bool) -> void:
	checkbox_toggle.emit(toggled_on)

func setup_entry(url: String, title: String, timestamp: String, icon_url: String = ""):
	entry_url = url
	entry_title = title
	
	title_label.text = title if not title.is_empty() else url
	
	var domain = URLUtils.extract_domain(url)
	if domain.is_empty():
		domain = url
	domain_label.text = domain
	
	var datetime_dict = Time.get_datetime_dict_from_datetime_string(timestamp, false)
	if datetime_dict.has("hour") and datetime_dict.has("minute"):
		var hour = datetime_dict.hour
		var minute = datetime_dict.minute
		var am_pm = "AM"
		
		if hour == 0:
			hour = 12
		elif hour > 12:
			hour -= 12
			am_pm = "PM"
		elif hour == 12:
			am_pm = "PM"
		
		time_label.text = "%d:%02d%s" % [hour, minute, am_pm]
	else:
		time_label.text = ""
	
	if not icon_url.is_empty():
		_load_icon(icon_url)
	else:
		const GLOBE_ICON = preload("res://Assets/Icons/globe.svg")
		icon.texture = GLOBE_ICON

func _load_icon(icon_url: String):
	if icon_url.is_empty():
		const GLOBE_ICON = preload("res://Assets/Icons/globe.svg")
		icon.texture = GLOBE_ICON
		return
	
	icon.texture = null
	
	var icon_resource = await Network.fetch_image(icon_url)
	
	if is_instance_valid(self) and icon_resource:
		icon.texture = icon_resource
	elif is_instance_valid(self):
		const GLOBE_ICON = preload("res://Assets/Icons/globe.svg")
		icon.texture = GLOBE_ICON

func get_title() -> String:
	return entry_title

func get_url() -> String:
	return entry_url

func _ready():
	title_label.gui_input.connect(_on_title_clicked)
	domain_label.gui_input.connect(_on_title_clicked)

func _on_title_clicked(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			entry_clicked.emit(entry_url)
