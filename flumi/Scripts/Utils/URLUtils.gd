class_name URLUtils
extends RefCounted

static func resolve_url(base_url: String, relative_url: String) -> String:
	# If relative_url is already absolute, return it as-is
	if relative_url.begins_with("http://") or relative_url.begins_with("https://") or relative_url.begins_with("gurt://") or relative_url.begins_with("file://"):
		return relative_url
	
	# If empty, treat as relative to current domain
	if base_url.is_empty():
		return relative_url
	
	var clean_base = base_url.rstrip("/")
	
	# Parse scheme and host
	var scheme_end = clean_base.find("://")
	if scheme_end == -1:
		return relative_url
	
	var scheme = clean_base.substr(0, scheme_end + 3)
	var remainder = clean_base.substr(scheme_end + 3)
	
	if scheme == "file://":
		var file_path = remainder
		
		if OS.get_name() == "Windows":
			file_path = file_path.replace("/", "\\")
		
		if relative_url.begins_with("/"):
			return scheme + relative_url.substr(1)
		else:
			var base_dir = file_path.get_base_dir()
			if base_dir.is_empty():
				return scheme + relative_url
			else:
				var resolved_path = base_dir + "/" + relative_url
				resolved_path = resolved_path.replace("\\", "/")
				return scheme + resolved_path
	
	# Split remainder into host and path
	var first_slash = remainder.find("/")
	var host = ""
	var current_path_parts = []
	
	if first_slash == -1:
		# No path in base URL, just host
		host = remainder
	else:
		host = remainder.substr(0, first_slash)
		var path = remainder.substr(first_slash + 1)
		
		# Remove query parameters from the path for URL resolution
		var query_start = path.find("?")
		if query_start != -1:
			path = path.substr(0, query_start)
		
		if not path.is_empty():
			current_path_parts = path.split("/")
	
	var final_path_parts = []
	
	if relative_url.begins_with("/"):
		# Absolute path from root
		var href_path = relative_url.substr(1) if relative_url.length() > 1 else ""
		if not href_path.is_empty():
			final_path_parts = href_path.split("/")
	else:
		# Relative path
		final_path_parts = current_path_parts.duplicate()
		
		if final_path_parts.size() > 0:
			var last_part = final_path_parts[-1]
			if "." in last_part and not last_part.ends_with("/"):
				final_path_parts.resize(final_path_parts.size() - 1)
		
		var href_parts = relative_url.split("/")
		for part in href_parts:
			if part == "..":
				if final_path_parts.size() > 0:
					final_path_parts.resize(final_path_parts.size() - 1)
			elif part == "." or part == "":
				continue
			else:
				final_path_parts.append(part)
	
	var result = scheme + host
	if final_path_parts.size() > 0:
		result += "/" + "/".join(final_path_parts)
	
	return result

static func extract_domain(url: String) -> String:
	if url.is_empty():
		return ""
	
	var clean_url = url
	if clean_url.begins_with("gurt://"):
		clean_url = clean_url.substr(7)
	elif clean_url.begins_with("https://"):
		clean_url = clean_url.substr(8)
	elif clean_url.begins_with("http://"):
		clean_url = clean_url.substr(7)
	elif clean_url.begins_with("file://"):
		return "localhost"
	
	var slash_pos = clean_url.find("/")
	if slash_pos != -1:
		clean_url = clean_url.substr(0, slash_pos)
	
	return clean_url

static func is_local_file_url(url: String) -> bool:
	return url.begins_with("file://")

static func file_url_to_path(url: String) -> String:
	if not is_local_file_url(url):
		return ""
	
	var path = url.substr(7)  # Remove "file://"
	
	if path.begins_with("/") and path.length() > 2 and path.substr(2, 1) == ":":
		path = path.substr(1)
	elif path.length() > 1 and path.substr(1, 1) == ":":
		pass
	
	if OS.get_name() == "Windows":
		path = path.replace("/", "\\")
	
	return path

static func path_to_file_url(path: String) -> String:
	var clean_path = path
	
	clean_path = clean_path.replace("\\", "/")
	
	if OS.get_name() == "Windows":
		if not clean_path.begins_with("/"):
			clean_path = "/" + clean_path
	else:
		if not clean_path.begins_with("/"):
			clean_path = "/" + clean_path
	
	return "file://" + clean_path
