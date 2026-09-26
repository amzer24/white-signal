extends Node2D
## Audition board for the 8-bit sound set in res://assets/audio/sfx8/.
## Reads manifest.json, so a rebuilt set shows up without editing this file.
## Keys: arrows move, Enter or Space plays, Escape stops everything. Mouse: click a row.

const DIR := "res://assets/audio/sfx8/"
const ROWS := 27
const ROW_H := 7
const TOP := 24
const COL_W := 240

var entries: Array = []
var streams: Array = []
var selected := 0
var flash := {}
var bus := "Master"

func _ready() -> void:
	if AudioServer.get_bus_index("SFX") != -1:
		bus = "SFX"
	var file := FileAccess.open(DIR + "manifest.json", FileAccess.READ)
	if file == null:
		push_error("sfx8 board: manifest.json not found in " + DIR)
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("sfx8 board: manifest.json could not be read")
		return
	for e in data.get("sounds", []):
		var stream = load(DIR + str(e.file))
		if stream == null:
			push_error("sfx8 board: could not load " + str(e.file))
			continue
		entries.append(e)
		streams.append(stream)

func play(i: int) -> void:
	if i < 0 or i >= streams.size():
		return
	selected = i
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.stream = streams[i]
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	flash[i] = 0.12

func stop_all() -> void:
	for c in get_children():
		if c is AudioStreamPlayer:
			c.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if entries.is_empty():
		return
	var n := entries.size()
	if event.is_action_pressed("ui_down", true):
		selected = (selected + 1) % n
	elif event.is_action_pressed("ui_up", true):
		selected = (selected - 1 + n) % n
	elif event.is_action_pressed("ui_right"):
		selected = mini(selected + ROWS, n - 1)
	elif event.is_action_pressed("ui_left"):
		selected = maxi(selected - ROWS, 0)
	elif event.is_action_pressed("ui_accept"):
		play(selected)
	elif event.is_action_pressed("ui_cancel"):
		stop_all()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := row_at(get_local_mouse_position())
		if i != -1:
			play(i)
	else:
		return
	get_viewport().set_input_as_handled()

func row_rect(i: int) -> Rect2:
	var col := floori(float(i) / ROWS)
	var row := i % ROWS
	return Rect2(8 + col * COL_W, TOP + row * ROW_H, COL_W - 16, ROW_H)

func row_at(pos: Vector2) -> int:
	for i in entries.size():
		if row_rect(i).has_point(pos):
			return i
	return -1

func _process(delta: float) -> void:
	for k in flash.keys():
		flash[k] -= delta
		if flash[k] <= 0.0:
			flash.erase(k)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), DrawUtil.BG)
	DrawUtil.text(self, Vector2(8, 6), "SFX8 BOARD", DrawUtil.WHITE, 2)
	DrawUtil.text(self, Vector2(472, 10), "%d SOUNDS . 8-BIT SET" % entries.size(), DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_rect(Rect2(8, TOP - 4, 464, 1), DrawUtil.DARK)
	if entries.is_empty():
		DrawUtil.text(self, Vector2(240, 120), "NO SOUNDS . RUN TOOLS/AUDIO/SFX8.PY", DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
		return
	for i in entries.size():
		var r := row_rect(i)
		var on := i == selected
		if flash.has(i):
			draw_rect(r, DrawUtil.GRAY)
		elif on:
			draw_rect(r, DrawUtil.WHITE)
		var ink := DrawUtil.BG if on or flash.has(i) else DrawUtil.WHITE
		var dim := DrawUtil.BG if on or flash.has(i) else DrawUtil.GRAY
		DrawUtil.text(self, r.position + Vector2(3, 1), str(entries[i].name).replace("_", " "), ink)
		DrawUtil.text(self, r.position + Vector2(r.size.x - 3, 1), "%.2fs" % float(entries[i].duration), dim, 1, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_rect(Rect2(8, 219, 464, 1), DrawUtil.DARK)
	var e: Dictionary = entries[selected]
	DrawUtil.text(self, Vector2(8, 226), "%s . %s" % [str(e.category), str(e.name)], DrawUtil.WHITE)
	DrawUtil.text(self, Vector2(8, 236), str(e.trigger), DrawUtil.GRAY)
	DrawUtil.text(self, Vector2(8, 246), "PEAK %.1f DB . RMS %.1f DB . LOUDEST 50MS %.1f DB" % [float(e.peak_dbfs), float(e.rms_dbfs), float(e.loudest_50ms_rms_dbfs)], DrawUtil.GRAY)
	DrawUtil.text(self, Vector2(240, 259), "ARROWS SELECT . ENTER PLAY . ESC STOP . CLICK", DrawUtil.GRAY, 1, HORIZONTAL_ALIGNMENT_CENTER)
