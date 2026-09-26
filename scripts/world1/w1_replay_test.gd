extends SceneTree
## Replays each level's proven route (levels/world1/<id>.route.json, written by
## tools/levels/build_maps.py) through the game's own World 1 rules. If the
## Godot port and the Python proof ever disagree, a level stops finishing here.
##   godot --headless --path . --script res://scripts/world1/w1_replay_test.gd

const Level := preload("res://scripts/world1/w1_level.gd")
const Sim := preload("res://scripts/world1/w1_sim.gd")
const LEVELS := ["test-room", "1-1", "1-2", "1-3", "1-4", "2-1", "2-2", "2-3", "2-4", "3-1", "3-2", "3-3", "3-4"]


func _initialize() -> void:
	var failures := 0
	for id in LEVELS:
		var route = JSON.parse_string(FileAccess.get_file_as_string(Level.path_for(id).replace(".txt", ".route.json")))
		var L = Level.load_file(id)
		var S = Sim.new(L)
		S.proof_mode = true
		S.place(L.start)
		S.invuln = 0.0
		var frames: String = route.frames
		var n := 0
		while n < frames.length() and not S.won and S.dead == "":
			var d := int(frames[n]) - 1
			S.advance(d, frames[n + 1] == "1", frames[n + 2] == "1")
			n += 3
		# the proof ends when the mast is touched; allow a few frames of drift
		var extra := 0
		while not S.won and S.dead == "" and extra < 20:
			S.advance(1, false, false)
			extra += 1
		var ok: bool = S.won
		if not ok:
			failures += 1
		print("%s  %s  frame %d/%d  at tile %.1f,%.1f  %s" % ["PASS" if ok else "FAIL", id, n / 3,
			frames.length() / 3, S.x / 16.0, S.y / 16.0, S.dead])
	print("W1 REPLAY: %d failure(s)" % failures)
	quit(1 if failures else 0)
