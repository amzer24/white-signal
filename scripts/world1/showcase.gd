extends Node2D
## World 1, World 2 and World 3 art and juice showcase. Standalone: open
## scenes/world1_showcase.tscn and press F6. Pages: 12 gallery pages (pages 5 to
## 7 are the World 2 Switchyard, page 8 the atmosphere sheets, pages 9 and 10
## the Last Relay village, pages 11 and 12 the World 3 Aerials), 3 juice pages
## (18 looping demos) and a level page that renders the real World 1 maps with
## the new tiles.
##
## Keys: LEFT/RIGHT or 1-9 page, UP/DOWN level (level page), F shader on/off,
## S big screen shake, T slow motion, P pause, SPACE restart the loops.

const Sheets := preload("res://scripts/world1/sheets.gd")
const Vignette := preload("res://scripts/world1/vignette.gd")
const Gallery := preload("res://scripts/world1/gallery.gd")
const LevelView := preload("res://scripts/world1/level_view.gd")
const J := preload("res://scripts/world1/juice.gd")

const JUICE_PAGES := [
	["stomp", "dash", "bump", "brick", "loose", "press"],
	["gate", "bridge", "checkpoint", "mast", "shards", "charge"],
	["vents", "dropper", "ceiling", "rings", "spring", "tells"],
]
const JUICE_NAMES := ["JUICE: PLAYER HITS", "JUICE: WORLD REACTS", "JUICE: TRAPS AND TELLS"]
const LEVELS := ["1-1", "1-2", "1-3", "1-4"]
const CELL := Vector2(160, 122)

class Overlay extends Node2D:
	var show_ref: Node2D
	func _draw() -> void:
		show_ref.call("draw_overlay", self)

var sh
var page := 0
var clock := 0.0
var auto_clock := true
var paused := false
var time_scale := 1.0
var level_idx := 0
var auto_scroll := true
var shake_at := -10.0

var world: Node2D
var post: CanvasItem
var gallery: Node2D
var level: Node2D
var juice_roots: Array = []
var vignettes: Array = []
var overlay: Overlay

func _ready() -> void:
	world = $World
	post = $Post/Screen
	sh = Sheets.new()
	gallery = Gallery.new()
	gallery.sh = sh
	world.add_child(gallery)
	for p in JUICE_PAGES.size():
		var root := Node2D.new()
		world.add_child(root)
		juice_roots.append(root)
		var kinds: Array = JUICE_PAGES[p]
		for i in kinds.size():
			var clip := Control.new()
			clip.clip_contents = true
			clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			clip.position = Vector2((i % 3) * CELL.x, 12 + int(i / 3.0) * (CELL.y + 2))
			clip.size = CELL
			root.add_child(clip)
			var v := Vignette.new()
			v.sh = sh
			v.kind = kinds[i]
			clip.add_child(v)
			vignettes.append(v)
	level = LevelView.new()
	level.sh = sh
	world.add_child(level)
	level.load_level(LEVELS[level_idx])
	overlay = Overlay.new()
	overlay.show_ref = self
	add_child(overlay)
	show_page(0)

func page_count() -> int:
	return Gallery.PAGES.size() + JUICE_PAGES.size() + 1

func page_name(i: int) -> String:
	if i < Gallery.PAGES.size():
		return Gallery.PAGES[i]
	i -= Gallery.PAGES.size()
	if i < JUICE_PAGES.size():
		return JUICE_NAMES[i]
	return "REAL MAPS WITH THE NEW TILES"

func show_page(i: int) -> void:
	page = posmod(i, page_count())
	var g := Gallery.PAGES.size()
	gallery.visible = page < g
	gallery.page = page
	for p in juice_roots.size():
		juice_roots[p].visible = page == g + p
	level.visible = page == g + JUICE_PAGES.size()
	_refresh()

func set_clock(t: float) -> void:
	clock = t
	_refresh()

func set_level(i: int, scroll := -1.0) -> void:
	level_idx = posmod(i, LEVELS.size())
	level.load_level(LEVELS[level_idx])
	if scroll >= 0.0:
		auto_scroll = false
		level.scroll = scroll
	_refresh()

func set_shader(on: bool) -> void:
	post.visible = on

func big_shake() -> void:
	shake_at = clock

func _process(delta: float) -> void:
	if auto_clock and not paused:
		clock += delta * time_scale
	_refresh()

func _refresh() -> void:
	world.position = J.shake(clock - shake_at, 5.0, 0.45, 99)
	gallery.clock = clock
	gallery.queue_redraw()
	for v in vignettes:
		v.clock = clock
		if v.get_parent().get_parent().visible:
			v.queue_redraw()
	level.clock = clock
	if auto_scroll and level.width > 30:
		var span: float = level.width * 16.0 - 480.0
		var d := fposmod(clock * 60.0, span * 2.0)
		level.scroll = d if d < span else span * 2.0 - d
	level.queue_redraw()
	overlay.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_RIGHT:
			show_page(page + 1)
		KEY_LEFT:
			show_page(page - 1)
		KEY_UP:
			set_level(level_idx - 1)
			auto_scroll = true
		KEY_DOWN:
			set_level(level_idx + 1)
			auto_scroll = true
		KEY_F:
			set_shader(not post.visible)
		KEY_S:
			big_shake()
		KEY_T:
			time_scale = 0.25 if time_scale == 1.0 else 1.0
		KEY_P:
			paused = not paused
		KEY_SPACE:
			clock = 0.0
		_:
			if k.keycode >= KEY_1 and k.keycode <= KEY_9:
				show_page(int(k.keycode - KEY_1))

func draw_overlay(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 480, 11), DrawUtil.BG)
	ci.draw_rect(Rect2(0, 11, 480, 1), DrawUtil.DARK)
	DrawUtil.text(ci, Vector2(4, 3), "WORLD ART  %d/%d  %s" % [page + 1, page_count(), page_name(page)], DrawUtil.WHITE)
	var flags := "SHADER %s" % ("ON" if post.visible else "OFF")
	if time_scale < 1.0:
		flags = "SLOW  " + flags
	if paused:
		flags = "PAUSED  " + flags
	DrawUtil.text(ci, Vector2(476, 3), flags, DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_RIGHT)
	if juice_page_visible():
		ci.draw_rect(Rect2(159, 12, 1, 248), DrawUtil.DARK)
		ci.draw_rect(Rect2(319, 12, 1, 248), DrawUtil.DARK)
	ci.draw_rect(Rect2(0, 260, 480, 10), DrawUtil.BG)
	var help := "LEFT RIGHT PAGE   F SHADER   S SHAKE   T SLOW   P PAUSE   SPACE RESTART"
	if page == page_count() - 1:
		help = "UP DOWN LEVEL   " + help
	DrawUtil.text(ci, Vector2(240, 263), help, DrawUtil.DARK, 1, HORIZONTAL_ALIGNMENT_CENTER)

func juice_page_visible() -> bool:
	var g := Gallery.PAGES.size()
	return page >= g and page < g + JUICE_PAGES.size()
