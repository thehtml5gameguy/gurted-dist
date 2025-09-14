class_name YearView
extends HBoxContainer

@export var calendar: Calendar

func init():
	var button_example: Button = %Button
	var year_container: VBoxContainer = %YearContainer
	
	var buttons_data = []
	for i in range(200):
		var year = i + 1900
		buttons_data.append(year)
	
	for year in buttons_data:
		var new_btn: Button = button_example.duplicate()
		new_btn.name = "Year" + str(year)
		new_btn.pressed.connect(_on_year_selected.bind(year))
		new_btn.text = str(year)
		year_container.add_child(new_btn)
	
	button_example.queue_free()
	
	year_container.resized.connect(func():
		scroll_to_current_year()
		refresh()
		)

func scroll_to_current_year():
	var year_container: VBoxContainer = %YearContainer
	var scroll_container: ScrollContainer = $ScrollContainer

	var current_year = calendar.date_time.year
	var target_button: Button = year_container.get_node_or_null("Year" + str(current_year))
	
	if not target_button:
		return
	
	while target_button.position.y <= 0:
		await get_tree().process_frame
	
	for child in year_container.get_children():
		if child is Button:
			child.set_pressed_no_signal(child == target_button)
	
	var button_position = target_button.position.y
	var container_height = scroll_container.size.y
	var button_height = target_button.size.y
	var scroll_position = button_position - (container_height / 2) + (button_height / 2)
	
	scroll_container.scroll_vertical = max(0, scroll_position)

func _on_year_selected(year: int):
	var new_date = calendar.date_time.duplicate()
	new_date.year = year
	calendar.selected = new_date
	calendar.date_time = new_date
	
	if calendar.has_signal("date_changed"):
		calendar.date_changed.emit(new_date)
	
	calendar.year_view.hide()
	calendar.month_view.show()
	calendar.month_view.refresh()
	
	calendar.finished.emit()

func previous():
	var new_date = calendar.date_time.duplicate()
	new_date.year -= 1
	calendar.date_time = new_date
	refresh()

func next():
	var new_date = calendar.date_time.duplicate()
	new_date.year += 1
	calendar.date_time = new_date
	refresh()

func refresh():
	var current_time = Time.get_unix_time_from_system()
	
	calendar.header.text = "%s %s" % [MonthView.num_to_month(calendar.date_time.month), calendar.date_time.year]
	
	for child in %YearContainer.get_children():
		if child is Button:
			child.set_pressed_no_signal(false)
	
	var target_button_name = "Year" + str(calendar.date_time.year)
	var target_button = %YearContainer.get_node_or_null(target_button_name)
	if target_button:
		target_button.set_pressed_no_signal(true)
