extends RefCounted
class_name GurtProtocol

static var DNS_SERVER_IP: String = "135.125.163.131"
static var DNS_SERVER_PORT: int = 4878

static func set_dns_server(ip_port: String):
	if ":" in ip_port:
		var parts = ip_port.split(":")
		DNS_SERVER_IP = parts[0]
		DNS_SERVER_PORT = parts[1].to_int()
	else:
		DNS_SERVER_IP = ip_port
		DNS_SERVER_PORT = 4878

static func is_gurt_domain(url: String) -> bool:
	if url.begins_with("gurt://"):
		return true
	
	if not url.contains("://"):
		# Extract just the domain part (before any path)
		var domain = url.split("/")[0]
		
		# Handle port numbers (e.g., localhost:4878)
		if domain.contains(":"):
			domain = domain.split(":")[0]
		
		# Check if it's a direct address (localhost, IP, etc.)
		if is_direct_address(domain):
			return true
		
		# Check if it's a standard domain (e.g., example.com)
		var parts = domain.split(".")
		return parts.size() == 2
	
	return false

static func is_direct_address(domain: String) -> bool:
	# Check if it's already an IP address or localhost
	if domain.contains(":"):
		var parts = domain.split(":")
		domain = parts[0]
	
	return domain == "localhost" or domain == "127.0.0.1" or is_ip_address(domain)

static func is_ip_address(address: String) -> bool:
	var parts = address.split(".")
	if parts.size() != 4:
		return false
	
	for part in parts:
		if not part.is_valid_int():
			return false
		var num = part.to_int()
		if num < 0 or num > 255:
			return false
	
	return true

static func resolve_gurt_domain(domain: String) -> String:
	if is_direct_address(domain):
		if domain == "localhost":
			return "127.0.0.1"
		return domain
	
	return domain

static func get_error_type(error_message: String) -> Dictionary:
	if "DNS server is not responding" in error_message or "Domain not found" in error_message:
		return {"code": "ERR_NAME_NOT_RESOLVED", "title": "This site can't be reached", "icon": "? :("}
	elif "timeout" in error_message.to_lower() or "timed out" in error_message.to_lower():
		return {"code": "ERR_CONNECTION_TIMED_OUT", "title": "This site can't be reached", "icon": "...?"}
	elif "Failed to fetch" in error_message or "No response" in error_message:
		return {"code": "ERR_CONNECTION_REFUSED", "title": "This site can't be reached", "icon": ">:("}
	elif "Invalid domain format" in error_message:
		return {"code": "ERR_INVALID_URL", "title": "This page isn't working", "icon": ":|"}
	else:
		return {"code": "ERR_UNKNOWN", "title": "Something went wrong", "icon": ">_<"}

static func create_error_page(error_message: String) -> PackedByteArray:
	var error_info = get_error_type(error_message)
	
	return ("""<head>
	<title>""" + error_info.title + """ - GURT</title>
	<meta name="theme-color" content="#f8f9fa">
	<style>
		body { bg-[#ffffff] text-[#202124] font-sans p-0 m-0 }
		.error-container { flex flex-col items-center justify-center max-w-[600px] mx-auto px-6 text-center }
		.error-icon { text-6xl mb-6 opacity-60 w-32 h-32 }
		.error-title { text-[#202124] text-2xl font-normal mb-4 line-height-1.3 }
		.error-subtitle { text-[#5f6368] text-base mb-6 line-height-1.4 }
		.error-code { bg-[#f8f9fa] text-[#5f6368] px-3 py-2 rounded-md font-mono text-sm inline-block mb-6 }
		.suggestions { text-left max-w-[400px] w-[500px] }
		.suggestion-title { text-[#202124] text-lg font-normal mb-3 }
		.suggestion-list { text-[#5f6368] text-sm line-height-1.6 }
		.suggestion-item { mb-2 pl-4 relative }
		.suggestion-item:before { content-"•" absolute left-0 top-0 text-[#5f6368] }
		.retry-button { bg-[#1a73e8] text-[#ffffff] px-6 py-3 rounded-md font-medium text-sm hover:bg-[#1557b0] active:bg-[#1246a0] cursor-pointer border-none mt-4 }
		.details-section { mt-8 pt-6 border-t border-[#e8eaed] }
		.details-toggle { text-[#1a73e8] text-sm cursor-pointer hover:underline }
		.details-content { bg-[#f8f9fa] text-[#5f6368] text-xs font-mono p-4 rounded-md mt-3 text-left display-none }
	</style>
	
	<script>
		gurt.select("#reload"):on("click", function()
			gurt.location.reload()
		end)
	</script>
</head>
<body>
	<div style="error-container">
		<p style="error-icon">""" + error_info.icon + """</p>
		
		<h1 style="error-title">""" + error_info.title + """</h1>
		
		<p style="error-subtitle">""" + error_message + """</p>
		
		<div style="error-code">""" + error_info.code + """</div>
		
		<div style="suggestions">
			<h2 style="suggestion-title">Try:</h2>
			<ul style="suggestion-list">
				<li style="suggestion-item">Checking if the domain is correctly registered</li>
				<li style="suggestion-item">Verifying your DNS server is running</li>
				<li style="suggestion-item">Checking your internet connection</li>
			</ul>
		</div>
		
		<button style="retry-button" id="reload">Reload</button>
	</div>
</body>""").to_utf8_buffer()
