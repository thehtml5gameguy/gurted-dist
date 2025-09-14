extends Button

const HISTORY = preload("res://Scenes/BrowserMenus/history.tscn")
const SETTINGS = preload("res://Scenes/BrowserMenus/settings.tscn")
const HELP = preload("res://Scenes/BrowserMenus/help.tscn")

@onready var tab_container: TabManager = $"../../TabContainer"
@onready var main: Main = $"../../../"

var history_scene: PopupPanel = null
var settings_scene: PopupPanel = null
var help_scene: PopupPanel = null

func _on_pressed() -> void:
	%OptionsMenu.show()

func _input(_event: InputEvent) -> void:
	if _event is InputEventKey and _event.pressed and _event.ctrl_pressed:
		if _event.keycode == KEY_N:
			if _event.shift_pressed:
				# CTRL+SHIFT+N - New incognito window
				_on_options_menu_id_pressed(2)
				get_viewport().set_input_as_handled()
			else:
				# CTRL+N - New window
				_on_options_menu_id_pressed(1)
				get_viewport().set_input_as_handled()
		elif _event.keycode == KEY_H:
			# CTRL+H - History
			_on_options_menu_id_pressed(4)
			get_viewport().set_input_as_handled()
		elif _event.keycode == KEY_J:
			# CTRL+J - Downloads
			_on_options_menu_id_pressed(5)
			get_viewport().set_input_as_handled()

func _on_options_menu_id_pressed(id: int) -> void:
	if id == 0: # new tab
		tab_container.create_tab()
	if id == 1: # new window
		OS.create_process(OS.get_executable_path(), [])
	if id == 2: # new ingonito window
		# TODO: handle incognito
		OS.create_process(OS.get_executable_path(), ["--incognito"])
	if id == 4: # history
		show_history()
	if id == 5: # downloads
		show_downloads()
	if id == 8: # help
		show_help()
	if id == 9: # settings
		show_settings()
	if id == 10: # exit
		get_tree().quit()

func show_history() -> void:
	if history_scene == null:
		history_scene = HISTORY.instantiate()
		history_scene.navigate_to_url.connect(main.navigate_to_url)
		main.add_child(history_scene)
		
		history_scene.connect("popup_hide", _on_history_closed)
	else:
		history_scene.load_history()
		history_scene.show()

func _on_history_closed() -> void:
	if history_scene:
		history_scene.hide()

func show_downloads() -> void:
	main.download_manager.show_downloads_history()

func show_help() -> void:
	if help_scene == null:
		help_scene = HELP.instantiate()
		main.add_child(help_scene)
		
		help_scene.connect("popup_hide", _on_help_closed)
	else:
		help_scene.show()

func _on_help_closed() -> void:
	if help_scene:
		help_scene.hide()

func show_settings() -> void:
	if settings_scene == null:
		settings_scene = SETTINGS.instantiate()
		main.add_child(settings_scene)
		
		settings_scene.connect("popup_hide", _on_settings_closed)
	else:
		settings_scene.show()

func _on_settings_closed() -> void:
	if settings_scene:
		settings_scene.hide()
