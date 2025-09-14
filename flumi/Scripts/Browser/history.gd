extends PopupPanel
signal navigate_to_url(url: String)

@onready var history_entry_container: VBoxContainer = $Main/PanelContainer2/ScrollContainer/HistoryEntryContainer
@onready var delete_menu: PanelContainer = $Main/DeleteMenu
@onready var line_edit: LineEdit = $Main/LineEdit
@onready var entries_label: RichTextLabel = $Main/DeleteMenu/HBoxContainer/RichTextLabel
@onready var cancel_button: Button = $Main/DeleteMenu/HBoxContainer/CancelButton
@onready var delete_button: Button = $Main/DeleteMenu/HBoxContainer/DeleteButton

var toggled_entries = []
var history_entry_scene = preload("res://Scenes/BrowserMenus/history_entry.tscn")

func _ready():
	delete_button.pressed.connect(_on_delete_button_pressed)
	line_edit.text_changed.connect(_on_search_text_changed)
	load_history()

func history_toggle(toggled: bool, entry) -> void:
	print('toggling ', entry, ' to :', toggled)
	if toggled:
		toggled_entries.append(entry)
	else:
		toggled_entries.remove_at(toggled_entries.find(entry))
	
	entries_label.text = str(toggled_entries.size()) + " selected"
	
	if toggled_entries.size() != 0:
		delete_menu.show()
		line_edit.hide()
	else:
		delete_menu.hide()
		line_edit.show()

func _on_cancel_button_pressed() -> void:
	var entries_to_reset = toggled_entries.duplicate()
	toggled_entries.clear()
	
	for entry in entries_to_reset:
		entry.reset()
	
	delete_menu.hide()
	line_edit.show()

func _on_delete_button_pressed() -> void:
	var urls_to_delete = []
	for entry in toggled_entries:
		if entry.has_meta("history_url"):
			urls_to_delete.append(entry.get_meta("history_url"))
	
	for url in urls_to_delete:
		remove_history_entry(url)
	
	var entries_to_remove = toggled_entries.duplicate()
	toggled_entries.clear()
	
	for entry in entries_to_remove:
		history_entry_container.remove_child(entry)
		entry.queue_free()
	
	delete_menu.hide()
	line_edit.show()

func _on_search_text_changed(search_text: String) -> void:
	filter_history_entries(search_text)

func load_history():
	var history_data = BrowserHistory.get_history_data()
	var existing_entries = history_entry_container.get_children()
	
	var needs_update = existing_entries.size() != history_data.size()
	
	if not needs_update and history_data.size() > 0 and existing_entries.size() > 0:
		var first_entry = existing_entries[0]
		if first_entry.has_meta("history_url"):
			var stored_url = first_entry.get_meta("history_url")
			if stored_url != history_data[0].url:
				needs_update = true
	
	if needs_update:
		clear_displayed_entries()
		for entry in history_data:
			add_history_entry_to_display(entry.url, entry.title, entry.timestamp, entry.icon_url)
	
	show()

func clear_displayed_entries():
	for child in history_entry_container.get_children():
		child.queue_free()

func add_history_entry_to_display(url: String, title_: String, timestamp: String, icon_url: String = ""):
	var entry_instance = history_entry_scene.instantiate()
	history_entry_container.add_child(entry_instance)
	entry_instance.setup_entry(url, title_, timestamp, icon_url)
	entry_instance.connect("checkbox_toggle", history_toggle.bind(entry_instance))
	entry_instance.connect("entry_clicked", _on_entry_clicked)
	entry_instance.set_meta("history_url", url)

func filter_history_entries(search_text: String):
	if search_text.is_empty():
		# Show all entries
		for child in history_entry_container.get_children():
			child.visible = true
		return
	
	# Filter existing entries by showing/hiding them
	var query = search_text.to_lower()
	for child in history_entry_container.get_children():
		if child.has_method("get_title") and child.has_method("get_url"):
			var title_ = child.get_title().to_lower()
			var url = child.get_url().to_lower()
			child.visible = title_.contains(query) or url.contains(query)
		else:
			child.visible = false

func remove_history_entry(url: String):
	BrowserHistory.remove_entry(url)

func _on_entry_clicked(url: String):
	navigate_to_url.emit(url)
