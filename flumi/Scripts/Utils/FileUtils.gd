class_name FileUtils
extends RefCounted

static func read_local_file(file_path: String) -> Dictionary:
	var result = {"success": false, "content": PackedByteArray(), "error": ""}
	
	if not FileAccess.file_exists(file_path):
		result.error = "File not found: " + file_path
		return result
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		result.error = "Cannot open file: " + file_path
		return result
	
	var content = file.get_buffer(file.get_length())
	file.close()
	
	result.success = true
	result.content = content
	return result

static func is_directory(path: String) -> bool:
	return DirAccess.dir_exists_absolute(path)

static func is_html_file(file_path: String) -> bool:
	var extension = file_path.get_extension().to_lower()
	return extension in ["html", "htm"]

static func is_supported_file(file_path: String) -> bool:
	var extension = file_path.get_extension().to_lower()
	return extension in ["html", "htm", "txt", "css", "js"]

static func create_error_page(title: String, error_message: String) -> PackedByteArray:
	var html = """<head>
	<title>""" + title + """ - File Browser</title>
	<style>
		body { bg-[#ffffff] text-[#202124] font-sans p-6 m-0 }
		.error-container { max-w-[600px] mx-auto text-center mt-20 }
		.error-icon { text-6xl mb-4 }
		.error-title { text-2xl font-normal mb-4 }
		.error-message { text-[#5f6368] mb-6 }
	</style>
</head>
<body>
	<div style="error-container">
		<h1 style="error-title">""" + title + """</h1>
		<p style="error-message">""" + error_message + """</p>
	</div>
</body>"""
	
	return html.to_utf8_buffer()
