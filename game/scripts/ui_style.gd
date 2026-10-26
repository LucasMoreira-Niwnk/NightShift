extends RefCounted

const INK := Color(0.035, 0.055, 0.055, 0.96)
const ACCENT := Color(0.73, 0.67, 0.44)
const TEXT := Color(0.88, 0.9, 0.83)
const MUTED := Color(0.49, 0.59, 0.55)

static func card(color: Color = INK, radius: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color(0.21, 0.29, 0.26)
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

static func theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color(1, 0.94, 0.75))
	theme.set_stylebox("panel", "PanelContainer", card())
	theme.set_stylebox("panel", "PopupMenu", card())
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, card(Color(0.075, 0.105, 0.1)))
		theme.set_stylebox("hover", type, card(Color(0.14, 0.19, 0.16)))
		theme.set_stylebox("pressed", type, card(Color(0.2, 0.23, 0.16)))
		var focus := card(Color(0, 0, 0, 0))
		focus.border_color = ACCENT
		theme.set_stylebox("focus", type, focus)
		theme.set_color("font_color", type, TEXT)
	return theme
