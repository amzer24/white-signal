extends SceneTree

func _initialize() -> void:
    var results: Array = []
    for file in ["far-terrain.png","mid-ruins.png","near-cables.png","near-cables-straight.png"]:
        var img := Image.load_from_file("res://assets/backgrounds/afterlight-v2/"+file)
        var w := img.get_width()
        var h := img.get_height()
        var scores: Array[float] = []
        var alpha_scores: Array[float] = []
        for x in w:
            var rgb := 0.0
            var alpha := 0.0
            for y in h:
                var a := img.get_pixel(x,y)
                var b := img.get_pixel((x+1)%w,y)
                rgb += absf(a.r*a.a-b.r*b.a)
                alpha += absf(a.a-b.a)
            scores.append(rgb/h)
            alpha_scores.append(alpha/h)
        var seam: float = scores.pop_back()
        var alpha_seam: float = alpha_scores.pop_back()
        scores.sort()
        alpha_scores.sort()
        var record := {"file":file,"size":str(img.get_size()),"rgb_wrap":seam,"rgb_internal_p95":scores[int(scores.size()*0.95)],"alpha_wrap":alpha_seam,"alpha_internal_p95":alpha_scores[int(alpha_scores.size()*0.95)]}
        results.append(record)
        print(JSON.stringify(record))
    var f := FileAccess.open("res://test-user/tile-seams.json",FileAccess.WRITE)
    f.store_string(JSON.stringify(results,"  "))
    quit()
