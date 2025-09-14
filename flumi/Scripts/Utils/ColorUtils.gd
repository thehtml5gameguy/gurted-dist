class_name ColorUtils
extends RefCounted

static func parse_color(color_string: String) -> Color:
	color_string = color_string.strip_edges()
	
	# Handle hex colors
	if color_string.begins_with("#"):
		return Color.from_string(color_string, Color.WHITE)
	
	# Handle rgb/rgba
	if color_string.begins_with("rgb"):
		var regex = RegEx.new()
		regex.compile("rgba?\\(([^)]+)\\)")
		var result = regex.search(color_string)
		if result:
			var values = result.get_string(1).split(",")
			if values.size() >= 3:
				var r = values[0].strip_edges().to_float() / 255.0
				var g = values[1].strip_edges().to_float() / 255.0
				var b = values[2].strip_edges().to_float() / 255.0
				var a = 1.0
				if values.size() >= 4:
					a = values[3].strip_edges().to_float()
				return Color(r, g, b, a)
	
	# Handle named colors - delegate to get_color function
	return get_color(color_string)

static func get_color(color_name: String) -> Color:
	# Common colors
	match color_name:
		"white": return Color.WHITE
		"black": return Color.BLACK
		"transparent": return Color.TRANSPARENT
		
		# Gray scale
		"slate-50": return Color.from_string("#f8fafc", Color.WHITE)
		"slate-100": return Color.from_string("#f1f5f9", Color.WHITE)
		"slate-200": return Color.from_string("#e2e8f0", Color.WHITE)
		"slate-300": return Color.from_string("#cbd5e1", Color.WHITE)
		"slate-400": return Color.from_string("#94a3b8", Color.WHITE)
		"slate-500": return Color.from_string("#64748b", Color.WHITE)
		"slate-600": return Color.from_string("#475569", Color.WHITE)
		"slate-700": return Color.from_string("#334155", Color.WHITE)
		"slate-800": return Color.from_string("#1e293b", Color.WHITE)
		"slate-900": return Color.from_string("#0f172a", Color.WHITE)
		"slate-950": return Color.from_string("#020617", Color.WHITE)
		
		"gray-50": return Color.from_string("#f9fafb", Color.WHITE)
		"gray-100": return Color.from_string("#f3f4f6", Color.WHITE)
		"gray-200": return Color.from_string("#e5e7eb", Color.WHITE)
		"gray-300": return Color.from_string("#d1d5db", Color.WHITE)
		"gray-400": return Color.from_string("#9ca3af", Color.WHITE)
		"gray-500": return Color.from_string("#6b7280", Color.WHITE)
		"gray-600": return Color.from_string("#4b5563", Color.WHITE)
		"gray-700": return Color.from_string("#374151", Color.WHITE)
		"gray-800": return Color.from_string("#1f2937", Color.WHITE)
		"gray-900": return Color.from_string("#111827", Color.WHITE)
		"gray-950": return Color.from_string("#030712", Color.WHITE)
		
		"zinc-50": return Color.from_string("#fafafa", Color.WHITE)
		"zinc-100": return Color.from_string("#f4f4f5", Color.WHITE)
		"zinc-200": return Color.from_string("#e4e4e7", Color.WHITE)
		"zinc-300": return Color.from_string("#d4d4d8", Color.WHITE)
		"zinc-400": return Color.from_string("#a1a1aa", Color.WHITE)
		"zinc-500": return Color.from_string("#71717a", Color.WHITE)
		"zinc-600": return Color.from_string("#52525b", Color.WHITE)
		"zinc-700": return Color.from_string("#3f3f46", Color.WHITE)
		"zinc-800": return Color.from_string("#27272a", Color.WHITE)
		"zinc-900": return Color.from_string("#18181b", Color.WHITE)
		"zinc-950": return Color.from_string("#09090b", Color.WHITE)
		
		"neutral-50": return Color.from_string("#fafafa", Color.WHITE)
		"neutral-100": return Color.from_string("#f5f5f5", Color.WHITE)
		"neutral-200": return Color.from_string("#e5e5e5", Color.WHITE)
		"neutral-300": return Color.from_string("#d4d4d4", Color.WHITE)
		"neutral-400": return Color.from_string("#a3a3a3", Color.WHITE)
		"neutral-500": return Color.from_string("#737373", Color.WHITE)
		"neutral-600": return Color.from_string("#525252", Color.WHITE)
		"neutral-700": return Color.from_string("#404040", Color.WHITE)
		"neutral-800": return Color.from_string("#262626", Color.WHITE)
		"neutral-900": return Color.from_string("#171717", Color.WHITE)
		"neutral-950": return Color.from_string("#0a0a0a", Color.WHITE)

		"stone-50": return Color.from_string("#fafaf9", Color.WHITE)
		"stone-100": return Color.from_string("#f5f5f4", Color.WHITE)
		"stone-200": return Color.from_string("#e7e5e4", Color.WHITE)
		"stone-300": return Color.from_string("#d6d3d1", Color.WHITE)
		"stone-400": return Color.from_string("#a8a29e", Color.WHITE)
		"stone-500": return Color.from_string("#78716c", Color.WHITE)
		"stone-600": return Color.from_string("#57534e", Color.WHITE)
		"stone-700": return Color.from_string("#44403c", Color.WHITE)
		"stone-800": return Color.from_string("#292524", Color.WHITE)
		"stone-900": return Color.from_string("#1c1917", Color.WHITE)
		"stone-950": return Color.from_string("#0c0a09", Color.WHITE)
		
		# Red
		"red-50": return Color.from_string("#fef2f2", Color.WHITE)
		"red-100": return Color.from_string("#fee2e2", Color.WHITE)
		"red-200": return Color.from_string("#fecaca", Color.WHITE)
		"red-300": return Color.from_string("#fca5a5", Color.WHITE)
		"red-400": return Color.from_string("#f87171", Color.WHITE)
		"red-500": return Color.from_string("#ef4444", Color.WHITE)
		"red-600": return Color.from_string("#dc2626", Color.WHITE)
		"red-700": return Color.from_string("#b91c1c", Color.WHITE)
		"red-800": return Color.from_string("#991b1b", Color.WHITE)
		"red-900": return Color.from_string("#7f1d1d", Color.WHITE)
		"red-950": return Color.from_string("#450a0a", Color.WHITE)

		# Orange
		"orange-50": return Color.from_string("#fff7ed", Color.WHITE)
		"orange-100": return Color.from_string("#ffedd5", Color.WHITE)
		"orange-200": return Color.from_string("#fed7aa", Color.WHITE)
		"orange-300": return Color.from_string("#fdba74", Color.WHITE)
		"orange-400": return Color.from_string("#fb923c", Color.WHITE)
		"orange-500": return Color.from_string("#f97316", Color.WHITE)
		"orange-600": return Color.from_string("#ea580c", Color.WHITE)
		"orange-700": return Color.from_string("#c2410c", Color.WHITE)
		"orange-800": return Color.from_string("#9a3412", Color.WHITE)
		"orange-900": return Color.from_string("#7c2d12", Color.WHITE)
		"orange-950": return Color.from_string("#431407", Color.WHITE)

		# Amber
		"amber-50": return Color.from_string("#fffbeb", Color.WHITE)
		"amber-100": return Color.from_string("#fef3c7", Color.WHITE)
		"amber-200": return Color.from_string("#fde68a", Color.WHITE)
		"amber-300": return Color.from_string("#fcd34d", Color.WHITE)
		"amber-400": return Color.from_string("#fbbf24", Color.WHITE)
		"amber-500": return Color.from_string("#f59e0b", Color.WHITE)
		"amber-600": return Color.from_string("#d97706", Color.WHITE)
		"amber-700": return Color.from_string("#b45309", Color.WHITE)
		"amber-800": return Color.from_string("#92400e", Color.WHITE)
		"amber-900": return Color.from_string("#78350f", Color.WHITE)
		"amber-950": return Color.from_string("#451a03", Color.WHITE)

		# Yellow
		"yellow-50": return Color.from_string("#fefce8", Color.WHITE)
		"yellow-100": return Color.from_string("#fef9c3", Color.WHITE)
		"yellow-200": return Color.from_string("#fef08a", Color.WHITE)
		"yellow-300": return Color.from_string("#fde047", Color.WHITE)
		"yellow-400": return Color.from_string("#facc15", Color.WHITE)
		"yellow-500": return Color.from_string("#eab308", Color.WHITE)
		"yellow-600": return Color.from_string("#ca8a04", Color.WHITE)
		"yellow-700": return Color.from_string("#a16207", Color.WHITE)
		"yellow-800": return Color.from_string("#854d0e", Color.WHITE)
		"yellow-900": return Color.from_string("#713f12", Color.WHITE)
		"yellow-950": return Color.from_string("#422006", Color.WHITE)
		
		# Lime
		"lime-50": return Color.from_string("#f7fee7", Color.WHITE)
		"lime-100": return Color.from_string("#ecfccb", Color.WHITE)
		"lime-200": return Color.from_string("#d9f99d", Color.WHITE)
		"lime-300": return Color.from_string("#bef264", Color.WHITE)
		"lime-400": return Color.from_string("#a3e635", Color.WHITE)
		"lime-500": return Color.from_string("#84cc16", Color.WHITE)
		"lime-600": return Color.from_string("#65a30d", Color.WHITE)
		"lime-700": return Color.from_string("#4d7c0f", Color.WHITE)
		"lime-800": return Color.from_string("#3f6212", Color.WHITE)
		"lime-900": return Color.from_string("#365314", Color.WHITE)
		"lime-950": return Color.from_string("#1a2e05", Color.WHITE)

		# Green
		"green-50": return Color.from_string("#f0fdf4", Color.WHITE)
		"green-100": return Color.from_string("#dcfce7", Color.WHITE)
		"green-200": return Color.from_string("#bbf7d0", Color.WHITE)
		"green-300": return Color.from_string("#86efac", Color.WHITE)
		"green-400": return Color.from_string("#4ade80", Color.WHITE)
		"green-500": return Color.from_string("#22c55e", Color.WHITE)
		"green-600": return Color.from_string("#16a34a", Color.WHITE)
		"green-700": return Color.from_string("#15803d", Color.WHITE)
		"green-800": return Color.from_string("#166534", Color.WHITE)
		"green-900": return Color.from_string("#14532d", Color.WHITE)
		"green-950": return Color.from_string("#052e16", Color.WHITE)
		
		# Emerald
		"emerald-50": return Color.from_string("#ecfdf5", Color.WHITE)
		"emerald-100": return Color.from_string("#d1fae5", Color.WHITE)
		"emerald-200": return Color.from_string("#a7f3d0", Color.WHITE)
		"emerald-300": return Color.from_string("#6ee7b7", Color.WHITE)
		"emerald-400": return Color.from_string("#34d399", Color.WHITE)
		"emerald-500": return Color.from_string("#10b981", Color.WHITE)
		"emerald-600": return Color.from_string("#059669", Color.WHITE)
		"emerald-700": return Color.from_string("#047857", Color.WHITE)
		"emerald-800": return Color.from_string("#065f46", Color.WHITE)
		"emerald-900": return Color.from_string("#064e3b", Color.WHITE)
		"emerald-950": return Color.from_string("#022c22", Color.WHITE)

		# Teal
		"teal-50": return Color.from_string("#f0fdfa", Color.WHITE)
		"teal-100": return Color.from_string("#ccfbf1", Color.WHITE)
		"teal-200": return Color.from_string("#99f6e4", Color.WHITE)
		"teal-300": return Color.from_string("#5eead4", Color.WHITE)
		"teal-400": return Color.from_string("#2dd4bf", Color.WHITE)
		"teal-500": return Color.from_string("#14b8a6", Color.WHITE)
		"teal-600": return Color.from_string("#0d9488", Color.WHITE)
		"teal-700": return Color.from_string("#0f766e", Color.WHITE)
		"teal-800": return Color.from_string("#115e59", Color.WHITE)
		"teal-900": return Color.from_string("#134e4a", Color.WHITE)
		"teal-950": return Color.from_string("#042f2e", Color.WHITE)

		# Cyan
		"cyan-50": return Color.from_string("#ecfeff", Color.WHITE)
		"cyan-100": return Color.from_string("#cffafe", Color.WHITE)
		"cyan-200": return Color.from_string("#a5f3fc", Color.WHITE)
		"cyan-300": return Color.from_string("#67e8f9", Color.WHITE)
		"cyan-400": return Color.from_string("#22d3ee", Color.WHITE)
		"cyan-500": return Color.from_string("#06b6d4", Color.WHITE)
		"cyan-600": return Color.from_string("#0891b2", Color.WHITE)
		"cyan-700": return Color.from_string("#0e7490", Color.WHITE)
		"cyan-800": return Color.from_string("#155e75", Color.WHITE)
		"cyan-900": return Color.from_string("#164e63", Color.WHITE)
		"cyan-950": return Color.from_string("#083344", Color.WHITE)

		# Sky
		"sky-50": return Color.from_string("#f0f9ff", Color.WHITE)
		"sky-100": return Color.from_string("#e0f2fe", Color.WHITE)
		"sky-200": return Color.from_string("#bae6fd", Color.WHITE)
		"sky-300": return Color.from_string("#7dd3fc", Color.WHITE)
		"sky-400": return Color.from_string("#38bdf8", Color.WHITE)
		"sky-500": return Color.from_string("#0ea5e9", Color.WHITE)
		"sky-600": return Color.from_string("#0284c7", Color.WHITE)
		"sky-700": return Color.from_string("#0369a1", Color.WHITE)
		"sky-800": return Color.from_string("#075985", Color.WHITE)
		"sky-900": return Color.from_string("#0c4a6e", Color.WHITE)
		"sky-950": return Color.from_string("#082f49", Color.WHITE)
		
		# Blue
		"blue-50": return Color.from_string("#eff6ff", Color.WHITE)
		"blue-100": return Color.from_string("#dbeafe", Color.WHITE)
		"blue-200": return Color.from_string("#bfdbfe", Color.WHITE)
		"blue-300": return Color.from_string("#93c5fd", Color.WHITE)
		"blue-400": return Color.from_string("#60a5fa", Color.WHITE)
		"blue-500": return Color.from_string("#3b82f6", Color.WHITE)
		"blue-600": return Color.from_string("#2563eb", Color.WHITE)
		"blue-700": return Color.from_string("#1d4ed8", Color.WHITE)
		"blue-800": return Color.from_string("#1e40af", Color.WHITE)
		"blue-900": return Color.from_string("#1e3a8a", Color.WHITE)
		"blue-950": return Color.from_string("#172554", Color.WHITE)

		# Indigo
		"indigo-50": return Color.from_string("#eef2ff", Color.WHITE)
		"indigo-100": return Color.from_string("#e0e7ff", Color.WHITE)
		"indigo-200": return Color.from_string("#c7d2fe", Color.WHITE)
		"indigo-300": return Color.from_string("#a5b4fc", Color.WHITE)
		"indigo-400": return Color.from_string("#818cf8", Color.WHITE)
		"indigo-500": return Color.from_string("#6366f1", Color.WHITE)
		"indigo-600": return Color.from_string("#4f46e5", Color.WHITE)
		"indigo-700": return Color.from_string("#4338ca", Color.WHITE)
		"indigo-800": return Color.from_string("#3730a3", Color.WHITE)
		"indigo-900": return Color.from_string("#312e81", Color.WHITE)
		"indigo-950": return Color.from_string("#1e1b4b", Color.WHITE)

		# Violet
		"violet-50": return Color.from_string("#f5f3ff", Color.WHITE)
		"violet-100": return Color.from_string("#ede9fe", Color.WHITE)
		"violet-200": return Color.from_string("#ddd6fe", Color.WHITE)
		"violet-300": return Color.from_string("#c4b5fd", Color.WHITE)
		"violet-400": return Color.from_string("#a78bfa", Color.WHITE)
		"violet-500": return Color.from_string("#8b5cf6", Color.WHITE)
		"violet-600": return Color.from_string("#7c3aed", Color.WHITE)
		"violet-700": return Color.from_string("#6d28d9", Color.WHITE)
		"violet-800": return Color.from_string("#5b21b6", Color.WHITE)
		"violet-900": return Color.from_string("#4c1d95", Color.WHITE)
		"violet-950": return Color.from_string("#2e1065", Color.WHITE)

		# Purple
		"purple-50": return Color.from_string("#faf5ff", Color.WHITE)
		"purple-100": return Color.from_string("#f3e8ff", Color.WHITE)
		"purple-200": return Color.from_string("#e9d5ff", Color.WHITE)
		"purple-300": return Color.from_string("#d8b4fe", Color.WHITE)
		"purple-400": return Color.from_string("#c084fc", Color.WHITE)
		"purple-500": return Color.from_string("#a855f7", Color.WHITE)
		"purple-600": return Color.from_string("#9333ea", Color.WHITE)
		"purple-700": return Color.from_string("#7e22ce", Color.WHITE)
		"purple-800": return Color.from_string("#6b21a8", Color.WHITE)
		"purple-900": return Color.from_string("#581c87", Color.WHITE)
		"purple-950": return Color.from_string("#3b0764", Color.WHITE)

		# Fuchsia
		"fuchsia-50": return Color.from_string("#fdf4ff", Color.WHITE)
		"fuchsia-100": return Color.from_string("#fae8ff", Color.WHITE)
		"fuchsia-200": return Color.from_string("#f5d0fe", Color.WHITE)
		"fuchsia-300": return Color.from_string("#f0abfc", Color.WHITE)
		"fuchsia-400": return Color.from_string("#e879f9", Color.WHITE)
		"fuchsia-500": return Color.from_string("#d946ef", Color.WHITE)
		"fuchsia-600": return Color.from_string("#c026d3", Color.WHITE)
		"fuchsia-700": return Color.from_string("#a21caf", Color.WHITE)
		"fuchsia-800": return Color.from_string("#86198f", Color.WHITE)
		"fuchsia-900": return Color.from_string("#701a75", Color.WHITE)
		"fuchsia-950": return Color.from_string("#4a044e", Color.WHITE)

		# Pink
		"pink-50": return Color.from_string("#fdf2f8", Color.WHITE)
		"pink-100": return Color.from_string("#fce7f3", Color.WHITE)
		"pink-200": return Color.from_string("#fbcfe8", Color.WHITE)
		"pink-300": return Color.from_string("#f9a8d4", Color.WHITE)
		"pink-400": return Color.from_string("#f472b6", Color.WHITE)
		"pink-500": return Color.from_string("#ec4899", Color.WHITE)
		"pink-600": return Color.from_string("#db2777", Color.WHITE)
		"pink-700": return Color.from_string("#be185d", Color.WHITE)
		"pink-800": return Color.from_string("#9d174d", Color.WHITE)
		"pink-900": return Color.from_string("#831843", Color.WHITE)
		"pink-950": return Color.from_string("#500724", Color.WHITE)

		# Rose
		"rose-50": return Color.from_string("#fff1f2", Color.WHITE)
		"rose-100": return Color.from_string("#ffe4e6", Color.WHITE)
		"rose-200": return Color.from_string("#fecdd3", Color.WHITE)
		"rose-300": return Color.from_string("#fda4af", Color.WHITE)
		"rose-400": return Color.from_string("#fb7185", Color.WHITE)
		"rose-500": return Color.from_string("#f43f5e", Color.WHITE)
		"rose-600": return Color.from_string("#e11d48", Color.WHITE)
		"rose-700": return Color.from_string("#be123c", Color.WHITE)
		"rose-800": return Color.from_string("#9f1239", Color.WHITE)
		"rose-900": return Color.from_string("#881337", Color.WHITE)
		"rose-950": return Color.from_string("#4c0519", Color.WHITE)

		_: return Color.BLACK
