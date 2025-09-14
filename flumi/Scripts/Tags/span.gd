class_name HTMLSpan
extends RichTextLabel

@onready var rich_text_label: RichTextLabel = self
@onready var background_rect: ColorRect = $BackgroundRect

func init(element: HTMLParser.HTMLElement, parser: HTMLParser) -> void:
	text = "[font_size=24]%s[/font_size]" % element.get_bbcode_formatted_text(parser)

func _ready():
	if has_meta("custom_css_background_color"):
		add_background_rect()

func add_background_rect():
	var color = get_meta("custom_css_background_color")
	background_rect.color = color
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
