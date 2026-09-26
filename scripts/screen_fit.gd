extends RefCounted
## Wide screens: the platformer shows more of the level at the sides instead of
## black bars. The picture is always 270 px tall and 480 to 720 px wide, so 16:9
## up to about 24:9 fills the screen. Anything wider gets thin bars at the sides.
## Older scenes that draw at a fixed 480 px call reset() to keep their layout.

const H := 270
const MIN_W := 480
const MAX_W := 720


static func width_for(win_size: Vector2i) -> int:
	if win_size.y <= 0:
		return MIN_W
	var w := clampi(int(round(H * float(win_size.x) / float(win_size.y))), MIN_W, MAX_W)
	return w - w % 2   # even, so a centred 480 column lands on whole pixels


## The real window size. The root window's own size can lag a frame behind
## when the window is maximised or resized, so ask the display server.
static func window_size(win: Window) -> Vector2i:
	if win == win.get_tree().root and DisplayServer.get_name() != "headless":
		return DisplayServer.window_get_size()
	return win.size


static func fit(win: Window) -> void:
	win.content_scale_size = Vector2i(width_for(window_size(win)), H)


## True when the window has changed shape since the last fit. Scenes check
## this every frame, so a maximise or drag always ends up filled.
static func stale(win: Window) -> bool:
	return width_for(window_size(win)) != win.content_scale_size.x


static func reset(win: Window) -> void:
	win.content_scale_size = Vector2i(MIN_W, H)
