extends "res://scripts/opening_playthrough_test.gd"
## Fresh journey: choose Field -> Stand -> Wire before repairing Drowned.
func drowned_route() -> void:
    if scene.profile.has_flag("array_restored"):
        await super.drowned_route()
        return
    # Current room is surveyed Lookout, reached by the shared opening.
    await land(158,183,false)
    await land(26,217,false)
    await use_control()
    if not require_room("hub"): return
    await land(280,217,false)
    await land(346,184)
    await use_control()
    if not require_room("return"): return
    await land(250,217,false)
    await land(115,217,false)
    await land(169,184)
    await use_control()
    if not require_room("stand_rim"): return
    await land(220,217,false)
    await land(390,217,false)
    await land(445,217,false)
    await use_control()
    if not require_room("shelter"): return
    if scene.profile.has_flag("drowned_restored") or scene.profile.has_flag("air_jump"):
        failed += 1
        print("FAIL alternate arrival must precede Drowned and Air Jump")
        return
    await stand_core()

func field_return_route() -> void:
    if scene.profile.has_flag("drowned_restored"):
        await super.field_return_route()
        return
    print("WIRE FIRST: Array restored before Drowned, air jump=",scene.profile.has_flag("air_jump"))
    await land(174,217,false)
    await use_control()
    if not require_room("wire_shelter"): return
    await land(180,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("stand_bridge"): return
    await land(190,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("shelter"): return
    await land(250,217,false)
    await land(100,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("stand_rim"): return
    await land(250,217,false)
    await land(90,217,false)
    await land(27,217,false)
    await use_control()
    if not require_room("return"): return
    await land(235,217,false)
    await land(432,217,false)
    await use_control()
    if not require_room("hub"): return
    await land(280,217,false)
    await land(430,217,false)
    await use_control()
    if not require_room("lookout"): return
    await land(113,183)
    await land(158,183,false)
    await land(221,147)
    await super.drowned_route()
