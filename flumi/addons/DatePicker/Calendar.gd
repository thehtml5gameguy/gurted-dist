class_name Calendar
extends PopupPanel

@export var header: Button
@export var next: BaseButton
@export var previous: BaseButton
@export var view_parent: Control

@export var month_view: MonthView
@export var year_view: YearView

var margin: float = 16.0

var view: Node:
	get:
		return view_parent.get_child(0) if view_parent.get_child_count() > 0 else null

var _date_time: Dictionary = Time.get_datetime_dict_from_system()
## The date that the calendar is currently displaying.
var date_time: Dictionary:
	get:
		return _date_time
	set(value):
		_date_time = value
		date_changed.emit()

var _selected: Dictionary = Time.get_datetime_dict_from_system()
## The date that the user has selected.
var selected: Dictionary:
	get:
		return _selected
	set(value):
		_selected = value
		date_selected.emit()

## The earliest date that can be selected.
var lower_limit: Dictionary
## The latest date that can be selected.
var upper_limit: Dictionary
## The button that displays this calendar - can be null.
var calendar_button: Button

## The signal emitted when the view changes.
signal view_changed(view: Control)
## The signal emitted when the date changes.
signal date_changed()
## The signal emitted when the user selects a date in ANY view.
signal date_selected()
## The signal emitted when the user is finished selecting a date.
signal finished()

func init():
	header.text = "%s %s" % [MonthView.num_to_month(date_time.month), date_time.year]
	
	header.pressed.connect(_on_header_pressed)
	previous.pressed.connect(func(): if view: view.previous())
	next.pressed.connect(func(): if view: view.next())
	
	year_view.init()

func _enter_tree():
	get_tree().root.gui_focus_changed.connect(_on_gui_focus_changed)

func _exit_tree():
	if get_tree() and get_tree().root:
		get_tree().root.gui_focus_changed.disconnect(_on_gui_focus_changed)

func _on_header_pressed():
	var is_default = month_view.visible
	if is_default:
		month_view.hide()
		year_view.show()
	else:
		month_view.show()
		year_view.hide()

func _on_gui_focus_changed(focus: Control):
	if focus and not is_ancestor_of(focus) and not focus is DateButton:
		visible = false

func set_view(new_view: Node):
	if view:
		view.queue_free()
	new_view.calendar = self
	view_parent.add_child(new_view)
	view_changed.emit(new_view)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and view:
				view.next()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and view:
				view.previous()
