class_name DownloadEntry
extends PanelContainer

@onready var time_label: RichTextLabel = $DownloadEntry/TimeLabel
@onready var filename_label: RichTextLabel = $DownloadEntry/FileNameLabel
@onready var domain_label: RichTextLabel = $DownloadEntry/DomainLabel
@onready var size_label: RichTextLabel = $DownloadEntry/SizeLabel
@onready var link_button: Button = $DownloadEntry/LinkButton
@onready var file_button: Button = $DownloadEntry/FileButton

var download_data: Dictionary = {}

func setup_download_entry(data: Dictionary):
	download_data = data
	
	var filename = data.get("filename", "Unknown file")
	var url = data.get("url", "")
	var current_site = data.get("current_site", "")
	var file_size = data.get("size", 0)
	var timestamp = data.get("timestamp", Time.get_unix_time_from_system())
	
	filename_label.text = filename
	
	current_site = URLUtils.extract_domain(url) if url != "" else "Unknown source"
	domain_label.text = current_site
	
	var size_text = NetworkRequest.format_bytes(file_size)
	size_label.text = size_text
	
	var time_text = _format_time(timestamp)
	time_label.text = time_text

func _format_time(unix_timestamp: float) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(int(unix_timestamp))
	
	# Format as "3:45PM"
	var hour = datetime.hour
	var minute = datetime.minute
	var am_pm = "AM"
	
	if hour == 0:
		hour = 12
	elif hour > 12:
		hour -= 12
		am_pm = "PM"
	elif hour == 12:
		am_pm = "PM"
	
	return "%d:%02d%s" % [hour, minute, am_pm]

func get_filename() -> String:
	return download_data.get("filename", "")

func get_domain() -> String:
	var url = download_data.get("url", "")
	return URLUtils.extract_domain(url) if url != "" else ""

func get_download_data() -> Dictionary:
	return download_data

func _on_link_button_pressed() -> void:
	DisplayServer.clipboard_set(download_data.get("url", ""))

func _on_file_button_pressed() -> void:
	var file_path = download_data.get("file_path", "")
	if file_path != "" and FileAccess.file_exists(file_path):
		var file_dir = file_path.get_base_dir()
		OS.shell_show_in_file_manager(file_dir)
	else:
		print("File not found: ", file_path)
