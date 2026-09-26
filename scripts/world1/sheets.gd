extends RefCounted
## World 1 sprite sheets. Loads every sheet listed in sheet_data.gd and draws
## frames by sheet + animation name. Positions are floored so art stays on the
## pixel grid. Timing comes from the per-frame durations in the manifest.

const Data := preload("res://scripts/world1/sheet_data.gd")
const DIR := "res://assets/world1/"

var tex := {}
var tex_flip := {}   # mirrored copies: frame i sits at column (cols - 1 - i)
var cols := {}

func _init() -> void:
	for sheet_name in Data.SHEETS:
		var t := _texture(DIR + str(Data.SHEETS[sheet_name].file))
		tex[sheet_name] = t
		cols[sheet_name] = int(t.get_width() / float(Data.SHEETS[sheet_name].fw))
		var img := t.get_image()
		if img != null:
			img.flip_x()
			tex_flip[sheet_name] = ImageTexture.create_from_image(img)

## Reads the source PNG while developing, so a freshly regenerated sheet shows
## up without waiting for the editor to reimport it. In an exported build the
## source file is absent and the imported texture is used instead.
static func _texture(path: String) -> Texture2D:
	var source := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(source):
		var img := Image.load_from_file(source)
		if img != null:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("world1 sheets: missing %s" % path)
	return PlaceholderTexture2D.new()

func size(sheet: String) -> Vector2:
	var s: Dictionary = Data.SHEETS[sheet]
	return Vector2(s.fw, s.fh)

func frames(sheet: String, anim: String) -> int:
	return int(Data.SHEETS[sheet].anims[anim].frames)

## Total length of one pass of an animation, in seconds.
func length(sheet: String, anim: String) -> float:
	var total := 0.0
	for d in Data.SHEETS[sheet].anims[anim].dur:
		total += float(d)
	return total

## Frame index `t` seconds after the animation started. Non-looping
## animations hold their last frame.
func frame_at(sheet: String, anim: String, t: float, force_loop := false) -> int:
	var a: Dictionary = Data.SHEETS[sheet].anims[anim]
	var durs: Array = a.dur
	var n: int = a.frames
	var total := length(sheet, anim)
	if total <= 0.0 or n <= 1:
		return 0
	if bool(a.loop) or force_loop:
		t = fposmod(t, total)
	elif t >= total:
		return n - 1
	t = maxf(t, 0.0)
	for i in n:
		var d := float(durs[i])
		if t < d:
			return i
		t -= d
	return n - 1

## Draws one frame with its top-left at `pos`.
func draw_frame(ci: CanvasItem, sheet: String, anim: String, frame: int, pos: Vector2,
		flip := false, mod := Color.WHITE) -> void:
	var s: Dictionary = Data.SHEETS[sheet]
	var fw := float(s.fw)
	var fh := float(s.fh)
	var row := int(s.anims[anim].row)
	var src := Rect2(frame * fw, row * fh, fw, fh)
	var p := pos.floor()
	if flip and tex_flip.has(sheet):
		var fsrc := Rect2((int(cols[sheet]) - 1 - frame) * fw, row * fh, fw, fh)
		ci.draw_texture_rect_region(tex_flip[sheet], Rect2(p, Vector2(fw, fh)), fsrc, mod)
	else:
		ci.draw_texture_rect_region(tex[sheet], Rect2(p, Vector2(fw, fh)), src, mod)

## Draws part of a frame: `part` is a rect inside the frame (local pixels).
func draw_part(ci: CanvasItem, sheet: String, anim: String, frame: int, pos: Vector2, part: Rect2,
		mod := Color.WHITE) -> void:
	if part.size.x <= 0.0 or part.size.y <= 0.0:
		return
	var s: Dictionary = Data.SHEETS[sheet]
	var row := int(s.anims[anim].row)
	var src := Rect2(frame * float(s.fw) + part.position.x, row * float(s.fh) + part.position.y,
		part.size.x, part.size.y)
	ci.draw_texture_rect_region(tex[sheet], Rect2(pos.floor() + part.position, part.size), src, mod)

## Draws the frame an animation shows `t` seconds after it started.
func draw_anim(ci: CanvasItem, sheet: String, anim: String, t: float, pos: Vector2,
		flip := false, mod := Color.WHITE) -> void:
	draw_frame(ci, sheet, anim, frame_at(sheet, anim, t), pos, flip, mod)
