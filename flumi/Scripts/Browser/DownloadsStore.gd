class_name DownloadsStore
extends PopupPanel

@onready var search_line_edit: LineEdit = $Main/LineEdit
@onready var download_entry_container: VBoxContainer = $Main/PanelContainer2/ScrollContainer/DownloadEntryContainer

const DOWNLOAD_ENTRY = preload("res://Scenes/BrowserMenus/download_entry.tscn")
var save_path = "user://downloads_history.json"

var download_entries: Array[DownloadEntry] = []

func _ready():
	search_line_edit.text_changed.connect(_on_search_text_changed)
	
	load_download_history()

func add_download_entry(download_data: Dictionary):
	var entry = DOWNLOAD_ENTRY.instantiate()
	download_entry_container.add_child(entry)
	
	entry.setup_download_entry(download_data)
	
	download_entries.append(entry)
	
	save_download_history()

func _on_search_text_changed(new_text: String):
	var search_term = new_text.to_lower().strip_edges()
	
	for entry in download_entries:
		if search_term.is_empty():
			entry.visible = true
		else:
			var filename = entry.get_filename().to_lower()
			var domain = entry.get_domain().to_lower()
			entry.visible = filename.contains(search_term) or domain.contains(search_term)

func load_download_history():
	if not FileAccess.file_exists(save_path):
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		print("Could not open downloads history file for reading")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("Error parsing downloads history JSON")
		return
	
	var downloads_data = json.data
	if downloads_data is Array:
		for download_data in downloads_data:
			add_download_entry(download_data)

func save_download_history():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		print("Could not open downloads history file for writing")
		return
	
	var downloads_data = get_download_data_array()
	var json_text = JSON.stringify(downloads_data)
	file.store_string(json_text)
	file.close()

func get_download_data_array() -> Array[Dictionary]:
	var data_array: Array[Dictionary] = []
	for entry in download_entries:
		data_array.append(entry.get_download_data())
	return data_array

func clear_all_downloads():
	for entry in download_entries:
		entry.queue_free()
	
	download_entries.clear()
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string("[]")
		file.close()
