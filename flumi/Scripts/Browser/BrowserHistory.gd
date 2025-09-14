extends Node

const HISTORY_FILE_PATH = "user://browser_history.json"
const MAX_HISTORY_ENTRIES = 1000

func get_history_data() -> Array:
	var history_file = FileAccess.open(HISTORY_FILE_PATH, FileAccess.READ)
	if not history_file:
		return []
	
	var json_string = history_file.get_as_text()
	history_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return []
	
	var history_data = json.data
	if not history_data is Array:
		return []
	
	return history_data

func save_history_data(history_data: Array):
	var history_file = FileAccess.open(HISTORY_FILE_PATH, FileAccess.WRITE)
	if not history_file:
		push_error("Failed to open history file for writing")
		return
	
	var json_string = JSON.stringify(history_data)
	history_file.store_string(json_string)
	history_file.close()

func add_entry(url: String, title: String, icon_url: String = ""):
	if url.is_empty():
		return
		
	var history_data = get_history_data()
	var timestamp = Time.get_datetime_string_from_system()
	
	var existing_index = -1
	for i in range(history_data.size()):
		if history_data[i].url == url:
			existing_index = i
			break
	
	var entry = {
		"url": url,
		"title": title,
		"timestamp": timestamp,
		"icon_url": icon_url
	}
	
	if existing_index >= 0:
		history_data.remove_at(existing_index)
	
	history_data.insert(0, entry)
	
	if history_data.size() > MAX_HISTORY_ENTRIES:
		history_data = history_data.slice(0, MAX_HISTORY_ENTRIES)
	
	save_history_data(history_data)

func remove_entry(url: String):
	var history_data = get_history_data()
	
	for i in range(history_data.size() - 1, -1, -1):
		if history_data[i].url == url:
			history_data.remove_at(i)
	
	save_history_data(history_data)

func clear_all():
	save_history_data([])

func search_history(query: String) -> Array:
	var history_data = get_history_data()
	var results = []
	
	query = query.to_lower()
	
	for entry in history_data:
		var title = entry.get("title", "").to_lower()
		var url = entry.get("url", "").to_lower()
		
		if title.contains(query) or url.contains(query):
			results.append(entry)
	
	return results
