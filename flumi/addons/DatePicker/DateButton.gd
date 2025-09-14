class_name DateButton
extends Button

signal date_selected(date_text: String)

var calendar: Calendar
var calendar_control: Control

const CALENDAR = preload("res://addons/DatePicker/Calendar.tscn")

func init():
	text = "mm/dd/yyyy"
	_init_calendar()

func _init_calendar():
	calendar = CALENDAR.instantiate()
	add_child(calendar)
	calendar.hide()
	calendar.init()

	pressed.connect(_on_button_pressed)
	calendar.popup_hide.connect(func(): button_pressed = false)
	calendar.finished.connect(_on_date_selected)
	tree_exited.connect(func(): if is_instance_valid(calendar): calendar.queue_free())

func init_with_date(date_string: String) -> void:
	_init_calendar()
	
	var parsed_date = parse_date_string(date_string)
	if parsed_date:
		calendar.date_time = parsed_date
		calendar.selected = parsed_date.duplicate()
		update_button_text()
	else:
		text = "mm/dd/yyyy"  # Set default text if parsing fails

func parse_date_string(date_string: String) -> Dictionary:
	# Parse ISO date format (YYYY-MM-DD)
	var parts = date_string.split("-")
	if parts.size() != 3:
		return {}
	
	var year = parts[0].to_int()
	var month = parts[1].to_int()
	var day = parts[2].to_int()
	
	# Validate date components
	if year < 1 or month < 1 or month > 12 or day < 1 or day > 31:
		return {}
	
	return {
		"year": year,
		"month": month,
		"day": day
	}

func update_button_text() -> void:
	var date = calendar.selected
	if date and date.has("month") and date.has("day") and date.has("year"):
		text = "%02d/%02d/%04d" % [date.month, date.day, date.year]
		date_selected.emit(text)
	else:
		text = "mm/dd/yyyy"

func _on_date_selected():
	var date = calendar.selected
	if date and date.has("month") and date.has("day") and date.has("year"):
		text = "%02d/%02d/%04d" % [date.month, date.day, date.year]
		date_selected.emit(text)
	else:
		text = "mm/dd/yyyy"

func _on_button_pressed():
	if calendar.is_visible():
		calendar.hide()
		return

	var viewport_height = get_viewport_rect().size.y
	var show_above = false
	if get_global_position().y + size.y + calendar.size.y > viewport_height and get_global_position().y * 2 + size.y > viewport_height:
		show_above = true
		
	var h_offset = (size.x - calendar.size.x) / 2
	var v_offset = -calendar.size.y if show_above else size.y
	
	calendar.position = get_screen_position() + Vector2(h_offset, v_offset)
	calendar.popup()
