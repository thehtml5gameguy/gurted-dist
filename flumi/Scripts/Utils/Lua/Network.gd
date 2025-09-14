class_name LuaNetworkUtils
extends RefCounted


static var gurt_client: GurtProtocolClient = null
static var current_domain: String = ""
static var client_last_used: int = 0
static var client_timeout_ms: int = 30000 # 30 seconds timeout for idle connections

static func setup_network_api(vm: LuauVM):
	vm.lua_pushcallable(_lua_fetch_handler, "fetch")
	vm.lua_setglobal("fetch")

static func resolve_fetch_url(url: String) -> String:
	if url.begins_with("http://") or url.begins_with("https://") or url.begins_with("gurt://"):
		return url
	
	var main_node = Engine.get_main_loop().current_scene

	if main_node and main_node.has_method("get_current_url"):
		current_domain = main_node.get_current_url()
	
	if current_domain.is_empty():
		if url.begins_with("/"):
			return "gurt://" + url.substr(1)
		else:
			return "gurt://" + url
	
	return URLUtils.resolve_url(current_domain, url)

static func _lua_fetch_handler(vm: LuauVM) -> int:
	var original_url: String = vm.luaL_checkstring(1)
	var options: Dictionary = {}
	
	if vm.lua_gettop() >= 2 and vm.lua_istable(2):
		options = vm.lua_todictionary(2)
	
	# Resolve relative URLs and default to gurt:// protocol
	var url = resolve_fetch_url(original_url)
	
	# Default options
	var method = options.get("method", "GET").to_upper()
	var headers = options.get("headers", {})
	var body = options.get("body", "")
	
	# Set request options
	var headers_array: PackedStringArray = []
	var headers_dict = {}
	var has_user_agent = false
	for header_name in headers:
		if str(header_name).to_lower() == "user-agent":
			has_user_agent = true
		headers_array.append(str(header_name) + ": " + str(headers[header_name]))
		headers_dict[str(header_name)] = str(headers[header_name])
	
	if not has_user_agent:
		var ua_value = UserAgent.get_user_agent()
		headers_array.append("User-Agent: " + ua_value)
		headers_dict["User-Agent"] = ua_value
	
	var start_ms = Time.get_ticks_msec()
	var response_data = make_http_request(url, method, headers_array, str(body))
	var elapsed_ms = Time.get_ticks_msec() - start_ms

	NetworkManager.call_deferred("add_completed_request", url, method, true, int(response_data.status), str(response_data.status_text), response_data.headers, str(response_data.body), [], headers_dict, str(body), float(elapsed_ms))
	
	# Create response object with actual data
	vm.lua_newtable()
	
	# Add response properties
	vm.lua_pushinteger(response_data.status)
	vm.lua_setfield(-2, "status")
	
	vm.lua_pushstring(response_data.status_text)
	vm.lua_setfield(-2, "statusText")
	
	# Convert response headers to table
	vm.lua_newtable()
	for header_name in response_data.headers:
		vm.lua_pushstring(response_data.headers[header_name])
		vm.lua_setfield(-2, header_name.to_lower())
	vm.lua_setfield(-2, "headers")
	
	# Store response body
	vm.lua_pushstring(response_data.body)
	vm.lua_setfield(-2, "_response_body")
	
	# Add response methods
	vm.lua_pushcallable(_response_text_handler, "response.text")
	vm.lua_setfield(-2, "text")
	
	vm.lua_pushcallable(_response_json_handler, "response.json")
	vm.lua_setfield(-2, "json")
	
	vm.lua_pushcallable(_response_ok_handler, "response.ok")
	vm.lua_setfield(-2, "ok")
	
	return 1

static func _response_text_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_response_body")
	var response_text = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	vm.lua_pushstring(response_text)
	return 1

static func _response_json_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "_response_body")
	var response_text = vm.lua_tostring(-1)
	vm.lua_pop(1)
	
	var json = JSON.new()
	var parse_result = json.parse(response_text)
	
	if parse_result == OK:
		vm.lua_pushvariant(json.data)
	else:
		vm.luaL_error("Invalid JSON in response")
	
	return 1

static func _response_ok_handler(vm: LuauVM) -> int:
	vm.luaL_checktype(1, vm.LUA_TTABLE)
	
	vm.lua_getfield(1, "status")
	var status = vm.lua_tointeger(-1)
	vm.lua_pop(1)
	
	vm.lua_pushboolean(status >= 200 and status < 300)
	return 1

static func make_http_request(url: String, method: String, headers: PackedStringArray, body: String) -> Dictionary:
	if url.begins_with("gurt://"):
		return make_gurt_request(url, method, headers, body)
	var http_client = HTTPClient.new()
	var response_data = {
		"status": 0,
		"status_text": "Network Error",
		"headers": {},
		"body": ""
	}
	
	# Parse URL
	var url_parts = url.split("://")
	if url_parts.size() < 2:
		response_data.status = 400
		response_data.status_text = "Bad Request - Invalid URL"
		return response_data
	
	var protocol = url_parts[0].to_lower()
	var use_ssl = (protocol == "https" or protocol == "gurt+ssl")
	var remaining_url = url_parts[1]
	
	var host_path = remaining_url.split("/", false, 1)
	var host = host_path[0]
	var path = "/" + (host_path[1] if host_path.size() > 1 else "")
	
	# Extract port if specified
	var port = 80
	if use_ssl:
		port = 443
	
	var host_parts = host.split(":")
	if host_parts.size() > 1:
		host = host_parts[0]
		port = host_parts[1].to_int()
	
	# Connect to host
	var error: Error
	if use_ssl:
		var tls_options = TLSOptions.client()
		error = http_client.connect_to_host(host, port, tls_options)
	else:
		error = http_client.connect_to_host(host, port)
	if error != OK:
		response_data.status = 0
		response_data.status_text = "Connection Failed"
		return response_data
	
	# Wait for connection
	var timeout_count = 0
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		OS.delay_msec(10)
		timeout_count += 1
		if timeout_count > 300:  # 3 second timeout
			response_data.status = 0
			response_data.status_text = "Connection Timeout"
			return response_data
	
	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		response_data.status = 0
		response_data.status_text = "Connection Failed"
		return response_data
	
	# Convert method string to HTTPClient.Method enum
	var http_method: HTTPClient.Method
	match method:
		"GET":
			http_method = HTTPClient.METHOD_GET
		"POST":
			http_method = HTTPClient.METHOD_POST
		"PUT":
			http_method = HTTPClient.METHOD_PUT
		"DELETE":
			http_method = HTTPClient.METHOD_DELETE
		"HEAD":
			http_method = HTTPClient.METHOD_HEAD
		"OPTIONS":
			http_method = HTTPClient.METHOD_OPTIONS
		"PATCH":
			http_method = HTTPClient.METHOD_PATCH
		_:
			http_method = HTTPClient.METHOD_GET
	
	# Make request
	error = http_client.request(http_method, path, headers, body)
	if error != OK:
		response_data.status = 0
		response_data.status_text = "Request Failed"
		return response_data
	
	# Wait for response
	timeout_count = 0
	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		OS.delay_msec(10)
		timeout_count += 1
		if timeout_count > 1000: # 10 second timeout
			response_data.status = 0
			response_data.status_text = "Request Timeout"
			return response_data
	
	if http_client.get_status() != HTTPClient.STATUS_BODY and http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		response_data.status = 0
		response_data.status_text = "Request Failed"
		return response_data
	
	# Get response
	if http_client.has_response():
		response_data.status = http_client.get_response_code()
		
		# Get status text
		match response_data.status:
			200: response_data.status_text = "OK"
			201: response_data.status_text = "Created"
			204: response_data.status_text = "No Content"
			400: response_data.status_text = "Bad Request"
			401: response_data.status_text = "Unauthorized"
			403: response_data.status_text = "Forbidden"
			404: response_data.status_text = "Not Found"
			500: response_data.status_text = "Internal Server Error"
			_: response_data.status_text = "Unknown"
		
		# Get response headers
		var response_headers = http_client.get_response_headers_as_dictionary()
		response_data.headers = response_headers
		
		# Get response body
		var body_bytes = PackedByteArray()
		timeout_count = 0
		while http_client.get_status() == HTTPClient.STATUS_BODY:
			http_client.poll()
			var chunk = http_client.read_response_body_chunk()
			if chunk.size() > 0:
				body_bytes.append_array(chunk)
				timeout_count = 0
			else:
				OS.delay_msec(10)
				timeout_count += 1
				if timeout_count > 1000: # 10 second timeout for body
					break
		
		response_data.body = body_bytes.get_string_from_utf8()
	
	http_client.close()
	return response_data

static func cleanup_idle_client():
	if gurt_client != null and Time.get_ticks_msec() - client_last_used > client_timeout_ms:
		gurt_client.disconnect()
		gurt_client = null
		current_domain = ""

static func get_or_create_gurt_client(domain: String) -> GurtProtocolClient:
	cleanup_idle_client()
	
	if gurt_client != null and current_domain == domain:
		client_last_used = Time.get_ticks_msec()
		return gurt_client
	
	if gurt_client != null:
		gurt_client.disconnect()
		gurt_client = null
	
	gurt_client = GurtProtocolClient.new()
	
	for ca_cert in CertificateManager.trusted_ca_certificates:
		gurt_client.add_ca_certificate(ca_cert)
	
	if not gurt_client.create_client_with_dns(10, GurtProtocol.DNS_SERVER_IP, GurtProtocol.DNS_SERVER_PORT):
		gurt_client = null
		current_domain = ""
		return null
	
	current_domain = domain
	client_last_used = Time.get_ticks_msec()
	return gurt_client

static func make_gurt_request(url: String, method: String, headers: PackedStringArray, body: String) -> Dictionary:
	var response_data = {
		"status": 0,
		"status_text": "Network Error",
		"headers": {},
		"body": ""
	}
	
	var domain_part = url.replace("gurt://", "")
	if domain_part.contains("/"):
		domain_part = domain_part.split("/")[0]
	
	var client = get_or_create_gurt_client(domain_part)
	if client == null:
		response_data.status = 0
		response_data.status_text = "Connection Failed"
		return response_data
	
	# Convert headers array to dictionary
	var headers_dict = {}
	for header in headers:
		var parts = header.split(":", 1)
		if parts.size() == 2:
			headers_dict[parts[0].strip_edges()] = parts[1].strip_edges()
	
	# Prepare request options
	var options = {
		"method": method
	}
	
	if not headers_dict.is_empty():
		options["headers"] = headers_dict
	
	if not body.is_empty():
		options["body"] = body
	
	var response = client.request(url, options)
	
	if not response:
		response_data.status = 0
		response_data.status_text = "No Response"
		return response_data
	
	response_data.status = response.status_code
	response_data.status_text = response.status_message if response.status_message else "OK"
	response_data.headers = response.headers if response.headers else {}
	
	var body_content = response.body if response.body else ""
	if body_content is PackedByteArray:
		response_data.body = body_content.get_string_from_utf8()
	else:
		response_data.body = str(body_content)
	
	return response_data

static func cleanup_connections():
	if gurt_client != null:
		gurt_client.disconnect()
		gurt_client = null
		current_domain = ""
