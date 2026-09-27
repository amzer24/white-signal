extends Node2D
## The settings pages the title screen opens: sound, display and keyboard keys.
## Closed when `page` is "home". Draws on the centred 480 x 270 column.

const TICK := "res://assets/audio/sfx8/menu_tick.wav"   # played when the effects volume changes

var page := "home"
var selected := 0
var dragging := -1
var tick: AudioStreamPlayer


func _ready() -> void:
	tick = AudioStreamPlayer.new()
	tick.bus = "SFX"
	tick.stream = load(TICK)
	add_child(tick)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and page == "keyboard":
		GameInput.keyboard.capturing = ""
		GameInput.keyboard.shift_pending = false


func _process(_delta: float) -> void:
	visible = page != "home"
	if visible:
		queue_redraw()


func open_settings() -> void:
	page = "settings"
	selected = 0


func back() -> void:
	if page == "keyboard":
		GameInput.keyboard.capturing = ""
		page = "settings"
		selected = 5
		return
	if dragging >= 0:
		AppSettings.save_preferences()
	dragging = -1
	page = "home"
	selected = 0


func row_count() -> int:
	return 8 if page == "keyboard" else 7


func row_rect(index: int) -> Rect2:
	if page == "keyboard":
		return Rect2(80, 60 + index * 20, 320, 19)
	return Rect2(80, 84 + index * 21, 320, 20)


func label(at: Vector2, text: String, size := 1, color := DrawUtil.WHITE, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	DrawUtil.text(self, at, text, color, size, alignment)


func _draw() -> void:
	if page == "home":
		return
	draw_rect(Rect2(0, 0, 480, 270), Color(0, 0, 0, 0.96))
	if page == "keyboard":
		label(Vector2(80, 25), "KEYBOARD", 4)
		var names := ["MOVE LEFT", "MOVE RIGHT", "JUMP", "DASH", "USE", "ARC", "RESTORE DEFAULTS", "BACK"]
		for i in names.size():
			var rect := row_rect(i)
			if i == selected:
				draw_rect(rect, DrawUtil.DARK)
			label(rect.position + Vector2(8, 7), names[i])
			if i < 6:
				var action: String = GameInput.keyboard.ACTIONS[i]
				label(rect.position + Vector2(308, 7), "PRESS KEY..." if GameInput.keyboard.capturing == action else GameInput.keyboard.key_label(action), 1, DrawUtil.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		label(Vector2(80, 230), GameInput.keyboard.error, 1, DrawUtil.WHITE)
		label(Vector2(80, 249), "ESC / B CANCEL . MENU KEYS STAY FIXED", 1, DrawUtil.GRAY)
		return
	label(Vector2(80, 35), "SETTINGS", 4)
	label(Vector2(80, 64), "SOUND AND DISPLAY", 1, DrawUtil.GRAY)
	var names := ["MUSIC", "EFFECTS", "FULLSCREEN", "REDUCED FLASH", "CAMERA SHAKE", "KEYBOARD", "BACK"]
	for i in 7:
		var rect := row_rect(i)
		if i == selected:
			draw_rect(rect, DrawUtil.DARK)
			draw_rect(rect, DrawUtil.GRAY, false, 1)
			label(rect.position + Vector2(-12, 9), ">")
		label(rect.position + Vector2(8, 8), names[i])
		if i < 2:
			var volume: float = AppSettings.music_volume if i == 0 else AppSettings.sfx_volume
			var bar := Rect2(230, rect.position.y + 10, 120, 4)
			draw_rect(bar, DrawUtil.DARK)
			draw_rect(Rect2(bar.position, Vector2(roundf(120 * volume), 4)), DrawUtil.WHITE)
			draw_rect(Rect2(228 + roundf(120 * volume), rect.position.y + 7, 4, 10), DrawUtil.WHITE)
			label(Vector2(388, rect.position.y + 8), "%d%%" % roundi(volume * 100), 1, DrawUtil.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		elif i < 5:
			var on: bool = [AppSettings.fullscreen, AppSettings.reduced_flashes, AppSettings.camera_shake][i - 2]
			label(Vector2(388, rect.position.y + 8), "ON" if on else "OFF", 1, DrawUtil.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	label(Vector2(80, 237), "D-PAD ADJUST . A TOGGLE . B BACK" if GameInput.controller_active else "LEFT/RIGHT ADJUST . ENTER TOGGLE . ESC BACK", 1, DrawUtil.GRAY)
	label(Vector2(80, 252), "SAVED AUTOMATICALLY" if AppSettings.save_error.is_empty() else AppSettings.save_error, 1, DrawUtil.GRAY if AppSettings.save_error.is_empty() else DrawUtil.WHITE)


func activate() -> void:
	if page == "keyboard":
		if selected < 6:
			GameInput.keyboard.begin_capture(GameInput.keyboard.ACTIONS[selected])
		elif selected == 6:
			GameInput.keyboard.restore_defaults()
		else:
			back()
		return
	match selected:
		2:
			AppSettings.toggle_fullscreen()
		3:
			AppSettings.toggle_flashes()
		4:
			AppSettings.toggle_shake()
		5:
			page = "keyboard"
			selected = 0
		6:
			back()


func adjust(amount: float, persist := true) -> void:
	if selected < 2:
		var kind := "music" if selected == 0 else "effects"
		var value: float = AppSettings.music_volume if selected == 0 else AppSettings.sfx_volume
		AppSettings.set_volume(kind, value + amount, persist)
		if selected == 1 and persist:
			tick.play()
	elif selected < 5:
		activate()


func slide(x: float) -> void:
	var volume := snappedf(clampf((x - 230.0) / 120.0, 0.0, 1.0), 0.05)
	AppSettings.set_volume("music" if dragging == 0 else "effects", volume, false)


func handle_input(event: InputEvent) -> bool:
	if page == "home":
		return false
	if page == "keyboard" and GameInput.keyboard.capture(event):
		return true
	event = GameInput.menu_event(event)
	if event is InputEventMouseMotion:
		var mouse: Vector2 = event.position - position
		if dragging >= 0:
			slide(mouse.x)
		else:
			for i in row_count():
				if row_rect(i).has_point(mouse):
					selected = i
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if dragging >= 0:
				AppSettings.save_preferences()
				if dragging == 1:
					tick.play()
				dragging = -1
			return true
		var mouse: Vector2 = event.position - position
		for i in row_count():
			if row_rect(i).has_point(mouse):
				selected = i
				if page == "settings" and i < 2:
					if mouse.x >= 225:
						dragging = i
						slide(mouse.x)
				else:
					activate()
				break
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
		if key == KEY_F11:
			AppSettings.toggle_fullscreen()
		elif key == KEY_ESCAPE:
			back()
		elif key in [KEY_UP, KEY_DOWN, KEY_W, KEY_S]:
			selected = posmod(selected + (-1 if key in [KEY_UP, KEY_W] else 1), row_count())
		elif page == "settings" and key in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]:
			adjust(-0.05 if key in [KEY_LEFT, KEY_A] else 0.05)
		elif key in [KEY_ENTER, KEY_SPACE]:
			activate()
	return true
