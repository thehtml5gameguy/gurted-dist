class_name HTMLAudio
extends VBoxContainer

@onready var popup_panel: PopupPanel = $PopupPanel
@onready var play_button: Button = $PanelContainer/HBoxContainer/Play
@onready var time_label: RichTextLabel = $PanelContainer/HBoxContainer/RichTextLabel
@onready var progress_slider: HSlider = $PanelContainer/HBoxContainer/HSlider
@onready var volume_button: Button = $PanelContainer/HBoxContainer/Volume
@onready var volume_slider: VSlider = $PopupPanel/VSlider
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

const PLAY_ICON = preload("res://Assets/Icons/play.svg")
const PAUSE_ICON = preload("res://Assets/Icons/pause.svg")
const VOLUME_OFF = preload("res://Assets/Icons/volume-off.svg")
const VOLUME_2 = preload("res://Assets/Icons/volume-2.svg")

var current_element: HTMLParser.HTMLElement
var current_parser: HTMLParser
var is_muted = false
var initial_volume_value = 50.0
var is_playing = false
var user_initiated_play = false
var progress_timer: Timer
var updating_slider = false
var in_user_click_context = false

var volume: float = 0.5:
	set(value):
		volume = clamp(value, 0.0, 1.0)
		if audio_player:
			audio_player.volume_db = linear_to_db(volume)
		if volume_slider:
			volume_slider.value = volume * 100
	get:
		return volume

var loop: bool = false:
	set(value):
		loop = value
	get:
		return loop

var muted: bool = false:
	set(value):
		muted = value
		is_muted = value
		update_volume_display()
	get:
		return is_muted

func _ready():
	if popup_panel:
		popup_panel.hide()
	
	if volume_slider:
		initial_volume_value = volume_slider.value
		volume = initial_volume_value / 100.0
	
	if play_button:
		play_button.icon = PLAY_ICON
	
	if volume_button:
		volume_button.icon = VOLUME_2
	
	# Set up audio player
	if audio_player:
		audio_player.finished.connect(_on_audio_finished)
	
	progress_timer = Timer.new()
	progress_timer.wait_time = 0.5
	progress_timer.timeout.connect(_on_progress_timer_timeout)
	add_child(progress_timer)

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	current_element = element
	current_parser = parser
	
	# Parse attributes
	var src = element.get_attribute("src")
	var controls = element.has_attribute("controls")
	var loop_attr = element.has_attribute("loop")
	var muted_attr = element.has_attribute("muted")
	
	if not controls:
		visible = false
	
	if src.is_empty():
		return
	
	loop = loop_attr
	if muted_attr:
		muted = true
		is_muted = true
		update_volume_display()
	
	load_audio_async(src)
	parser.register_dom_node(element, self)

func load_audio_async(src: String) -> void:
	if not is_inside_tree():
		await tree_entered
	
	reset_stream_state()
	
	if src.begins_with("https://") or src.begins_with("gurt://"):
		await load_remote_audio(src)
	else:
		print("Audio loading error: Only HTTPS and GURT protocols are supported. Attempted: ", src)
		return

func load_remote_audio(src: String) -> void:
	if not (src.begins_with("https://") or src.begins_with("gurt://")):
		return
	
	if src.begins_with("https://"):
		await load_https_audio(src)
	elif src.begins_with("gurt://"):
		await load_gurt_audio(src)

func load_https_audio(src: String) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.download_chunk_size = 65536
	http_request.timeout = 30
	
	http_request.request_completed.connect(_on_audio_download_completed)
	var error = http_request.request(src)
	
	if error != OK:
		http_request.queue_free()
		return

func load_gurt_audio(src: String) -> void:
	var response = await Network.fetch_gurt_resource(src, true)
	if response is PackedByteArray and response.size() > 0:
		var audio_stream = load_audio_from_buffer(response, src)
		if audio_stream and audio_player:
			audio_player.stream = audio_stream
			on_stream_loaded()

func load_audio_from_buffer(data: PackedByteArray, file_path: String) -> AudioStream:
	if data.size() == 0:
		return null
	
	var extension = file_path.get_extension().to_lower()
	var audio_stream: AudioStream
	
	match extension:
		"ogg", "oga":
			audio_stream = AudioStreamOggVorbis.load_from_buffer(data)
		"wav", "wave":
			audio_stream = AudioStreamWAV.new()
			audio_stream.data = data
			audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
			audio_stream.mix_rate = 44100
			audio_stream.stereo = true
			audio_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		"mp3":
			audio_stream = AudioStreamMP3.load_from_buffer(data)
			if not audio_stream:
				audio_stream = AudioStreamMP3.new()
				audio_stream.data = data
	
	return audio_stream

func _on_audio_download_completed(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var http_request = get_children().filter(func(child): return child is HTTPRequest)[0]
	http_request.queue_free()
	
	if response_code < 200 or response_code >= 300:
		return
	
	if body.size() == 0:
		return
	
	var content_type = ""
	for header in headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.split(":")[1].strip_edges().to_lower()
			break
	
	var audio_stream: AudioStream

	# Determine format from content type
	var format_extension = ""
	if "ogg" in content_type or "vorbis" in content_type:
		format_extension = "ogg"
	elif "wav" in content_type or "wave" in content_type:
		format_extension = "wav"
	elif "mp3" in content_type or "mpeg" in content_type:
		format_extension = "mp3"
	else:
		var url_extension = current_element.get_attribute("src").get_extension().to_lower()
		if url_extension in ["ogg", "oga", "wav", "wave", "mp3"]:
			format_extension = url_extension
		else:
			return
	
	audio_stream = load_audio_from_buffer(body, "remote." + format_extension)
	
	if audio_stream:
		if audio_player:
			audio_player.stream = audio_stream
			on_stream_loaded()

func reset_stream_state():
	cached_duration = -1.0
	stream_load_failed = false

func on_stream_loaded():
	reset_stream_state()
	
	progress_slider.editable = true
	progress_slider.scrollable = true
	
	update_duration_display()
	
	if volume_slider:
		volume_slider.value = volume * 100
	
	if is_muted:
		update_volume_display()

func update_duration_display():
	if time_label:
		var duration = get_duration()
		time_label.text = "00:00/" + format_time(duration)

var last_progress_update: float = 0.0

func _on_progress_timer_timeout():
	if not is_playing or not audio_player.stream or updating_slider:
		return
	
	var current_pos = audio_player.get_playback_position()
	var total_length = audio_player.stream.get_length()
	
	var time_diff = abs(current_pos - last_progress_update)
	if time_diff < 0.1:
		return
	
	last_progress_update = current_pos
	
	if total_length > 0 and progress_slider:
		updating_slider = true
		progress_slider.value = (current_pos / total_length) * 100
		updating_slider = false
		
	if time_label:
		time_label.text = format_time(current_pos) + "/" + format_time(total_length)


var cached_duration: float = -1.0
var stream_load_failed: bool = false

func get_stream_length_safe() -> float:
	if not audio_player or not audio_player.stream:
		return 0.0
	
	if cached_duration > 0:
		return cached_duration
	
	if stream_load_failed:
		return 0.0
	
	var length = 0.0
	if audio_player.stream.has_method("get_length"):
		if audio_player.stream is AudioStreamOggVorbis:
			var ogg_stream = audio_player.stream as AudioStreamOggVorbis
			if not ogg_stream.packet_sequence:
				stream_load_failed = true
				return 0.0
		
		length = audio_player.stream.get_length()
		
		if length <= 0 or is_nan(length) or is_inf(length):
			if audio_player.stream is AudioStreamOggVorbis:
				stream_load_failed = true
			length = 0.0
		else:
			cached_duration = length
	
	return length

func format_time(seconds: float) -> String:
	var mins = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

func update_volume_display():
	if volume_button:
		if is_muted:
			volume_button.icon = VOLUME_OFF
		else:
			volume_button.icon = VOLUME_2
	
	if audio_player:
		if is_muted:
			audio_player.volume_db = -80
		else:
			audio_player.volume_db = linear_to_db(volume)

func play() -> bool:
	if not audio_player or not audio_player.stream:
		return false
	
	if stream_load_failed:
		return false
	
	if not user_initiated_play:
		return false
	
	if audio_player.stream is AudioStreamOggVorbis:
		var ogg_stream = audio_player.stream as AudioStreamOggVorbis
		if not ogg_stream.packet_sequence or ogg_stream.packet_sequence.granule_positions.size() == 0:
			stream_load_failed = true
			return false
	
	if audio_player.stream_paused:
		audio_player.stream_paused = false
	else:
		audio_player.play()
	
	is_playing = true
	if visible and play_button:
		play_button.icon = PAUSE_ICON
	
	if progress_timer:
		progress_timer.start()
	
	return true

func pause() -> void:
	if audio_player:
		audio_player.stream_paused = true
	is_playing = false
	if visible and play_button:
		play_button.icon = PLAY_ICON
	
	progress_timer.stop()

func stop() -> void:
	if audio_player:
		audio_player.stop()
	is_playing = false
	if visible and play_button:
		play_button.icon = PLAY_ICON
	
	progress_timer.stop()

func get_current_time() -> float:
	if audio_player:
		return audio_player.get_playback_position()
	return 0.0

func get_duration() -> float:
	if audio_player and audio_player.stream:
		return audio_player.stream.get_length()
	return 0.0

func set_current_time(time: float) -> void:
	if audio_player and audio_player.stream:
		if audio_player.stream_paused:
			audio_player.stream_paused = false
			audio_player.play(time) 
			audio_player.stream_paused = true
		else:
			audio_player.seek(time)

func _on_play_pressed():
	user_initiated_play = true
	if is_playing:
		pause()
	else:
		play()
	user_initiated_play = false

func _on_progress_slider_value_changed(value: float):
	if updating_slider:
		return
		
	if audio_player and audio_player.stream and progress_slider.editable:
		var total_length = audio_player.stream.get_length()
		if total_length > 0:
			var target_time = (value / 100.0) * total_length
			set_current_time(target_time)

func _on_audio_finished():
	if loop and audio_player:
		audio_player.play()
	else:
		is_playing = false
		
		if visible and progress_slider:
			progress_slider.value = 100
		if visible and time_label:
			var total_length = get_duration()
			time_label.text = format_time(total_length) + "/" + format_time(total_length)
		
		if visible and play_button:
			play_button.icon = PLAY_ICON
		
		if progress_timer:
			progress_timer.stop()

func _on_volume_pressed():
	is_muted = !is_muted
	update_volume_display()
	
	if popup_panel and popup_panel.is_visible():
		popup_panel.hide()

func _on_volume_mouse_entered():
	if not popup_panel or not volume_button:
		return
		
	if popup_panel.is_visible():
		return
	
	var h_offset = (volume_button.size.x - popup_panel.size.x) / 2
	var v_offset = volume_button.size.y + 17 
	
	popup_panel.position = volume_button.get_screen_position() + Vector2(h_offset, v_offset)
	popup_panel.show()

func _on_volume_mouse_exited():
	if not volume_slider or not popup_panel:
		return
		
	if volume_slider.value == initial_volume_value:
		await get_tree().create_timer(0.3).timeout
		
		var mouse_position = get_global_mouse_position()
		var popup_position = popup_panel.get_position()
		var popup_size = popup_panel.get_size()
		var popup_rect = Rect2(popup_position, popup_size)
		
		if not popup_rect.has_point(mouse_position):
			popup_panel.hide()

func _on_popup_panel_focus_exited() -> void:
	if popup_panel:
		popup_panel.hide()
	if volume_slider:
		initial_volume_value = volume_slider.value

func _on_volume_slider_value_changed(value: float) -> void:
	initial_volume_value = value
	volume = value / 100.0
	if not is_muted:
		update_volume_display()

func _deferred_play_with_user_context(is_user_initiated: bool) -> void:
	user_initiated_play = is_user_initiated
	play()
	user_initiated_play = false
