extends RefCounted
## Optional research room. Three memories, one route, no random glyph requirements.

static func build() -> Dictionary:
    var l := LevelData.blank_level("THE ROOM REMEMBERS", 2320, 1)
    l["objective"] = "WAKE THREE MEMORIES"
    l["required_memories"] = 3
    l["lab"] = true
    l.goal = Rect2(2230, 150, 26, 80)
    for r in [Rect2(0,230,800,40), Rect2(830,230,450,40), Rect2(1310,230,1010,40)]:
        LevelData.platform(l, r, "ground")
    for r in [Rect2(460,194,70,36), Rect2(550,158,90,72),
            Rect2(1460,194,70,36), Rect2(1550,158,120,72), Rect2(1730,194,70,36)]:
        LevelData.platform(l, r)
    LevelData.fixture(l, "memory", 270, 179, "THE OPERATOR")
    LevelData.fixture(l, "memory", 1030, 179, "THE MACHINE")
    LevelData.fixture(l, "memory", 1600, 107, "THE LAST SHIFT")
    for x in [80, 740, 1420, 2100]:
        l.checkpoints.append({"pos": Vector2(x,230)})
    LevelData.sign_at(l, 100, 185, "HIT TO REMEMBER")
    LevelData.sign_at(l, 350, 141, "LIGHT LEAVES TRACES")
    LevelData.sign_at(l, 900, 189, "THE MACHINE WAITS")
    LevelData.sign_at(l, 1470, 122, "ONE LAST SHIFT")
    LevelData.sign_at(l, 2100, 189, "CARRY THEM ON")
    return l
