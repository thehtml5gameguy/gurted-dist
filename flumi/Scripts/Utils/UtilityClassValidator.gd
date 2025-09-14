class_name UtilityClassValidator
extends RefCounted

static var compiled_patterns: Array = []

# TODO: hardcoded colors gotta be swapped with Tailwind colors. stuff like "text-red-500" is considered a selector class
static func init_patterns():
	if compiled_patterns.size() == 0:
		var utility_patterns = [
			"^text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl)$",  # font sizes
			"^text-(left|center|right|justify)$",  # text alignment
			"^text-\\[.*\\]$",  # custom text colors
			"^text-(white|black|transparent|slate-\\d+|gray-\\d+|red-\\d+|green-\\d+|blue-\\d+|yellow-\\d+)$",  # text colors
			"^bg-\\[.*\\]$",  # custom bg colors
			"^bg-(white|black|transparent|slate-\\d+|gray-\\d+|red-\\d+|green-\\d+|blue-\\d+|yellow-\\d+)$",  # bg colors
			"^(w|h|min-w|min-h|max-w|max-h)-",  # sizing
			"^font-(bold|mono|italic|sans|serif)$",  # font styles
			"^font-\\[.*\\]$",  # custom font families with brackets
			"^font-[a-zA-Z][a-zA-Z0-9_-]*$",  # custom font families without brackets
			"^underline$",
			"^flex",  # flex utilities
			"^items-",  # align items
			"^justify-",  # justify content
			"^content-",  # align content
			"^self-",  # align self
			"^order-",  # order
			"^gap-",  # gap
			"^(p|px|py|pt|pr|pb|pl)-",  # padding
			"^rounded",  # border radius
			"^basis-",  # flex basis
			"^(mx|my|m)-auto$",  # margin auto for centering
			"^border$",  # general border
			"^border-\\d+$",  # border width (e.g., border-2)
			"^border-\\[.*\\]$",  # custom border width/color (e.g., border-[2px], border-[#ff0000])
			"^border-none$",  # border styles
			"^border-(t|r|b|l)$",  # individual border sides (e.g., border-t)
			"^border-(t|r|b|l)-\\d+$",  # individual border side widths (e.g., border-t-2)
			"^border-(t|r|b|l)-\\[.*\\]$",  # custom individual border sides (e.g., border-t-[2px])
			"^border-(t|r|b|l)-(white|black|transparent|slate-\\d+|gray-\\d+|red-\\d+|green-\\d+|blue-\\d+|yellow-\\d+)$",  # individual border side colors
			"^border-(white|black|transparent|slate-\\d+|gray-\\d+|red-\\d+|green-\\d+|blue-\\d+|yellow-\\d+)$",  # border colors
			"^opacity-\\[.*\\]$",  # custom opacity values
			"^z-\\[.*\\]$",  # custom z-index values
			"^cursor-[a-zA-Z-]+$",  # cursor types
			"^scale-(x-|y-)?\\d+$",  # scale utilities like scale-100, scale-x-75, scale-y-150
			"^scale-(x-|y-)?\\[.*\\]$",  # custom scale values like scale-[1.5], scale-x-[2.0]
			"^rotate-\\d+$",  # rotation utilities like rotate-45, rotate-90
			"^rotate-\\[.*\\]$",  # custom rotation values like rotate-[45deg], rotate-[3.5rad]
			"^transition(-colors|-opacity|-transform)?$",  # transition utilities
			"^(hover|active):",  # pseudo classes
		]
		for pattern in utility_patterns:
			var regex = RegEx.new()
			regex.compile(pattern)
			compiled_patterns.append(regex)

static func is_utility_class(cls: String) -> bool:
	# once
	init_patterns()

	for regex in compiled_patterns:
		if regex.search(cls):
			return true
	return false