class_name DownloadDialog
extends PopupPanel

signal download_confirmed(download_data: Dictionary, save_path: String)
signal download_cancelled(download_data: Dictionary)

@onready var ok_button: Button = $VBox/HBoxContainer/OkButton
@onready var cancel_button: Button = $VBox/HBoxContainer/CancelButton
@onready var file_dialog: FileDialog = $FileDialog

@onready var filename_label: Label = $VBox/FilenameLabel
@onready var url_label: Label = $VBox/URLLabel

var download_data: Dictionary = {}

func show_download_dialog(data: Dictionary):
	download_data = data
	
	var filename = data.get("filename", "download")
	var url = data.get("url", "")
	
	filename_label.text = "File: " + filename
	
	var current_site = data.get("current_site", "")
	if current_site != "":
		url_label.text = "From: " + current_site
	else:
		url_label.text = "From: " + URLUtils.extract_domain(url)
	
	popup()
	_animate_entrance()
	ok_button.grab_focus()

func _animate_entrance():
	if not is_inside_tree():
		return
	
	var original_size = Vector2(size)
	var small_size = original_size * 0.8
	var size_difference = original_size - small_size
	var original_pos = position
	
	size = Vector2i(small_size)
	position = original_pos + Vector2i(size_difference * 0.5)
	
	var tween = create_tween()
	if tween:
		tween.set_parallel(true)
		var size_property = tween.tween_property(self, "size", Vector2i(original_size), 0.2)
		var pos_property = tween.tween_property(self, "position", original_pos, 0.2)
		
		if size_property:
			size_property.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		if pos_property:
			pos_property.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_download_confirmed():
	file_dialog.current_file = download_data.get("filename", "download")
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	file_dialog.show()

func _animate_exit():
	if not is_inside_tree():
		queue_free()
		return
	
	var current_size = Vector2(size)
	var small_size = current_size * 0.8
	var size_difference = current_size - small_size
	var current_pos = position
	var target_pos = current_pos + Vector2i(size_difference * 0.5)
	
	var tween = create_tween()
	if tween:
		tween.set_parallel(true)
		var size_property = tween.tween_property(self, "size", Vector2i(small_size), 0.15)
		var pos_property = tween.tween_property(self, "position", target_pos, 0.15)
		
		if size_property:
			size_property.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		if pos_property:
			pos_property.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		
		await tween.finished
	
	queue_free()

func _on_save_location_selected(path: String):
	download_confirmed.emit(download_data, path)
	_animate_exit()

func _on_file_dialog_cancelled():
	download_cancelled.emit(download_data)
	_animate_exit()

func _on_download_cancelled():
	download_cancelled.emit(download_data)
	_animate_exit()
