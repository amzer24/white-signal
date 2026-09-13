extends SceneTree
func _initialize() -> void:
    if not FileAccess.file_exists("res://scripts/signal_alignment.gd"):
        print("FAIL: alignment module missing")
        quit(1)
        return
    var puzzle = load("res://scripts/signal_alignment.gd").new()
    assert(not puzzle.latch())
    assert(not puzzle.rotate(-1) and not puzzle.rotate(3))
    for i in 4: puzzle.rotate(0)
    assert(puzzle.positions == [0,0,0])
    puzzle.rotate(0)
    assert(puzzle.reset() and puzzle.positions == [0,0,0])
    for i in 3:
        for step in puzzle.target[i]: puzzle.rotate(i)
    assert(puzzle.is_aligned() and puzzle.latch())
    assert(not puzzle.rotate(0) and not puzzle.reset())
    print("ALIGNMENT: 0 failures")
    quit()
