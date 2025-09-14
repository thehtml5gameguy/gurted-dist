class_name DownloadProgress
extends PanelContainer

signal download_cancelled(download_id: String)

@onready var filename_label: Label = $HBox/VBox/FilenameLabel
@onready var progress_bar: ProgressBar = $HBox/VBox/ProgressBar
@onready var status_label: Label = $HBox/VBox/StatusLabel
@onready var cancel_button: Button = $HBox/CancelButton

var download_id: String = ""
var download_data: Dictionary = {}
var start_time: float = 0.0

func _ready():
	progress_bar.value = 0
	status_label.text = "Starting download..."

func setup_download(id: String, data: Dictionary):
	download_id = id
	download_data = data
	start_time = Time.get_ticks_msec() / 1000.0
	
	var filename = data.get("filename", "Unknown file")
	filename_label.text = filename
	status_label.text = "Starting download..."
	progress_bar.value = 0
	
	_animate_entrance()

func _animate_entrance():
	if not is_inside_tree():
		return
		
	var download_container = get_parent()
	var anchor_container = download_container.get_parent() if download_container else null
	
	if anchor_container and anchor_container.name == "DownloadAnchor" and download_container.get_child_count() == 1:
		var tween = create_tween()
		if tween:
			var tween_property = tween.tween_property(anchor_container, "offset_left", -381, 0.3)
			if tween_property:
				tween_property.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		call_deferred("_animate_individual_entrance")

func _animate_individual_entrance():
	if not is_inside_tree():
		return
	
	var original_x = position.x
	position.x += 400 # Move off-screen to the right
	
	var tween = create_tween()
	if tween:
		var slide_property = tween.tween_property(self, "position:x", original_x, 0.3)
		if slide_property:
			slide_property.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func update_progress(progress_percent: float, bytes_downloaded: int = 0, total_bytes: int = 0):
	progress_bar.value = progress_percent
	
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - start_time
	var status_text = ""
	
	if total_bytes > 0:
		var speed_bps = bytes_downloaded / elapsed_time if elapsed_time > 0 else 0
		
		var remaining_bytes = total_bytes - bytes_downloaded
		var eta_seconds = remaining_bytes / speed_bps if speed_bps > 0 else 0
		
		status_text = NetworkRequest.format_bytes(bytes_downloaded) + " / " + NetworkRequest.format_bytes(total_bytes)
		if speed_bps > 0:
			status_text += " (" + NetworkRequest.format_bytes(int(speed_bps)) + "/s)"
		if eta_seconds > 0 and eta_seconds < 3600:
			status_text += " - %d seconds left" % int(eta_seconds)
	else:
		status_text = "%.0f%% complete" % progress_percent
	
	status_label.text = status_text

func set_completed(file_path: String):
	progress_bar.value = 100
	status_label.text = "Download complete: " + file_path.get_file()
	cancel_button.text = "✓"
	cancel_button.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	_animate_exit()

func set_error(error_message: String):
	status_label.text = "Error: " + error_message
	cancel_button.text = "✕"
	progress_bar.modulate = Color.RED
	
	await get_tree().create_timer(4.0).timeout
	_animate_exit()

func _animate_exit():
	if not is_inside_tree():
		queue_free()
		return
	
	var download_container = get_parent()
	var anchor_container = download_container.get_parent() if download_container else null
	
	var is_last_download = download_container and download_container.get_child_count() == 1
	
	var tween = create_tween()
	if tween:
		var slide_property = tween.tween_property(self, "position:x", position.x + 400, 0.25)
		if slide_property:
			slide_property.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		
		await tween.finished
	
	if is_last_download and anchor_container and anchor_container.name == "DownloadAnchor":
		var container_tween = create_tween()
		if container_tween:
			var container_property = container_tween.tween_property(anchor_container, "offset_left", 381, 0.25)
			if container_property:
				container_property.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			await container_tween.finished
	
	queue_free()

func _on_cancel_pressed():
	download_cancelled.emit(download_id)
	_animate_exit()
