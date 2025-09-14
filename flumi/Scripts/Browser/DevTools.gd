extends Control

@onready var console: DevToolsConsole = $DevTools/TabContainer/Console

func _ready():
	connect_console_signals()

func connect_console_signals():
	if console:
		Trace.get_instance().log_message.connect(_on_trace_log_message)

func get_console() -> DevToolsConsole:
	return console

func _on_trace_log_message(message: String, level: String, timestamp: float):
	if console:
		console.add_log_entry(message, level, timestamp)

func _on_close_button_pressed():
	Engine.get_main_loop().current_scene._toggle_dev_tools()
