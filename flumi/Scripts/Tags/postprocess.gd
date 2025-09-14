class_name HTMLPostprocess
extends Control

const Network = preload("res://Scripts/Network.gd")

var element: HTMLParser.HTMLElement
var parser: HTMLParser
var shader_material: ShaderMaterial
var built_in_shaders = {
	"crt": "res://Shaders/crt.gdshader",
	"film": "res://Shaders/film.gdshader",
	"vignette": "res://Shaders/vignette.gdshader",
	"pencil": "res://Shaders/pencil.gdshader",
	"snowfall": "res://Shaders/snowfall.gdshader",
	"chrome": "res://Shaders/chrome.gdshader",
	"rblur": "res://Shaders/rblur.gdshader",
	"lensflare": "res://Shaders/lensflare.gdshader",
	"foliage": "res://Shaders/foliage.gdshader",
	"dither": "res://Shaders/dither.gdshader"
}

func init(element_: HTMLParser.HTMLElement, parser_: HTMLParser):
	element = element_
	parser = parser_
	
	var preset = element.get_attribute("preset")
	if preset and built_in_shaders.has(preset):
		await apply_preset_shader(preset)
	
	elif element.has_attribute("src"):
		await load_external_shader()
	
	elif not element.text_content.is_empty():
		apply_inline_shader()

func apply_preset_shader(preset_name: String):
	var shader_resource = built_in_shaders[preset_name]
	var shader = load(shader_resource)
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	shader_material.set_shader_parameter("u_bgTexture", load("res://Assets/Textures/parchment.jpg"))
	shader_material.set_shader_parameter("u_patternTexture", load("res://Assets/Textures/pencil.jpg"))
	
	var BLUE_NOISE = load("res://Assets/Textures/blue_noise.png")
	shader_material.set_shader_parameter("uTexBlueNoise", BLUE_NOISE)
	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.colors = [Color("#8B4513"), Color("#CD853F"), Color("#D2691E"), Color("#B22222"), Color("#A0522D")]
	gradient_texture.gradient = gradient
	shader_material.set_shader_parameter("pallete", gradient_texture)
	
	apply_shader_uniforms()
	apply_postprocessing_to_viewport()

func load_external_shader():
	var src = element.get_attribute("src")
	
	var main = Engine.get_main_loop().current_scene
	var resolved_url = URLUtils.resolve_url(main.current_domain, src)
	
	var network = Network.new()
	var response = await network.fetch_content(resolved_url)
	
	if response.success:
		var shader_code = response.content.get_string_from_utf8()
		var shader = Shader.new()
		shader.code = shader_code
		
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		
		apply_shader_uniforms()
		apply_postprocessing_to_viewport()
	else:
		print("Failed to load shader from: ", resolved_url)

func apply_inline_shader():
	var shader_code = element.text_content.strip_edges()
	if shader_code.is_empty():
		return
	
	var shader = Shader.new()
	shader.code = shader_code
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	apply_shader_uniforms()
	apply_postprocessing_to_viewport()

func apply_shader_uniforms():
	if not shader_material or not shader_material.shader:
		return
	
	for attr_name in element.attributes:
		if attr_name in ["src", "preset"]:
			continue
		
		var attr_value = element.get_attribute(attr_name)
		var uniform_value = parse_uniform_value(attr_value)
		
		if uniform_value != null:
			shader_material.set_shader_parameter(attr_name, uniform_value)

func parse_uniform_value(value_string: String):
	if value_string.is_valid_float():
		return value_string.to_float()
	
	if value_string.is_valid_int():
		return value_string.to_int()
	
	if value_string.to_lower() == "true":
		return true
	elif value_string.to_lower() == "false":
		return false
	
	if value_string.begins_with("Vector2(") or value_string.begins_with("vec2("):
		var vec_str = value_string.replace("Vector2(", "").replace("vec2(", "").replace(")", "")
		var components = vec_str.split(",")
		if components.size() == 2:
			return Vector2(components[0].strip_edges().to_float(), components[1].strip_edges().to_float())
	
	if value_string.begins_with("Vector3(") or value_string.begins_with("vec3("):
		var vec_str = value_string.replace("Vector3(", "").replace("vec3(", "").replace(")", "")
		var components = vec_str.split(",")
		if components.size() == 3:
			return Vector3(components[0].strip_edges().to_float(), components[1].strip_edges().to_float(), components[2].strip_edges().to_float())
	
	if value_string.begins_with("Vector4(") or value_string.begins_with("vec4("):
		var vec_str = value_string.replace("Vector4(", "").replace("vec4(", "").replace(")", "")
		var components = vec_str.split(",")
		if components.size() == 4:
			return Vector4(components[0].strip_edges().to_float(), components[1].strip_edges().to_float(), components[2].strip_edges().to_float(), components[3].strip_edges().to_float())
	
	if value_string.begins_with("#"):
		return Color(value_string)
	
	return value_string

func apply_postprocessing_to_viewport():
	if not shader_material:
		return
	
	var main_scene = Engine.get_main_loop().current_scene
	var active_tab = main_scene.get_active_tab()
	var panel_container = active_tab.background_panel
	
	var existing_overlay = panel_container.get_node_or_null("PostprocessOverlay")
	if existing_overlay:
		existing_overlay.queue_free()
	
	var overlay_rect = ColorRect.new()
	overlay_rect.name = "PostprocessOverlay"
	overlay_rect.material = shader_material
	overlay_rect.color = Color.WHITE
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_rect.z_index = 100
	
	panel_container.add_child(overlay_rect)
