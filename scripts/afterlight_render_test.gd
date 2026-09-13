extends SceneTree

var failures := 0
func check(label: String, ok: bool) -> void:
    print(("PASS " if ok else "FAIL ")+label)
    if not ok: failures += 1
func average(img: Image, area: Rect2i) -> float:
    var sum := 0.0
    for y in range(area.position.y,area.end.y,2):
        for x in range(area.position.x,area.end.x,2):
            sum += img.get_pixel(x,y).r
    return sum / float(area.size.x*area.size.y/4)
func _initialize() -> void:
    var path := "res://assets/backgrounds/afterlight-v2/"
    for file in ["far-terrain.png","mid-ruins.png","near-cables-straight.png"]:
        var img := Image.load_from_file(path+file)
        check(file+" has actual transparency",img.detect_alpha()!=Image.ALPHA_NONE)
    var normal := Image.load_from_file("res://test-user/afterlight-normal.png")
    var dark := Image.load_from_file("res://test-user/afterlight-dark.png")
    var memory := Image.load_from_file("res://test-user/afterlight-memory.png")
    check("captures use 2x integer display scaling",normal.get_size()==Vector2i(960,540))
    # Sample the new low ruins plane, above the solid floor and left of the player.
    var backdrop := Rect2i(50,330,180,40)
    var ordinary := average(normal,backdrop)
    var dimmed := average(dark,backdrop)
    var recalled := average(memory,backdrop)
    check("authored dark reduces background luminance",dimmed < ordinary * 0.8)
    check("memory visibly restores the same background",recalled > dimmed * 1.2)
    # A fixed patch of the rightmost solid step stays identically lit in every mode.
    var same := true
    for y in range(250,300):
        for x in range(850,930):
            if normal.get_pixel(x,y) != dark.get_pixel(x,y) or dark.get_pixel(x,y) != memory.get_pixel(x,y):
                same = false
    check("solid step pixels are unaffected by darkness or memory",same)
    print("AFTERLIGHT RENDER: %d failure(s)" % failures)
    quit(1 if failures else 0)
