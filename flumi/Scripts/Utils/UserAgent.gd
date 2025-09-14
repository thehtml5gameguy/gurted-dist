class_name UserAgent
extends RefCounted

# Generate Flumi browser user agent string
static func get_user_agent() -> String:
	var app_version = ProjectSettings.get_setting("application/config/version", "1.0.0")
	var godot_version = Engine.get_version_info()
	var os_name = OS.get_name()
	
	var arch = ""
	match os_name:
		"Windows":
			if OS.has_environment("PROCESSOR_ARCHITEW6432"):
				arch = "x64"
			elif OS.get_environment("PROCESSOR_ARCHITECTURE") == "AMD64":
				arch = "x64"
			else:
				arch = "x86"
		"Linux":
			arch = "X11"
		"macOS":
			arch = "Intel"
		_:
			arch = "Unknown"
	
	var user_agent = "Mozilla/5.0 (%s; %s) Flumi/%s GurtKit/%s Godot/%s.%s.%s (gurted.com)" % [
		os_name,
		arch,
		app_version,
		app_version,
		godot_version.major,
		godot_version.minor,
		godot_version.patch
	]
	return user_agent
