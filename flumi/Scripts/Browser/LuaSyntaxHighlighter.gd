@tool
class_name LuaSyntaxHighlighter
extends SyntaxHighlighter

@export_group("Colors")
@export var font_color: Color = Color.from_string("#d4d4d4", Color.WHITE)
@export var keyword_color: Color = Color.from_string("#c586c0", Color.WHITE)
@export var gurt_globals_color: Color = Color.from_string("#569cd6", Color.WHITE)
@export var function_color: Color = Color.from_string("#dcdcaa", Color.WHITE)
@export var member_color: Color = Color.from_string("#9cdcfe", Color.WHITE)
@export var number_color: Color = Color.from_string("#b5cea8", Color.WHITE)
@export var string_color: Color = Color.from_string("#ce9178", Color.WHITE)
@export var comment_color: Color = Color.from_string("#6a9955", Color.WHITE)
@export var symbol_color: Color = Color.from_string("#c586c0", Color.WHITE)

enum State { DEFAULT, IN_MULTILINE_COMMENT, IN_MULTILINE_STRING }
var _state_cache: Dictionary = {}

var _keywords: Dictionary = {}
var _built_in_functions: Dictionary = {}
var _gurt_globals: Dictionary = {}
var _member_keywords: Dictionary = {}

func _init() -> void:
	for k in ["and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"]:
		_keywords[k] = true

	for f in ["assert", "collectgarbage", "dofile", "error", "getmetatable", "ipairs", "load", "loadfile", "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawlen", "rawset", "require", "select", "setmetatable", "tonumber", "tostring", "type", "xpcall"]:
		_built_in_functions[f] = true
	
	for g in ["gurt", "trace", "JSON", "Time", "WebSocket", "Clipboard", "Regex", "setTimeout", "setInterval", "clearTimeout", "clearInterval", "fetch", "urlEncode", "urlDecode"]:
		_gurt_globals[g] = true

	var members = [
		"select", "selectAll", "create", "body", "location", "href", "reload", "goto", "query", "get", "has", "getAll",
		"log", "warn", "error", "text", "value", "visible", "children", "parent", "nextSibling", "previousSibling",
		"firstChild", "lastChild", "classList", "on", "append", "remove", "insertBefore", "insertAfter", "replace",
		"clone", "getAttribute", "setAttribute", "show", "hide", "focus", "unfocus", "createTween", "unsubscribe",
		"add", "remove", "toggle", "contains", "item", "length", "to", "duration", "easing", "transition", "play",
		"pause", "stop", "currentTime", "volume", "loop", "src", "playing", "paused", "withContext", "fillRect",
		"strokeRect", "clearRect", "drawCircle", "drawText", "setFont", "measureText", "beginPath", "moveTo",
		"lineTo", "closePath", "stroke", "fill", "arc", "quadraticCurveTo", "bezierCurveTo", "setStrokeStyle",
		"setFillStyle", "setLineWidth", "save", "translate", "rotate", "scale", "restore", "source", "ok", "json",
		"status", "statusText", "headers", "stringify", "parse", "now", "format", "date", "sleep", "benchmark",
		"timer", "delay", "elapsed", "reset", "complete", "remaining", "new", "send", "close", "readyState",
		"test", "match", "tostring", "replace", "replaceAll", "trim",
	]
	for m in members:
		_member_keywords[m] = true

func _is_whitespace(ch: String) -> bool:
	return ch == " " or ch == "\t"

func _clear_highlighting_cache():
	_state_cache.clear()

func _get_initial_state() -> int:
	return State.DEFAULT

func _get_line_state(p_line: int, p_state: int) -> int:
	var current_state: int = p_state
	var line_text: String = get_text_edit().get_line(p_line)
	var line_len: int = line_text.length()
	var i := 0
	while i < line_len:
		if current_state == State.DEFAULT:
			if i + 3 < line_len and line_text.substr(i, 4) == "--[[":
				current_state = State.IN_MULTILINE_COMMENT
				i += 4
				continue
			if i + 1 < line_len and line_text.substr(i, 2) == "[[":
				current_state = State.IN_MULTILINE_STRING
				i += 2
				continue
			if line_text[i] == "'" or line_text[i] == "\"":
				var quote = line_text[i]
				i += 1
				while i < line_len:
					if line_text[i] == "\\": i += 2; continue
					if line_text[i] == quote: break
					i += 1
		else:
			var end_idx = line_text.find("]]", i)
			if end_idx != -1:
				current_state = State.DEFAULT
				i = end_idx + 2
				continue
			else:
				i = line_len
		i += 1
	_state_cache[p_line] = current_state
	return current_state

func _get_line_syntax_highlighting(p_line: int) -> Dictionary:
	var color_map := {}
	var start_state: int = _state_cache.get(p_line - 1, _get_initial_state())
	
	var line_text: String = get_text_edit().get_line(p_line)
	var line_len: int = line_text.length()
	
	color_map[0] = {"color": font_color}
	
	var i := 0
	if start_state != State.DEFAULT:
		var end_idx = line_text.find("]]")
		var region_color = comment_color if start_state == State.IN_MULTILINE_COMMENT else string_color
		
		color_map[0] = {"color": region_color}
		if end_idx == -1:
			return color_map
		else:
			i = end_idx + 2
			if i < line_len:
				color_map[i] = {"color": font_color}
			start_state = State.DEFAULT
	while i < line_len:
		var start_col: int = i
		var current_char: String = line_text[i]

		if current_char == "-" and i + 1 < line_len and line_text[i+1] == "-":
			if not (i + 3 < line_len and line_text.substr(i, 4) == "--[["):
				color_map[i] = {"color": comment_color}
				return color_map

		if current_char == "\"" or current_char == "'":
			var quote = current_char
			var string_start = i
			i += 1
			while i < line_len:
				if line_text[i] == "\\": i += 2; continue
				if line_text[i] == quote: i += 1; break
				i += 1
			var string_end = i
			color_map[string_start] = {"color": string_color}
			if string_end < line_len:
				color_map[string_end] = {"color": font_color}
			continue

		if current_char.is_valid_int() or (current_char == "." and i + 1 < line_len and line_text[i+1].is_valid_int()):
			var is_hex = false
			if current_char == "0" and i + 1 < line_len and line_text[i+1].to_lower() == "x":
				i += 2; is_hex = true
			while i < line_len:
				var ch = line_text[i]
				if (is_hex and ch.is_valid_hex_number(false)) or \
				   (not is_hex and (ch.is_valid_int() or ch in "Ee.-+")):
					i += 1
				else:
					break
			var number_end = i
			color_map[start_col] = {"color": number_color}
			if number_end < line_len:
				color_map[number_end] = {"color": font_color}
			continue

		if current_char.is_valid_identifier() and not current_char.is_valid_int():
			while i < line_len and line_text[i].is_valid_identifier():
				i += 1
			var word = line_text.substr(start_col, i - start_col)
			
			var color = font_color
			if _keywords.has(word): color = keyword_color
			elif _gurt_globals.has(word): color = gurt_globals_color
			elif _built_in_functions.has(word): color = function_color
			else:
				var prev_char_idx = start_col - 1
				while prev_char_idx >= 0 and _is_whitespace(line_text[prev_char_idx]):
					prev_char_idx -= 1
				var next_char_idx = i
				while next_char_idx < line_len and _is_whitespace(line_text[next_char_idx]):
					next_char_idx += 1
				
				var is_member = prev_char_idx >= 0 and line_text[prev_char_idx] in [".", ":"]
				var is_function_call = next_char_idx < line_len and line_text[next_char_idx] == "("
				
				if is_member and _member_keywords.has(word): color = member_color
				elif is_function_call: color = function_color
			
			if color != font_color: color_map[start_col] = {"color": color}
			continue

		if not _is_whitespace(current_char):
			color_map[i] = {"color": symbol_color}
			if i + 1 < line_len:
				color_map[i + 1] = {"color": font_color}

		i += 1

	return color_map
