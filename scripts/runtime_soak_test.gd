extends SceneTree
var scene: Node2D
var report := {}
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
    for i in count: await process_frame
func snapshot() -> Dictionary:
    return {"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"static_bytes":OS.get_static_memory_usage()}
func percentile(values: Array, fraction: float) -> float:
    values.sort()
    return values[mini(values.size()-1,int(values.size()*fraction))]
func run() -> void:
    Engine.max_fps = 60
    scene = load("res://scenes/exploration.tscn").instantiate()
    scene.save_path = "res://test-user/runtime_soak.json"
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute(scene.save_path+suffix)
    root.add_child(scene)
    scene.profile.set_flags({"first_beacon":true,"west_ear":true,"dash":true,"air_jump":true,"drowned_restored":true,"pump_repaired":true,"stand_restored":true,"wire_repaired":true,"array_restored":true,"wire_shaft_released":true,"wire_shaft_archive":true})
    var samples := {}
    for id in ["arrival","drowned_gallery","conductor","wire_carriage","wire_shaft","array_inspection"]:
        scene.enter_room(id)
        if id == "wire_shaft":
            scene.activate("shaft_release")
            scene.activate("shaft_ride")
        await frames(90)
        var frame_times: Array = []
        var process_times: Array = []
        var draws: Array = []
        var previous := Time.get_ticks_usec()
        for i in 120:
            await RenderingServer.frame_post_draw
            var now := Time.get_ticks_usec()
            frame_times.append(float(now-previous)/1000)
            previous = now
            process_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
            draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
        samples[id] = {"frame_p50_ms":percentile(frame_times,0.5),"frame_p95_ms":percentile(frame_times,0.95),"frame_max_ms":frame_times.max(),"process_p95_ms":percentile(process_times,0.95),"draw_calls_max":draws.max()}
        print("MEASURED ",id," ",JSON.stringify(samples[id]))
    report["render_samples"] = samples
    report["frame_cap"] = Engine.max_fps
    var checkpoints: Array = []
    for cycle in 60:
        for id in ["wire_shelter","wire_shaft","array","array_inspection"]:
            scene.enter_room(id)
            await frames(2)
        scene.enter_room("wire_shaft")
        await frames(3)
        if cycle in [9,29,59]:
            var sample := snapshot()
            sample["cycles"] = cycle+1
            checkpoints.append(sample)
            print("SOAK ",JSON.stringify(sample))
    report["soak"] = checkpoints
    report["renderer"] = RenderingServer.get_video_adapter_name()
    report["scope"] = "Six current rooms, 120 rendered frames each after 90-frame warmup at explicit 60fps cap; 300 room transitions in one scene. Development geometry, not final content or minimum hardware."
    scene.queue_free()
    await frames(5)
    report["after_scene_free"] = snapshot()
    var file := FileAccess.open("res://test-user/runtime-soak-report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    for suffix in ["", ".tmp", ".bak"]: DirAccess.remove_absolute("res://test-user/runtime_soak.json"+suffix)
    print("RUNTIME SOAK COMPLETE")
    quit()
