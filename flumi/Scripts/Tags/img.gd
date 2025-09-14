extends TextureRect

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	var src = element.get_attribute("src")
	if !src: return print("Ignoring <img/> tag without \"src\" attribute.")
	
	load_image_async(src, element, parser)

func load_image_async(src: String, element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	# Wait until this node is in the scene tree
	if not is_inside_tree():
		await tree_entered
	
	texture = await Network.fetch_image(src)
	
	if !is_instance_valid(texture): 
		print("Failed to load image: ", src)
		return
	
	var element_styles = parser.get_element_styles_internal(element, "")
	var has_width = element_styles.has("width")
	var has_height = element_styles.has("height")
	
	if not has_width and not has_height:
		var texture_size = texture.get_size()
		custom_minimum_size = texture_size
		size = texture_size
	else:
		var width_val = element_styles.get("width", "")
		var height_val = element_styles.get("height", "")
		
		if width_val == "100%" and height_val == "100%" or width_val == "full" and height_val == "full":
			size_flags_horizontal = Control.SIZE_EXPAND_FILL
			size_flags_vertical = Control.SIZE_EXPAND_FILL
			custom_minimum_size = Vector2.ZERO
		else:
			# Handle cases where only width or only height is specified
			var texture_size = texture.get_size()
			var aspect_ratio = texture_size.x / texture_size.y
			
			if has_width and not has_height:
				# Only width specified - calculate height to maintain aspect ratio
				var width_pixels = SizingUtils.parse_size_value(width_val)
				if width_pixels != null and typeof(width_pixels) != TYPE_STRING and width_pixels > 0:
					var calculated_height = width_pixels / aspect_ratio
					custom_minimum_size = Vector2(width_pixels, calculated_height)
			elif has_height and not has_width:
				# Only height specified - calculate width to maintain aspect ratio  
				var height_pixels = SizingUtils.parse_size_value(height_val)
				if height_pixels != null and typeof(height_pixels) != TYPE_STRING and height_pixels > 0:
					var calculated_width = height_pixels * aspect_ratio
					custom_minimum_size = Vector2(calculated_width, height_pixels)
			elif has_width and has_height:
				# Both specified - use both values
				var width_pixels = SizingUtils.parse_size_value(width_val)
				var height_pixels = SizingUtils.parse_size_value(height_val) 
				if width_pixels != null and typeof(width_pixels) != TYPE_STRING and width_pixels > 0 and \
				   height_pixels != null and typeof(height_pixels) != TYPE_STRING and height_pixels > 0:
					custom_minimum_size = Vector2(width_pixels, height_pixels)
