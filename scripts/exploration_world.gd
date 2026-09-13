extends Node2D
## Isolated exploration slice. The legacy RunState supplies controller timing only;
## permanent exploration discoveries belong exclusively to profile.

const Guidance = preload("res://scripts/exploration_guidance.gd")
const Rooms = preload("res://scripts/exploration_rooms.gd")
const PlayerScript = preload("res://scripts/player.gd")
const SaveScript = preload("res://scripts/exploration_save.gd")
const PacketScript = preload("res://scripts/exploration_packet.gd")
const DrownedScript = preload("res://scripts/drowned_mechanism.gd")
var drowned: RefCounted
const SiphonScript = preload("res://scripts/siphon_mechanism.gd")
var siphon: RefCounted
const StandScript = preload("res://scripts/stand_mechanism.gd")
var stand: RefCounted
var map_region := 0
const AlignmentScript = preload("res://scripts/signal_alignment.gd")
var alignment: RefCounted
const NetworkScript = preload("res://scripts/network_mechanism.gd")
var network: RefCounted
const GateScript = preload("res://scripts/gate_mechanism.gd")
var gate: RefCounted
var save_path := "user://ws_exploration_v1.json"
var profile = SaveScript.new()
var room_id := "hub"
var room: Dictionary
var player: CharacterBody2D
var solids: Node2D
var lift: AnimatableBody2D
var lift_power := false
var paused := false
var map_open := false:
	set(value):
		map_open = value
		if is_instance_valid(noise_actor): noise_actor.visible = not value
var map_help := false
var memory_time := 0.0
var elapsed := 0.0
var notice := ""
var notice_time := 0.0
var foreground_cache: Dictionary = {}
var far_texture: Texture2D
var ruins_texture: Texture2D
var window_texture: Texture2D
var exiting := false
var noise_actor: CharacterBody2D
var noise_cleared: Dictionary = {}
var drowned_material = preload("res://scripts/drowned_material.gd").new()
var coherence_light = preload("res://scripts/coherence_light.gd").new()
var beacon_light_power := 0.0
var window_light_power := 0.0
var settings_menu: Node2D

func _ready() -> void:
	GameInput.controller_lost.connect(_controller_lost)
	profile.path = save_path
	profile.load_profile()
	beacon_light_power = 1.0 if profile.has_flag("first_beacon") else 0.0
	window_light_power = 1.0 if profile.has_flag("west_ear") else 0.0
	RunState.lab_active = true # prevents legacy campaign boundary writes
	RunState.mods = RunState.BASE.duplicate()
	RunState.hitstop = 0.0
	RunState.state = "play"
	settings_menu = preload("res://scripts/menu_ui.gd").new()
	settings_menu.exploration_path = save_path
	settings_menu.settings_only = true
	settings_menu.z_index = 100
	add_child(settings_menu)
	var pump_motor = preload("res://scripts/pump_motor.gd").new()
	pump_motor.name = "PumpMotor"
	add_child(pump_motor)
	Music.begin_exploration()
	player = CharacterBody2D.new()
	player.set_script(PlayerScript)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12,14)
	collision.shape = shape
	player.add_child(collision)
	add_child(player)
	RunState.respawned.connect(respawn)
	var far_path := "res://assets/backgrounds/afterlight-v2/far-terrain.png"
	if ResourceLoader.exists(far_path): far_texture = load(far_path)
	var ruins_path := "res://assets/backgrounds/afterlight-v2/mid-ruins.png"
	if ResourceLoader.exists(ruins_path): ruins_texture = load(ruins_path)
	var window_path := "res://assets/exploration/answering-window.png"
	if ResourceLoader.exists(window_path): window_texture = load(window_path)
	drowned = DrownedScript.new(self)
	siphon = SiphonScript.new(self)
	stand = StandScript.new(self)
	alignment = AlignmentScript.new()
	network = NetworkScript.new(self)
	gate = GateScript.new(self)
	enter_room(String(profile.data.room))

func _exit_tree() -> void:
	Music.end_exploration()
	if RunState.respawned.is_connected(respawn): RunState.respawned.disconnect(respawn)

func _sync_abilities() -> void:
	RunState.mods.dash = profile.has_flag("dash")
	RunState.mods.air_jumps = 1 if profile.has_flag("air_jump") else 0

func enter_room(id: String, from := "") -> void:
	if not id in SaveScript.ROOMS: return
	if not profile.enter_room(id):
		if room.is_empty():
			room_id = "hub"
			room = Rooms.get_room("hub")
			_build_geometry()
			player.reset_at(room.spawn)
		_notify("SAVE FAILED . PROGRESS HELD IN THIS ROOM")
		return
	room_id = id
	room = Rooms.get_room(id,profile.data.flags)
	drowned.enter()
	siphon.enter()
	stand.enter()
	network.enter()
	gate.enter()
	alignment = AlignmentScript.new()
	if profile.has_flag("east_ear"):
		alignment.positions = alignment.target.duplicate()
		alignment.latch()
	map_region = 1 if id in StandScript.IDS else 0
	if id in DrownedScript.IDS: map_region = 7
	if id == "siphon": map_region = 6
	if id in ["cellar","sump"]: map_region = 2
	if id in ["flats","conduit","arrival"]: map_region = 3
	if id in ["array_cable","wire_shaft","wire_shelter","wire_carriage","array","array_inspection"]: map_region = 4
	if id in ["approach","gate","source_return","source_walk","aftermath"]: map_region = 5
	memory_time = 0.0
	lift_power = profile.has_flag("catch") and not profile.has_flag("west_ear")
	_build_geometry()
	_sync_abilities()
	var spawn: Vector2 = room.spawn
	if from != "":
		for exit_data in room.exits:
			if exit_data[0] == from:
				spawn = exit_data[1]
				spawn.x += 24.0 if spawn.x < 240 else -24.0
				break
	player.reset_at(spawn)

func _solid(rect: Rect2, script: Script = null) -> StaticBody2D:
	var body := StaticBody2D.new()
	if script != null: body.set_script(script)
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	solids.add_child(body)
	return body

func _build_geometry() -> void:
	if is_instance_valid(solids):
		remove_child(solids)
		solids.queue_free()
	solids = Node2D.new()
	add_child(solids)
	lift = null
	for rect in room.platforms:
		var body := _solid(rect)
		if room_id == "siphon" or ((room_id in StandScript.IDS or room_id in DrownedScript.IDS or room_id in ["amplifier","gate","source_return","source_walk","array_cable","wire_shaft","array","array_inspection"]) and rect.size.y <= 8): body.get_child(0).one_way_collision = true
	if room_id == "flats":
		var memory_block = _solid(Rect2(199,168,24,16),PacketScript)
		memory_block.world = self
		memory_block.action_id = "intro_memory"
	if room_id == "cellar" and not profile.has_flag("south_ear"):
		var intake = _solid(Rect2(199,167,24,16),PacketScript)
		intake.world = self
		intake.action_id = "intake_strike"
	if room_id == "workshop":
		var packet = _solid(Rect2(199,150,24,16),PacketScript)
		packet.world = self
	if room_id == "gallery":
		if profile.has_flag("catch"):
			for rect in _stairs(): _solid(rect)
		lift = AnimatableBody2D.new()
		lift.position = Vector2(225,124 if profile.has_flag("catch") else 220)
		lift.sync_to_physics = false
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(62,8)
		collision.shape = shape
		collision.one_way_collision = true
		lift.add_child(collision)
		solids.add_child(lift)
	if drowned != null: drowned.build()
	if siphon != null: siphon.build()
	if stand != null: stand.build()
	if network != null: network.build()
	_spawn_noise()

func _spawn_noise() -> void:
	if is_instance_valid(noise_actor):
		remove_child(noise_actor)
		noise_actor.queue_free()
	noise_actor = null
	if not room_id in ["array_inspection","array_cable"] or noise_cleared.has(room_id): return
	noise_actor = load("res://scripts/cling_noise.gd" if room_id == "array_cable" else "res://scripts/exploration_noise.gd").new()
	noise_actor.world = self
	noise_actor.encounter_id = room_id
	noise_actor.position = Vector2(250,112) if room_id == "array_cable" else Vector2(240,215)
	noise_actor.min_x = 190
	noise_actor.max_x = 310
	noise_actor.speed = 42
	add_child(noise_actor)
	noise_actor.visible = not map_open

func _stairs() -> Array:
	return [Rect2(108,190,48,8),Rect2(168,157,48,8),Rect2(246,125,45,8)]

func can_use_exit(target: String) -> bool:
	if (room_id == "array_cable" and target == "wire_shelter") or (room_id == "wire_shelter" and target == "array_cable"): return profile.has_flag("cable_archive")
	if room_id == "basin" and target == "drowned_street": return drowned.water_y >= 241
	if (room_id == "pump" and target == "float") or (room_id == "float" and target == "pump"): return profile.has_flag("drowned_restored")
	if room_id == "drowned_gallery" and target == "float": return profile.has_flag("pump_repaired")
	if (room_id == "drowned_gallery" and target == "drowned_dock") or (room_id == "drowned_dock" and target == "drowned_gallery"): return profile.has_flag("drowned_restored")
	if target == "stand_bridge": return profile.has_flag("stand_restored")
	if room_id == "return" and target == "stand_rim": return profile.has_flag("dash") or profile.has_flag("stand_restored")
	if (room_id == "pump" and target == "stand_sluice") or (room_id == "stand_sluice" and target == "pump"): return profile.has_flag("drowned_restored")
	if room_id == "stand_bridge" and target == "wire_shelter": return profile.has_flag("stand_restored") and profile.has_flag("dash")
	match room_id:
		"conduit":
			if target == "arrival": return profile.has_flag("conduit_open")
		"arrival":
			if target == "hub": return profile.has_flag("first_beacon")
		"hub":
			if target == "return": return profile.has_flag("return_open")
			if target == "aftermath": return profile.has_flag("signal_restored")
		"workshop":
			if target == "gallery": return profile.has_flag("plate_seen")
		"gallery":
			if target == "amplifier": return profile.has_flag("west_ear")
		"amplifier":
			if target == "return": return profile.has_flag("dash")
			if target == "fourth": return profile.has_flag("air_jump")
		"return":
			if target == "hub": return profile.has_flag("return_open")
			if target == "shelter": return profile.has_flag("dash") or profile.has_flag("stand_restored")
			if target == "conductor": return profile.has_flag("stand_restored")
			if target == "causeway": return profile.has_flag("east_ear")
		"causeway":
			if target == "return": return profile.has_flag("east_ear")
			if target == "sump": return profile.has_flag("field_restored")
		"sump":
			if target == "causeway": return profile.has_flag("field_restored")
		"lookout":
			if target == "siphon": return profile.has_flag("siphon_return")
		"basin":
			if target == "float": return profile.has_flag("float_latch")
		"siphon":
			if target == "lookout": return profile.has_flag("siphon_return")
		"pump":
			if target == "siphon": return profile.has_flag("pump_repaired")
			if target == "float": return profile.has_flag("pump_repaired")
			if target == "shelter": return profile.has_flag("drowned_restored")
			if target == "array": return profile.has_flag("drowned_restored")
		"float":
			if target == "basin": return profile.has_flag("float_latch")
		"shelter":
			if target == "pump": return profile.has_flag("drowned_restored")
			if target == "wire_shelter": return profile.has_flag("stand_restored") and profile.has_flag("dash")
			if target == "approach": return profile.has_flag("approach_return")
		"conductor":
			if target == "return": return profile.has_flag("stand_restored")
		"wire_carriage":
			if target == "array": return profile.has_flag("wire_repaired")
		"wire_shelter":
			if target == "array": return profile.has_flag("array_restored")
		"array":
			if target == "pump": return profile.has_flag("drowned_restored")
			if target == "wire_carriage": return profile.has_flag("wire_repaired")
			if target == "wire_shelter": return profile.has_flag("array_restored")
			if target == "approach": return profile.has_flag("array_restored")
		"approach":
			if target == "gate": return gate.ready()
			if target == "shelter": return profile.has_flag("approach_return")
		"gate":
			if target == "source_return": return gate.progress().latched
			if target == "aftermath": return profile.has_flag("signal_restored")
		"source_return":
			if target == "source_walk": return gate.progress().tested
		"source_walk":
			if target == "aftermath": return profile.has_flag("signal_restored")
	return true

func _commit(flag: String) -> bool:
	if profile.set_flag(flag): return true
	_notify("SAVE FAILED . TRY THE CONTROL AGAIN")
	return false

func activate(id: String) -> void:
	if id == "cable_archive" and room_id == "array_cable":
		if _commit("cable_archive"): _notify("THE CABLES KEPT THEIR ROUTINE . SHELTER RETURN OPEN")
		return
	if id == "inspection_archive" and room_id == "array_inspection":
		if _commit("inspection_archive"):
			_notify("INSPECTION LOG . THE MACHINES LEARNED OUR ROUTINES")
		return
	if siphon != null and siphon.use(id): return
	if gate != null and gate.use(id):
		Sfx.beep(165,0.12,0.035,"sawtooth")
		return
	if network != null and network.use(id):
		Sfx.beep(125,0.075,0.035,"sawtooth")
		return
	if id == "intro_memory" and room_id == "flats":
		if _commit("intro_memory"):
			memory_time = 7
			_notify("THE DISHES WAITED . NO DEFENCE WAS NEEDED HERE")
		return
	if id == "conduit_switch" and room_id == "conduit":
		if _commit("conduit_open"):
			player.reset_at(Vector2(355,215))
			_notify("SERVICE CONDUIT . BOTH ENDS REMAIN USABLE")
		return
	if id == "conduit_return" and room_id == "conduit":
		player.reset_at(Vector2(211,215))
		return
	if id == "first_beacon" and room_id == "arrival":
		if _commit("first_beacon"):
			_notify("REPEATER RESTORED . THE LISTENING FIELD ANSWERS")
		return
	if id == "fourth_memory" and room_id == "fourth":
		if _commit("fourth_archive"):
			memory_time = 8
			_notify("THE FOURTH EAR WAS ISOLATED . THE WORKSHOP KEPT ITS LIGHT")
		return
	if id == "intake_strike" and room_id == "cellar":
		if _commit("south_ear"):
			call_deferred("_build_geometry")
			_notify("SOUTH INTAKE CLEARED . AIR MOVES THROUGH THE FIELD")
			Sfx.beep(95,0.12,0.045,"sawtooth")
		return
	if id == "field_transmit" and room_id == "sump":
		if not (profile.has_flag("west_ear") and profile.has_flag("east_ear") and profile.has_flag("south_ear")):
			_notify("FEEDER INCOMPLETE . FOLLOW THE UNLIT EAR")
		elif _commit("field_restored"):
			_notify("THREE EARS ANSWER . FIELD FEEDER COMMISSIONED")
		return
	if room_id == "causeway":
		if id in ["dish_0","dish_1","dish_2"]:
			alignment.rotate(int(id.right(1)))
			_notify("ALIGNMENT HELD" if alignment.locked else "MATCH THE SOLID ARM TO THE ETCHED SIGHT LINE")
			Sfx.beep(180,0.045,0.035)
			return
		if id == "ear_transmit":
			if not alignment.is_aligned(): _notify("SIGNAL SCATTERS . CHECK ALL THREE SIGHT LINES")
			elif _commit("east_ear"):
				alignment.latch()
				_notify("EAST EAR HOLDS . COUNTERWEIGHT ROUTE OPEN")
			return
	if stand != null and stand.use(id):
		Sfx.beep(82,0.08,0.035,"sawtooth")
		return
	if drowned != null and drowned.use(id):
		return
	match id:
		"memory":
			if not _commit("memory"): return
			memory_time = 7.0
			_notify("THEY CLOSED THIS CHANNEL BY HAND")
		"selector":
			if room_id != "gallery": return
			if profile.has_flag("west_ear"):
				_notify("WEST EAR HOLDS . THE STAIR REMAINS")
			elif profile.has_flag("catch"):
				if _commit("west_ear"):
					lift_power = false
					_notify("WEST EAR RESTORED . AMPLIFIER OPEN")
			else:
				lift_power = not lift_power
				_notify("LIFT POWERED . RIDE TO THE CATCH" if lift_power else "LIFT RECALLED")
		"catch":
			if room_id != "gallery": return
			if not lift_power and not profile.has_flag("catch"):
				_notify("POWER THE SERVICE LIFT FIRST")
			elif _commit("catch"):
				_build_geometry()
				_notify("CATCH HOLDS . STAIR UNFOLDED . REROUTE BELOW")
		"dash":
			if room_id != "amplifier" or not profile.has_flag("west_ear"): return
			if profile.has_flag("dash"):
				_notify("DASH IS YOURS . JUMP THEN " + GameInput.action_label("dash") + " TO CROSS")
				return
			if profile.set_flags({"dash":true,"amplifier_training":true}):
				_sync_abilities()
				player.dash_ready = true
				_notify("DASH IS YOURS . " + GameInput.action_label("dash") + " . REFILLS ON GROUND")
			else: _notify("SAVE FAILED . TRY THE PROTOCOL AGAIN")
		"amplifier_release":
			if room_id != "amplifier" or not profile.has_flag("dash"): return
			if _commit("amplifier_released"):
				room = Rooms.get_room(room_id,profile.data.flags)
				_build_geometry()
				_notify("RETURN STEPS HOLD . THE CROSSING IS NOW CONNECTED")
		"return_latch":
			if room_id == "return" and profile.has_flag("dash") and _commit("return_open"):
				_notify("HUB LIFT OPEN . THIS ROUTE WILL REMAIN")
		"survey":
			if room_id == "lookout" and _commit("survey"):
				_notify("DROWNED OUTLINE RECEIVED . OPEN YOUR MAP")
	Sfx.beep(460.0,0.055,0.04)

func _nearest() -> Array:
	var found: Array = []
	var best := 29.0
	for action in room.actions:
		var distance: float = player.position.distance_to(action[1])
		if distance < best:
			best = distance
			found = ["action",action[0],action[2]]
	for exit_data in room.exits:
		var distance: float = player.position.distance_to(exit_data[1])
		if distance < best:
			best = distance
			found = ["exit",exit_data[0],exit_data[2]]
	return found

func _controller_lost() -> void:
	paused = true
	RunState.state = "pause"
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if settings_menu != null and settings_menu.page != "home":
		settings_menu.handle_input(event)
		get_viewport().set_input_as_handled()
		return
	var use_pressed: bool = GameInput.use_event(event)
	event = GameInput.exploration_event(event,paused,map_open)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			map_open = not map_open
			map_help = false
			RunState.state = "pause" if paused or map_open else "play"
			get_viewport().set_input_as_handled()
		elif map_open and event.keycode == KEY_H:
			map_help = not map_help
			get_viewport().set_input_as_handled()
		elif map_open and event.keycode == KEY_ESCAPE:
			if map_help:
				map_help = false
				get_viewport().set_input_as_handled()
				return
			map_open = false
			RunState.state = "pause" if paused else "play"
			get_viewport().set_input_as_handled()
		elif map_open and event.keycode == KEY_TAB:
			map_region = (map_region+1)%8
			map_help = false
			get_viewport().set_input_as_handled()
		elif map_open:
			return
		elif event.keycode in [KEY_ESCAPE,KEY_P]:
			paused = not paused
			RunState.state = "pause" if paused else "play"
			get_viewport().set_input_as_handled()
		elif paused and event.keycode == KEY_Q:
			leave_to_title()
		elif paused and event.keycode == KEY_F:
			AppSettings.toggle_flashes()
		elif paused and event.keycode == KEY_O:
			settings_menu.open_settings()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R and not paused:
			respawn()
		elif not paused and use_pressed:
			var target := _nearest()
			if not target.is_empty():
				if target[0] == "action": activate(target[1])
				elif can_use_exit(target[1]): enter_room(target[1],room_id)
				else: _notify("CIRCUIT CLOSED . FOLLOW THE CONNECTED CONTROL")
			get_viewport().set_input_as_handled()

func leave_to_title() -> void:
	if exiting: return
	exiting = true
	RunState.lab_active = false
	RunState.state = "menu"
	RunState.apply_deck()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func respawn() -> void:
	noise_cleared.clear()
	_sync_abilities()
	if drowned != null: drowned.reset_safe()
	if stand != null: stand.reset()
	if network != null: network.enter()
	if siphon != null: siphon.enter()
	if gate != null: gate.enter()
	if alignment != null: alignment.reset()
	if room_id == "gallery" and not profile.has_flag("catch"): lift_power = false
	if room_id in DrownedScript.IDS: enter_room("basin")
	player.reset_at(room.spawn)
	_spawn_noise()
	if room_id == "arrival" and profile.has_flag("first_beacon"): player.reset_at(Vector2(240,215))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or room.is_empty(): return
	if not paused and not map_open:
		elapsed += delta
		beacon_light_power = move_toward(beacon_light_power,1.0 if profile.has_flag("first_beacon") else 0.0,delta/0.8)
		window_light_power = move_toward(window_light_power,1.0 if profile.has_flag("west_ear") else 0.0,delta/0.8)
		memory_time = maxf(0.0,memory_time-delta)
		notice_time = maxf(0.0,notice_time-delta)
		player.position.x = clampf(player.position.x,8,472)
		if player.position.y > 278: respawn()
		if drowned != null: drowned.tick(delta)
		if siphon != null: siphon.tick(delta)
		if stand != null: stand.tick(delta)
		if network != null: network.tick(delta)
		if gate != null: gate.tick(delta)
		if room_id == "gallery" and is_instance_valid(lift):
			var target_y := 124.0 if lift_power or profile.has_flag("catch") else 220.0
			lift.position.y = move_toward(lift.position.y,target_y,36.0*delta)
		if room_id == "workshop" and not profile.has_flag("plate_seen") and Rect2(295,204,33,24).has_point(player.position):
			if _commit("plate_seen"): _notify("SHUTTER OPEN . FOLLOW THE CABLE")
	queue_redraw()

func _notify(text: String) -> void:
	notice = text
	notice_time = 5.0

func text_at(at: Vector2,text: String,color := DrawUtil.WHITE,text_scale := 1,align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	DrawUtil.text(self,at,text,color,text_scale,align)

func _draw() -> void:
	if room.is_empty() or not is_instance_valid(player): return
	draw_rect(Rect2(0,0,480,270),DrawUtil.BG)
	if far_texture != null and not room_id in ["wire_shaft","array_cable"]:
		var offset := roundf(player.position.x*0.08)
		draw_texture_rect(far_texture,Rect2(-offset-170,-105,960,320),false,Color(0.8,0.8,0.8,0.7))
	if ruins_texture != null and room_id in ["hub","workshop","gallery","amplifier","return","lookout","causeway","cellar","sump","arrival","wire_shelter","array"]:
		var offset := roundf(player.position.x*0.18)
		draw_texture_rect(ruins_texture,Rect2(-offset-110,-60,960,320),false,Color(0.85,0.85,0.85,0.8))
	# Non-repeating receiver silhouettes give the room a destination.
	for i in 0 if room_id in DrownedScript.IDS or room_id in ["array_cable","wire_shaft","basin","pump","float","shelter","conductor","flats","conduit","arrival","wire_shelter","wire_carriage","array","approach","gate","aftermath"] else 3:
		var center := Vector2(110+i*134,75+i%2*22)
		draw_arc(center,43,0.15,2.99,22,Color(0.15,0.15,0.15),3)
		draw_line(center+Vector2(0,39),center+Vector2(0,152),Color(0.12,0.12,0.12),3)
	_draw_window()
	if drowned != null: drowned.draw_world()
	if siphon != null: siphon.draw_world()
	if stand != null: stand.draw_world()
	if network != null: network.draw_world()
	if gate != null: gate.draw_world()
	if room_id == "amplifier": preload("res://scripts/amplifier_room.gd").draw(self)
	if room_id == "causeway": _draw_alignment()
	if room_id == "fourth": _draw_fourth_archive()
	if room_id in ["flats","conduit","arrival"]: _draw_flats()
	if room_id == "cellar":
		draw_rect(Rect2(190,80,42,87),DrawUtil.DARK)
		text_at(Vector2(184,60),"SOUTH INTAKE",DrawUtil.GRAY)
		if not profile.has_flag("south_ear"):
			draw_rect(Rect2(199,167,24,16),DrawUtil.GRAY)
			draw_polyline(PackedVector2Array([Vector2(213,168),Vector2(207,174),Vector2(216,176),Vector2(210,182)]),DrawUtil.BG,2)
		else:
			for i in 4:
				var y := 91+int(elapsed*18+i*18)%70
				draw_line(Vector2(202,y),Vector2(218,y),DrawUtil.GRAY,1)
	if room_id == "sump":
		for i in 3:
			var lit: bool = profile.has_flag(["west_ear","east_ear","south_ear"][i])
			draw_circle(Vector2(118+i*122,105),19,DrawUtil.WHITE if lit else DrawUtil.DARK)
			text_at(Vector2(118+i*122,136),["WEST LIFT","EAST DISH","SOUTH INTAKE"][i],DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
			draw_line(Vector2(118+i*122,155),Vector2(244,197),DrawUtil.GRAY if lit else DrawUtil.DARK,1)
	for rect in room.platforms: _draw_platform(rect)
	if room_id == "gallery":
		draw_line(Vector2(168,209),Vector2(225,209),DrawUtil.GRAY,1)
		draw_line(Vector2(225,120),Vector2(225,220),DrawUtil.DARK,2)
		draw_line(Vector2(168,205),Vector2(168,85),DrawUtil.DARK,1)
		draw_line(Vector2(168,85),Vector2(399,85),DrawUtil.GRAY if profile.has_flag("west_ear") else DrawUtil.DARK,1)
		if profile.has_flag("catch"):
			for rect in _stairs(): _draw_platform(rect)
		if is_instance_valid(lift): _draw_platform(Rect2(lift.position-Vector2(31,4),Vector2(62,8)))
	if room_id == "workshop":
		draw_rect(Rect2(296,220,31,4),DrawUtil.WHITE if profile.has_flag("plate_seen") else DrawUtil.GRAY)
		draw_line(Vector2(312,222),Vector2(444,222),DrawUtil.GRAY,1)
		draw_rect(Rect2(199,150,24,16),DrawUtil.DARK)
		draw_rect(Rect2(199,150,24,16),DrawUtil.WHITE,false,1)
		text_at(Vector2(207,154),"+",DrawUtil.WHITE)
		if memory_time > 0:
			for x in [237,263]:
				draw_rect(Rect2(x,181,6,7),DrawUtil.GRAY)
				draw_rect(Rect2(x-2,189,10,20),DrawUtil.GRAY)
			draw_line(Vector2(247,195),Vector2(263,195),DrawUtil.WHITE,2)
	if room_id == "lookout":
		for y in range(230,246,3): draw_line(Vector2(92,y),Vector2(480,y),Color(0.22,0.22,0.22),1)
		text_at(Vector2(333,107),"DROWNED ARRAY",DrawUtil.GRAY)
		text_at(Vector2(328,119),"LOWER SERVICE OPEN",DrawUtil.GRAY)
	if room_id == "array_cable":
		for mark in [239,261]:
			draw_line(Vector2(mark,219),Vector2(mark,224),DrawUtil.GRAY,1)
		draw_line(Vector2(243,222),Vector2(257,222),DrawUtil.DARK,1)
	for exit_data in room.exits:
		var at: Vector2 = exit_data[1]
		var color: Color = DrawUtil.GRAY if can_use_exit(exit_data[0]) else DrawUtil.DARK
		draw_rect(Rect2(at-Vector2(12,24),Vector2(24,31)),color,false,2)
		text_at(at-Vector2(3,12),">" if can_use_exit(exit_data[0]) else "X",color)
	for action in room.actions:
		if action[0] == "memory" or room_id == "wire_shaft": continue
		var at: Vector2 = action[1]
		draw_rect(Rect2(at-Vector2(8,9),Vector2(16,16)),DrawUtil.GRAY,false,1)
		text_at(at-Vector2(3,6),">" if action[0] == "dash" else "+")
	if network != null: network.shaft.draw_controls()
	var p := player.position.round()
	if player.dash_t > 0:
		draw_rect(Rect2(p.x-player.face*18-6,p.y-5,15,10),DrawUtil.GRAY)
	preload("res://scripts/spark_visual.gd").draw(self,player,player.visual_time)
	draw_rect(Rect2(0,0,480,29),Color(0.025,0.025,0.025,0.96))
	text_at(Vector2(12,7),room.title)
	var abilities := "DASH >>" if profile.has_flag("dash") else "SIGNAL --"
	if profile.has_flag("air_jump"): abilities += " . AIR +1"
	text_at(Vector2(468,7),abilities,DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_RIGHT)
	text_at(Vector2(12,19),Guidance.goal(self),DrawUtil.GRAY)
	draw_rect(Rect2(0,246,480,24),DrawUtil.BG)
	var near := _nearest()
	if notice_time > 0: text_at(Vector2(240,250),notice,DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
	elif not near.is_empty(): text_at(Vector2(240,250),("X . " if GameInput.controller_active else GameInput.action_label("interact") + " / DOWN . ")+String(near[2]),DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
	else: text_at(Vector2(240,250),("STICK MOVE . A JUMP . RB DASH . X USE . Y MAP" if GameInput.controller_active else GameInput.action_label("move_left") + "/" + GameInput.action_label("move_right") + " MOVE . " + GameInput.action_label("jump") + " JUMP . " + GameInput.action_label("interact") + " USE . M MAP"),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
	if profile.last_error != "": text_at(Vector2(12,260),"SAVE: "+String(profile.last_error).left(66),DrawUtil.WHITE)
	elif profile.has_flag("return_open"): text_at(Vector2(240,261),"THE WINDOW ANSWERS . YOUR REPAIR HOLDS",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
	if paused and (settings_menu == null or settings_menu.page == "home"):
		draw_rect(Rect2(0,29,480,217),Color(0,0,0,0.86))
		text_at(Vector2(240,106),"PAUSED",DrawUtil.WHITE,4,HORIZONTAL_ALIGNMENT_CENTER)
		text_at(Vector2(240,157),("B RESUME . VIEW RETURN TO TITLE" if GameInput.controller_active else "ESC RESUME . Q RETURN TO TITLE"),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
		text_at(Vector2(240,175),("X REDUCED FLASH: " if GameInput.controller_active else "F REDUCED FLASH: ")+("ON" if AppSettings.reduced_flashes else "OFF"),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
		text_at(Vector2(240,193),"A SETTINGS" if GameInput.controller_active else "O SETTINGS",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
	if map_open: _draw_map()

func map_state(id: String) -> String:
	if id in profile.data.visited: return "visited"
	if profile.has_flag("survey") and id in ["basin","pump","float","drowned_street","drowned_gallery","drowned_dock"]: return "surveyed"
	for visited in profile.data.visited:
		var known: Dictionary = Rooms.get_room(visited,profile.data.flags)
		for route in known.exits:
			if route[0] == id: return "hint"
	return "hidden"

func map_note(id: String) -> String:
	if id == "fourth" and map_state(id) != "hidden":
		if map_state(id) == "visited":
			return "ARCHIVE" if profile.has_flag("fourth_archive") else "SIGNAL UNREAD"
		return "REACHABLE" if profile.has_flag("air_jump") else "AIR JUMP NEEDED"
	if id == "amplifier" and map_state(id) == "visited" and preload("res://scripts/amplifier_room.gd").released(profile.data.flags):
		return "RETURN OPEN"
	var milestones := {
		"array_cable":["cable_archive","RETURN OPEN"],"array_inspection":["inspection_archive","ARCHIVE"],"drowned_gallery":["air_jump","AIR JUMP"],"drowned_cycle":["cycle_archive","ARCHIVE"],"amplifier":["dash","DASH FOUND"],"return":["return_open","SHORTCUT"],
		"wire_shaft":["wire_shaft_archive","ARCHIVE"],"lookout":["survey","SURVEYED"],"sump":["field_restored","FEED LIVE"],
		"pump":["pump_repaired","PUMP LIVE"],"float":["drowned_restored","FEED LIVE"],
		"conductor":["stand_restored","FEED LIVE"],"array":["array_restored","FEED LIVE"],
		"wire_carriage":["wire_repaired","REPAIRED"],"siphon":["siphon_return","SHORTCUT"],
		"gate":["signal_restored","RESTORED"],"arrival":["first_beacon","BEACON LIVE"]}
	if map_state(id) != "visited" or not milestones.has(id): return ""
	return milestones[id][1] if profile.has_flag(milestones[id][0]) else ""

func _draw_map() -> void:
	if map_help:
		_draw_map_help()
		return
	if map_region > 0:
		_draw_region_map()
		return
	draw_rect(Rect2(0,0,480,270),Color(0.02,0.02,0.02))
	text_at(Vector2(18,15),"RELAY SURVEY",DrawUtil.WHITE,3)
	text_at(Vector2(18,44),"OUTLINES ARE SURVEYED . NAMES ARE EXPLORED" if profile.has_flag("survey") else "VISITED PLACES HOLD . FAINT SIGNALS ARE UNEXPLORED",DrawUtil.GRAY)
	var positions := {"hub":Vector2(65,125),"workshop":Vector2(65,70),"gallery":Vector2(180,70),"amplifier":Vector2(295,70),"fourth":Vector2(410,70),"return":Vector2(295,125),"lookout":Vector2(65,183),"basin":Vector2(180,183),"causeway":Vector2(180,125)}
	var names := {"hub":"HUB","workshop":"WORKSHOP","gallery":"BALLAST","amplifier":"AMPLIFIER","fourth":"FOURTH DISH","return":"RETURN","lookout":"LOOKOUT","basin":"BASIN","causeway":"CAUSEWAY"}
	for link in [["hub","workshop"],["workshop","gallery"],["gallery","amplifier"],["amplifier","fourth"],["amplifier","return"],["return","hub"],["hub","causeway"],["causeway","return"],["hub","lookout"],["lookout","basin"]]:
		if map_state(link[0]) == "hidden" or map_state(link[1]) == "hidden": continue
		var color: Color = DrawUtil.GRAY if map_state(link[0]) == "visited" and map_state(link[1]) == "visited" else DrawUtil.DARK
		if link[0] == "return" and not profile.has_flag("return_open"): color = DrawUtil.DARK
		if link[0] == "causeway" and not profile.has_flag("east_ear"): color = DrawUtil.DARK
		if link[1] == "fourth" and not profile.has_flag("air_jump"): color = DrawUtil.DARK
		if link[0] == "basin" and link[1] == "float" and not profile.has_flag("float_latch"): color = DrawUtil.DARK
		if link[0] == "return" and link[1] == "hub":
			draw_polyline(PackedVector2Array([positions["return"],Vector2(295,150),Vector2(65,150),positions["hub"]]),color,1)
		elif link[0] == "basin" and link[1] == "float":
			draw_polyline(PackedVector2Array([positions["basin"],Vector2(180,210),Vector2(410,210),positions["float"]]),color,1)
		else: draw_line(positions[link[0]],positions[link[1]],color,1)
	for id in positions:
		var state := map_state(id)
		if state == "hidden": continue
		var at: Vector2 = positions[id]
		draw_rect(Rect2(at-Vector2(45,13),Vector2(90,27)),DrawUtil.DARK if state == "visited" else DrawUtil.BG)
		draw_rect(Rect2(at-Vector2(45,13),Vector2(90,27)),DrawUtil.WHITE if id == room_id else DrawUtil.GRAY if state == "visited" else DrawUtil.DARK,false,1)
		text_at(at-Vector2(0,4),names[id] if state == "visited" else "OUTLINE" if state == "surveyed" else "? SIGNAL",DrawUtil.WHITE if state == "visited" else DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
		if not map_note(id).is_empty(): text_at(at+Vector2(0,5),map_note(id),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
		if id == room_id: text_at(at+Vector2(0,17),"YOU",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
	if profile.has_flag("survey"):
		text_at(Vector2(25,215),"SURVEY: BLEED BEFORE PUMP",DrawUtil.GRAY)
		text_at(Vector2(25,227),Guidance.drowned_lead(profile),DrawUtil.WHITE)
	text_at(Vector2(240,253),("Y/B CLOSE . LB REGION . X HELP" if GameInput.controller_active else "M/ESC CLOSE . TAB REGION . H HELP"),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)

func stand_map_exits() -> String:
	var labels: PackedStringArray = []
	for route in [["stand_rim","return","RIM","FIELD"],["stand_sluice","pump","SLUICE","DROWNED"],["stand_bridge","wire_shelter","BRIDGE","WIRE"],["shelter","approach","COURT","SOURCE"]]:
		if map_state(route[0]) != "visited": continue
		labels.append(route[2]+": "+(route[3] if map_state(route[1]) == "visited" else "?"))
	return " . ".join(labels)

func _draw_region_map() -> void:
	draw_rect(Rect2(0,0,480,270),DrawUtil.BG)
	text_at(Vector2(18,15),{1:"THE STAND",2:"FIELD SERVICE",3:"FLATS LINE",4:"WIRE AND ARRAY",5:"THE SOURCE",6:"SIPHON SERVICE",7:"DROWNED ARRAY"}[map_region],DrawUtil.WHITE,3)
	text_at(Vector2(18,44),{1:"STORED CURRENT . SHELTERED RETURNS",2:"THREE EARS . ONE SHARED TRANSMITTER",3:"FIRST CARRIER . FIRST RECEIVER",4:"SHARED MAINTENANCE . INDEPENDENT FEEDS",5:"LOCAL FEEDS . A WORLD THAT REMEMBERS",6:"ONE SUPPLY . A RETURN THAT HOLDS",7:"EXPOSE THE STREET . RESTORE ITS RETURN"}[map_region],DrawUtil.GRAY)
	if map_region == 1: text_at(Vector2(18,62),stand_map_exits(),DrawUtil.GRAY)
	var points := {"stand_rim":Vector2(65,155),"shelter":Vector2(185,155),"stand_charge":Vector2(185,85),"conductor":Vector2(305,85),"stand_bridge":Vector2(305,155),"stand_sluice":Vector2(185,218),"stand_trial":Vector2(425,85)}
	var names := {"stand_rim":"BROKEN RIM","shelter":"COURT","stand_charge":"CHARGE BAY","conductor":"RESERVOIR","stand_bridge":"BRIDGE","stand_sluice":"SLUICE","stand_trial":"FRACTURE"}
	var links := [["stand_rim","shelter"],["shelter","stand_charge"],["stand_charge","conductor"],["conductor","stand_bridge"],["stand_bridge","shelter"],["shelter","stand_sluice"],["conductor","stand_trial"]]
	if map_region == 2:
		points = {"hub":Vector2(80,91),"causeway":Vector2(240,91),"return":Vector2(400,91),"cellar":Vector2(80,190),"lookout":Vector2(240,190),"sump":Vector2(400,190)}
		names = {"hub":"HUB","causeway":"CAUSEWAY","return":"RETURN","cellar":"INTAKE","lookout":"LOOKOUT","sump":"TRANSMITTER"}
		links = [["hub","cellar"],["cellar","lookout"],["lookout","sump"],["sump","causeway"],["causeway","hub"],["causeway","return"]]
	elif map_region == 3:
		points = {"flats":Vector2(80,120),"conduit":Vector2(240,120),"arrival":Vector2(400,120),"hub":Vector2(400,205)}
		names = {"flats":"FLATS","conduit":"CONDUIT","arrival":"RECEIVER","hub":"FIELD HUB"}
		links = [["flats","conduit"],["conduit","arrival"],["arrival","hub"]]
	elif map_region == 4:
		points = {"wire_shaft":Vector2(65,80),"wire_shelter":Vector2(65,145),"wire_carriage":Vector2(200,80),"array":Vector2(345,80),"stand_bridge":Vector2(65,210),"drowned_dock":Vector2(425,145),"array_inspection":Vector2(345,210),"array_cable":Vector2(200,210)}
		names = {"wire_shaft":"SHAFT","wire_shelter":"INSPECTION","wire_carriage":"CARRIAGE","array":"ARRAY","stand_bridge":"STAND","drowned_dock":"DROWNED","array_inspection":"NOISE BAY","array_cable":"CABLE WALK"}
		links = [["wire_shelter","wire_shaft"],["stand_bridge","wire_shelter"],["wire_shelter","wire_carriage"],["wire_carriage","array"],["drowned_dock","array"],["array","wire_shelter"],["array","array_inspection"],["array_inspection","array_cable"],["array_cable","wire_shelter"]]
	elif map_region == 5:
		points = {"array":Vector2(60,80),"approach":Vector2(180,80),"gate":Vector2(300,80),"source_return":Vector2(420,80),"shelter":Vector2(180,205),"hub":Vector2(60,205),"aftermath":Vector2(300,205),"source_walk":Vector2(420,205)}
		names = {"approach":"APPROACH","gate":"GANTRY","source_return":"RETURN","source_walk":"LOCAL WALK","aftermath":"AFTERMATH","array":"ARRAY","shelter":"STAND","hub":"FIELD HUB"}
		links = [["array","approach"],["approach","gate"],["gate","source_return"],["source_return","source_walk"],["source_walk","aftermath"],["approach","shelter"],["aftermath","hub"]]
		if profile.has_flag("signal_restored"): links.append(["gate","aftermath"])
	elif map_region == 6:
		points = {"pump":Vector2(80,145),"siphon":Vector2(240,100),"lookout":Vector2(400,145)}
		names = {"pump":"PUMP HOUSE","siphon":"SIPHON STACK","lookout":"LOOKOUT"}
		links = [["pump","siphon"],["siphon","lookout"]]
	elif map_region == 7:
		points = {"basin":Vector2(80,90),"pump":Vector2(240,90),"float":Vector2(400,90),"drowned_street":Vector2(80,175),"drowned_gallery":Vector2(240,175),"drowned_dock":Vector2(400,175),"drowned_cycle":Vector2(240,222)}
		names = {"basin":"HIGH RIM","pump":"PUMP HOUSE","float":"FLOAT","drowned_street":"OLD STREET","drowned_gallery":"GALLERY","drowned_dock":"FREIGHT","drowned_cycle":"SIDE BASIN"}
		links = [["basin","pump"],["basin","drowned_street"],["drowned_street","drowned_gallery"],["drowned_gallery","float"],["float","pump"],["drowned_gallery","drowned_dock"],["drowned_street","drowned_cycle"]]
	for link in links:
		if map_state(link[0]) == "hidden" or map_state(link[1]) == "hidden": continue
		var open := true
		if link[0] == "basin" and link[1] == "drowned_street": open = profile.has_flag("basin_bled") or drowned.main_y >= 241
		elif link[0] == "drowned_gallery": open = profile.has_flag("pump_repaired") if link[1] == "float" else profile.has_flag("drowned_restored")
		elif link[0] == "float": open = profile.has_flag("drowned_restored")
		elif link[0] == "siphon": open = profile.has_flag("siphon_return")
		elif link[0] == "pump": open = profile.has_flag("pump_repaired") if link[1] == "siphon" else profile.has_flag("drowned_restored")
		elif link[1] == "stand_bridge" or link[0] == "stand_bridge": open = profile.has_flag("stand_restored")
		elif link[0] == "return": open = profile.has_flag("dash") or profile.has_flag("stand_restored")
		elif link[0] == "sump": open = profile.has_flag("field_restored")
		elif link[0] == "causeway" and link[1] == "return": open = profile.has_flag("east_ear")
		elif link[0] == "conduit": open = profile.has_flag("conduit_open")
		elif link[0] == "arrival": open = profile.has_flag("first_beacon")
		elif link[0] == "wire_carriage": open = profile.has_flag("wire_repaired")
		elif link[0] == "array_cable": open = profile.has_flag("cable_archive")
		elif link[0] == "array": open = link[1] in ["array_inspection","wire_shelter"] or profile.has_flag("array_restored")
		elif link[0] == "approach": open = gate.ready() if link[1] == "gate" else profile.has_flag("approach_return")
		elif link[0] == "gate": open = profile.has_flag("signal_restored") if link[1] == "aftermath" else gate.progress().latched
		elif link[0] == "source_return": open = gate.progress().tested
		elif link[0] in ["source_walk","aftermath"]: open = profile.has_flag("signal_restored")
		var seen: bool = map_state(link[0]) == "visited" and map_state(link[1]) == "visited"
		var link_color: Color = DrawUtil.GRAY if open and seen else DrawUtil.DARK
		if map_region == 4 and link[0] == "array" and link[1] == "wire_shelter":
			draw_polyline(PackedVector2Array([points["array"],Vector2(345,145),Vector2(65,145),points["wire_shelter"]]),link_color,1)
		elif map_region == 5 and link[0] == "aftermath" and link[1] == "hub":
			draw_polyline(PackedVector2Array([points["aftermath"],Vector2(300,232),Vector2(60,232),points["hub"]]),link_color,1)
		else: draw_line(points[link[0]],points[link[1]],link_color,1)
	for id in points:
		var state := map_state(id)
		if state == "hidden": continue
		var at: Vector2 = points[id]
		draw_rect(Rect2(at-Vector2(48,13),Vector2(96,26)),DrawUtil.DARK if state == "visited" else DrawUtil.BG)
		draw_rect(Rect2(at-Vector2(48,13),Vector2(96,26)),DrawUtil.WHITE if id == room_id else DrawUtil.GRAY,false,1)
		text_at(at-Vector2(0,4),names[id] if state == "visited" else "OUTLINE" if state == "surveyed" else "? SIGNAL",DrawUtil.WHITE if state == "visited" else DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
		if not map_note(id).is_empty(): text_at(at+Vector2(0,5),map_note(id),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
		if id == room_id: text_at(at+Vector2(0,17),"YOU",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
	text_at(Vector2(240,253),("Y/B CLOSE . LB REGION . X HELP" if GameInput.controller_active else "M/ESC CLOSE . TAB REGION . H HELP"),DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_flats() -> void:
	draw_rect(Rect2(0,29,480,195),Color(0.15,0.13,0.09,0.18))
	for i in 5:
		var x := 30+i*105
		draw_arc(Vector2(x,180+i%2*15),39,0.1,3.04,22,DrawUtil.DARK,2)
		draw_line(Vector2(x,211),Vector2(x,224),DrawUtil.GRAY,2)
	if room_id == "flats":
		draw_rect(Rect2(199,168,24,16),DrawUtil.GRAY)
		text_at(Vector2(207,172),"+",DrawUtil.BG)
		if memory_time > 0:
			draw_rect(Rect2(256,188,6,7),DrawUtil.GRAY)
			draw_rect(Rect2(254,197,10,23),DrawUtil.GRAY)
			draw_line(Vector2(262,200),Vector2(291,187),DrawUtil.WHITE,2)
	elif room_id == "conduit":
		for x in [211,355]:
			draw_rect(Rect2(x-16,203,32,21),DrawUtil.GRAY,false,2)
			text_at(Vector2(x,191),"DOWN",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
		draw_line(Vector2(211,235),Vector2(355,235),DrawUtil.GRAY,3)
	elif room_id == "arrival":
		var lit: bool = profile.has_flag("first_beacon")
		coherence_light.draw(self,Vector2(240,171),beacon_light_power,Color(0.68,0.75,0.65,0.26))
		draw_rect(Rect2(234,173,12,43),DrawUtil.GRAY)
		draw_circle(Vector2(240,171),8,DrawUtil.WHITE if lit else DrawUtil.DARK)
		if lit: draw_arc(Vector2(240,171),18,0,TAU,24,DrawUtil.GRAY,1)

func _draw_fourth_archive() -> void:
	draw_arc(Vector2(180,78),47,0.1,3.05,28,DrawUtil.GRAY,3)
	draw_line(Vector2(182,122),Vector2(182,139),DrawUtil.GRAY,2)
	draw_line(Vector2(182,139),Vector2(245,139),DrawUtil.GRAY,2)
	draw_line(Vector2(270,139),Vector2(350,139),DrawUtil.GRAY,2)
	draw_rect(Rect2(347,96,35,44),DrawUtil.WHITE,false,2)
	for x in [353,364,375]: draw_rect(Rect2(x,101,4,31),DrawUtil.GRAY)
	# Isolator motion is memory only; the actual route never changes collision.
	var isolated := memory_time <= 0 or memory_time < 5
	draw_line(Vector2(246,139),Vector2(247,118) if isolated else Vector2(268,137),DrawUtil.WHITE,3)
	# The local reference remains coherent on both sides of the remembered cut.
	# Replaying the archive never removes a repair or changes room collision.
	draw_rect(Rect2(307,176,18,16),DrawUtil.GRAY,false,1)
	draw_rect(Rect2(313,180,6,8),DrawUtil.WHITE)
	draw_polyline(PackedVector2Array([Vector2(325,184),Vector2(390,184),Vector2(390,119),Vector2(382,119)]),DrawUtil.GRAY,2)
	for pane_x in [353,364,375]: draw_rect(Rect2(pane_x,106,4,23),DrawUtil.WHITE)
	coherence_light.draw(self,Vector2(364,118),0.65,Color(0.72,0.75,0.59,0.2))
	text_at(Vector2(307,200),"LOCAL REFERENCE",DrawUtil.GRAY)
	# Squared terminal faces and a parked knife distinguish isolation from decay.
	draw_rect(Rect2(242,135,5,8),DrawUtil.WHITE,false,1)
	draw_rect(Rect2(267,135,5,8),DrawUtil.WHITE,false,1)
	text_at(Vector2(222,105),"ISOLATED" if isolated else "COMMON",DrawUtil.GRAY)
	if memory_time > 0:
		draw_rect(Rect2(225,122,6,7),DrawUtil.GRAY)
		draw_rect(Rect2(223,131,10,19),DrawUtil.GRAY)
		draw_line(Vector2(229,134),Vector2(246,124 if isolated else 139),DrawUtil.WHITE,2)
		var pulse_x := 184+int((8-memory_time)*48)%61
		draw_rect(Rect2(pulse_x,136,5,5),DrawUtil.WHITE)
	text_at(Vector2(334,155),"WORKSHOP",DrawUtil.GRAY)

func _draw_alignment() -> void:
	for i in 3:
		var at := Vector2(120+i*98,91)
		var angle := float(alignment.positions[i])*PI/2
		var sight := float(alignment.target[i])*PI/2
		draw_arc(at,21,0,TAU,24,DrawUtil.GRAY,1)
		var target_end := at+Vector2.UP.rotated(sight)*32
		draw_line(at,target_end,DrawUtil.GRAY,1)
		draw_rect(Rect2(target_end-Vector2(3,3),Vector2(6,6)),DrawUtil.GRAY,false,1)
		draw_line(at,at+Vector2.UP.rotated(angle)*19,DrawUtil.WHITE,3)
		draw_circle(at,3,DrawUtil.WHITE)
		draw_line(at+Vector2(0,23),Vector2(at.x,room.actions[i][1].y-12),DrawUtil.DARK,1)
	text_at(Vector2(240,49),"THIN LINE: SIGHT . SOLID ARM: DISH",DrawUtil.GRAY,1,HORIZONTAL_ALIGNMENT_CENTER)
	if profile.has_flag("east_ear"):
		draw_line(Vector2(110,130),Vector2(380,130),DrawUtil.WHITE,1)
		text_at(Vector2(240,137),"EAST EAR RESTORED",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)

func _draw_platform(rect: Rect2, use_material: bool = true) -> void:
	draw_rect(rect,DrawUtil.DARK)
	if use_material and room_id in DrownedScript.IDS and drowned_material.texture != null:
		drowned_material.draw(self,rect)
	else:
		for x in range(int(rect.position.x)+8,int(rect.end.x),16):
			draw_line(Vector2(x,rect.position.y+4),Vector2(x,minf(rect.end.y,rect.position.y+12)),Color(0.12,0.12,0.12),1)
	draw_line(rect.position,rect.position+Vector2(rect.size.x,0),DrawUtil.GRAY,2)

func _draw_window() -> void:
	if not room_id in ["hub","workshop","return"]: return
	var at := Vector2(355,82) if room_id == "workshop" else Vector2(252,65)
	var lit: bool = profile.has_flag("west_ear")
	coherence_light.draw(self,at+Vector2(24,26),window_light_power,Color(0.77,0.73,0.60,0.23))
	if window_texture != null:
		draw_texture_rect(window_texture,Rect2(at,Vector2(48,64)),false,Color.WHITE if lit else Color(0.5,0.5,0.5))
	else:
		draw_rect(Rect2(at,Vector2(37,43)),DrawUtil.WHITE if lit else DrawUtil.DARK,false,2)
		for i in 3: draw_rect(Rect2(at+Vector2(4+i*11,4),Vector2(7,34)),DrawUtil.GRAY if lit else Color(0.12,0.12,0.12))
		draw_line(at+Vector2(4,5),at+Vector2(22,28),DrawUtil.BG,3)

func _draw_map_help() -> void:
	draw_rect(Rect2(0,0,480,270),Color(0.02,0.02,0.02))
	text_at(Vector2(18,15),"READING THE SIGNAL",DrawUtil.WHITE,2)
	var rows := [
		["YOU", "YOUR ROOM HAS A BRIGHT BORDER"],
		["ROOM NAME", "VISITED . REMEMBERED BETWEEN SESSIONS"],
		["? SIGNAL", "AN EXIT LEADS HERE . STILL UNEXPLORED"],
		["OUTLINE", "SURVEYED SHAPE . ENTER TO LEARN ITS NAME"],
		["DIM ROUTE", "UNEXPLORED OR WAITING FOR A REPAIR"],
		["SURVEY", "USE THE LOOKOUT TO REVEAL DROWNED OUTLINES"]]
	for i in rows.size():
		var y := 52+i*29
		text_at(Vector2(18,y),rows[i][0],DrawUtil.WHITE)
		text_at(Vector2(18,y+11),rows[i][1],DrawUtil.GRAY)
	text_at(Vector2(18,234),"DISTANT PLACES STAY HIDDEN UNTIL DISCOVERED",DrawUtil.GRAY)
	text_at(Vector2(240,253),"X/B BACK . Y CLOSE" if GameInput.controller_active else "H/ESC BACK . M CLOSE",DrawUtil.WHITE,1,HORIZONTAL_ALIGNMENT_CENTER)
