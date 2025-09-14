extends LineEdit

# NOTE: this should be implemented to every Control element,
# so that it defocuses on click outside element, instead of focusing on another control node,
# but I find it impractical to simply paste to every script in Tags.
# Will hold onto the above for now, and only implement it in SearchBar for now
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0), size).has_point(evLocal.position):
			release_focus()
