class_name MonthView
extends VBoxContainer

@export var calendar: Calendar

var buttons: GridContainer
var dates: Array = []
var _updating: bool = false

func _ready():
	buttons = $Days
	for i in range(buttons.get_child_count()):
		buttons.get_child(i).toggled.connect(_on_day_toggled.bind(i))
	refresh()

func _on_day_toggled(toggled: bool, button_index: int):
	if _updating or button_index >= dates.size() or not dates[button_index]:
		return
	
	var button = buttons.get_child(button_index)
	if not toggled:
		button.set_pressed_no_signal(true)
		return
	
	for i in range(buttons.get_child_count()):
		if i != button_index:
			buttons.get_child(i).set_pressed_no_signal(false)
	
	calendar.selected = dates[button_index]
	calendar.date_time = dates[button_index].duplicate()
	calendar.hide()
	calendar.finished.emit()

func previous():
	var new_date = calendar.date_time.duplicate()
	new_date.month -= 1
	if new_date.month < 1:
		new_date.month = 12
		new_date.year -= 1
	calendar.date_time = new_date
	refresh()

func next():
	var new_date = calendar.date_time.duplicate()
	new_date.month += 1
	if new_date.month > 12:
		new_date.month = 1
		new_date.year += 1
	calendar.date_time = new_date
	refresh()

func refresh():
	_updating = true
	calendar.header.text = "%s %s" % [num_to_month(calendar.date_time.month), calendar.date_time.year]
	dates.clear()
	dates.resize(buttons.get_child_count())
	
	for i in range(buttons.get_child_count()):
		var button = buttons.get_child(i)
		button.text = ""
		button.set_pressed_no_signal(false)
		dates[i] = null
	
	var first_day = calendar.date_time.duplicate()
	first_day.day = 1
	var start_day = Time.get_datetime_dict_from_unix_time(
		Time.get_unix_time_from_datetime_dict(first_day)
	).weekday % 7
	
	var days_in_month = get_days_in_month(calendar.date_time.year, calendar.date_time.month)
	
	var prev_month_num = calendar.date_time.month - 1
	var prev_year = calendar.date_time.year
	if prev_month_num < 1:
		prev_month_num = 12
		prev_year -= 1
	var prev_days = get_days_in_month(prev_year, prev_month_num)
	
	var gray_color = Color(0.51, 0.54, 0.596)
	var dark_color = Color(0.133, 0.137, 0.137)
	
	# Fill previous month days
	for i in range(start_day):
		var day = prev_days - start_day + i + 1
		var button = buttons.get_child(i)
		dates[i] = {"year": prev_year, "month": prev_month_num, "day": day}
		button.text = str(day)
		button.add_theme_color_override("font_color", gray_color)
		button.add_theme_color_override("font_hover_color", gray_color)
		button.set_pressed_no_signal(
			day == calendar.selected.day and
			calendar.selected.year == prev_year and
			calendar.selected.month == prev_month_num
		)
	
	# Fill current month days
	for i in range(days_in_month):
		var button = buttons.get_child(i + start_day)
		dates[i + start_day] = {"year": calendar.date_time.year, "month": calendar.date_time.month, "day": i + 1}
		button.text = str(i + 1)
		button.add_theme_color_override("font_color", dark_color)
		button.add_theme_color_override("font_hover_color", dark_color)
		button.set_pressed_no_signal(
			i + 1 == calendar.selected.day and
			calendar.selected.year == calendar.date_time.year and
			calendar.selected.month == calendar.date_time.month
		)
	
	var next_month_num = calendar.date_time.month + 1
	var next_year = calendar.date_time.year
	if next_month_num > 12:
		next_month_num = 1
		next_year += 1
	
	# Fill next month days
	for i in range(days_in_month + start_day, buttons.get_child_count()):
		var day = i + 1 - days_in_month - start_day
		var button = buttons.get_child(i)
		dates[i] = {"year": next_year, "month": next_month_num, "day": day}
		button.text = str(day)
		button.add_theme_color_override("font_color", gray_color)
		button.add_theme_color_override("font_hover_color", gray_color)
		button.set_pressed_no_signal(
			day == calendar.selected.day and
			calendar.selected.year == next_year and
			calendar.selected.month == next_month_num
		)
	
	_updating = false

func get_days_in_month(year: int, month: int) -> int:
	var thirty_one = [1, 3, 5, 7, 8, 10, 12]
	var thirty = [4, 6, 9, 11]
	
	if month in thirty_one:
		return 31
	elif month in thirty:
		return 30
	elif month == 2:
		return 29 if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0) else 28
	else:
		return 0

static func num_to_month(month: int) -> String:
	var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return months[month - 1]
