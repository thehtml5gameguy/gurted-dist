extends Control

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	# This is mainly for cases where <option> appears outside of <select>
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text(parser)
	add_child(label)
