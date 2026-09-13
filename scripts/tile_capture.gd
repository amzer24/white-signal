extends SceneTree

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(1440,540))
    root.content_scale_size = Vector2i(1440,540)
    var board := Node2D.new()
    root.add_child(board)
    var files := ["far-terrain.png","mid-ruins.png","near-cables-straight.png"]
    var textures: Array[Texture2D] = []
    for file in files:
        textures.append(load("res://assets/backgrounds/afterlight-v2/"+file))
    for style in ["dark","light","checker"]:
        var draw_board := func() -> void:
            board.draw_rect(Rect2(0,0,1440,540),Color("080808") if style == "dark" else Color("bbbbbb"))
            if style == "checker":
                for y in range(0,540,16):
                    for x in range(0,1440,16):
                        if (x/16+y/16)%2 == 0:
                            board.draw_rect(Rect2(x,y,16,16),Color("777777"))
            for row in 3:
                for column in 3:
                    board.draw_texture_rect(textures[row],Rect2(column*480,row*180+20,480,160),false)
                board.draw_string(ThemeDB.fallback_font,Vector2(12,row*180+16),files[row]+" — normal repeat ×3; joins at 480 and 960",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE if style=="dark" else Color.BLACK)
        board.draw.connect(draw_board)
        board.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://test-user/tile-board-"+style+".png")
        board.draw.disconnect(draw_board)
    print("TILE BOARDS COMPLETE")
    quit()
