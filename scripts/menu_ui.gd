extends Node2D
## THESIS: a short action list; controls and preferences get their own page.
## OWN-WORLD: existing four-gray pixel font, square focus plate, single rules.
## STORY: continue or start, then adjust sound/display without losing a run.
## FIRST VIEWPORT: title above up to eight keyboard/mouse-selectable rows.
## FORM: local extension of the established Godot menu; no new visual identity.

var page := "home"
var settings_only := false
var selected := 0
var return_selected := 0
var dragging := -1
var exploration_unreadable := false
var exploration_saved := false
var recovery_message := ""
var recovery_archive := ""
var exploration_path := "user://ws_exploration_v1.json"
var exploration_label := "START EXPLORATION"
var exploration_detail := "A LASTING JOURNEY . DISCOVERIES SAVE AUTOMATICALLY"

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and page == "keyboard":
        GameInput.keyboard.capturing = ""
        GameInput.keyboard.shift_pending = false

func refresh_exploration() -> void:
    exploration_unreadable = false
    exploration_saved = false
    var profile = preload("res://scripts/exploration_save.gd").new()
    profile.path = exploration_path
    exploration_label = "START EXPLORATION"
    exploration_detail = "A LASTING JOURNEY . DISCOVERIES SAVE AUTOMATICALLY"
    if profile.load_profile():
        exploration_saved = true
        exploration_label = "RESUME EXPLORATION"
        var place: String = preload("res://scripts/exploration_rooms.gd").get_room(profile.data.room).title
        exploration_detail = "RESUME: " + place
        if profile.recovered_backup: exploration_detail = "BACKUP AVAILABLE . " + place
    elif not profile.last_error.is_empty():
        exploration_unreadable = true
        exploration_label = "EXPLORATION SAVE"
        exploration_detail = "SAVE UNREADABLE . ORIGINAL RETAINED"


func _ready() -> void:
    RunState.state_changed.connect(_on_state)
    refresh_exploration()

func _on_state(state: String) -> void:
    if state == "menu":
        refresh_exploration()
        page = "home"
        selected = 0

func _process(_delta: float) -> void:
    visible = (not settings_only and RunState.state == "menu") or page != "home"
    queue_redraw()

func home_items() -> Array:
    var items: Array = [[exploration_label,exploration_detail,"explore"]]
    if exploration_saved:
        items.append(["NEW EXPLORATION","KEEP PREVIOUS SAVE . BEGIN A NEW JOURNEY","restart_explore"])
    if get_parent().can_resume:
        items.append(["RESUME CLASSIC","RESUME CLASSIC AT YOUR LAST RELAY BOUNDARY","continue"])
    items.append(["NEW CLASSIC RUN","RESTART CLASSIC . EXPLORATION SAVE IS SEPARATE","new"])
    items.append(["SETTINGS","MUSIC . EFFECTS . DISPLAY","settings"])
    items.append(["HOW TO PLAY","MOVEMENT . GLYPHS . CONDUITS","controls"])
    items.append(["EXTRAS","CREDITS . AFTERLIGHT STUDY","extras"])
    items.append(["QUIT GAME","RETURN TO DESKTOP","quit"])
    return items

func open_settings() -> void:
    return_selected = selected
    page = "settings"
    selected = 0

func back() -> void:
    if page == "credits":
        page = "extras"
        selected = 0
        return
    if page == "keyboard":
        GameInput.keyboard.capturing = ""
        page = "settings"
        selected = 5
        return
    if dragging >= 0: AppSettings.save_preferences()
    dragging = -1
    page = "home"
    selected = return_selected

func row_count() -> int:
    if page == "home": return home_items().size()
    if page == "extras": return 3
    if page in ["recovery","recovery_confirm","recovery_done","new_journey"]: return 2
    if page in ["settings","keyboard"]: return 7
    return 1

func row_rect(index: int) -> Rect2:
    if page == "extras": return Rect2(120,106+index*31,240,24)
    if page == "keyboard": return Rect2(80,65+index*22,320,21)
    if page in ["recovery","recovery_confirm","recovery_done","new_journey"]: return Rect2(80,174+index*28,320,24)
    if page == "home":
        return Rect2(120,99+index*16,240,15) if home_items().size() > 7 else Rect2(120,105+index*18,240,17)
    if page == "settings": return Rect2(80,84+index*21,320,20)
    return Rect2(120,223,240,22)

func label(at: Vector2, text: String, size := 1, color := DrawUtil.WHITE, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
    DrawUtil.text(self,at,text,color,size,alignment)

func _draw() -> void:
    if settings_only and page == "home": return
    if not visible: return
    draw_rect(Rect2(0,0,480,270),Color(0,0,0,0.78 if page == "home" else 0.96))
    if page == "home":
        label(Vector2(240,43),"WHITE SIGNAL",5,DrawUtil.WHITE,HORIZONTAL_ALIGNMENT_CENTER)
        label(Vector2(240,83),"CARRY THE SPARK TO THE GATE",1,DrawUtil.GRAY,HORIZONTAL_ALIGNMENT_CENTER)
        var items := home_items()
        selected = clampi(selected,0,items.size()-1)
        for i in items.size():
            var rect := row_rect(i)
            if i == selected: draw_rect(rect,DrawUtil.WHITE)
            label(rect.position+Vector2(18,2),items[i][0],2,DrawUtil.BG if i==selected else DrawUtil.WHITE)
            if i == selected: label(rect.position+Vector2(5,7),"> ",1,DrawUtil.BG)
        label(Vector2(240,235),items[selected][1],1,DrawUtil.GRAY,HORIZONTAL_ALIGNMENT_CENTER)
        label(Vector2(240,252),"D-PAD SELECT . A CONFIRM" if GameInput.controller_active else "UP/DOWN SELECT . ENTER CONFIRM . CLICK",1,DrawUtil.GRAY,HORIZONTAL_ALIGNMENT_CENTER)
    elif page == "new_journey":
        label(Vector2(60,36),"NEW JOURNEY",3)
        label(Vector2(60,82),"YOUR PREVIOUS SAVE WILL BE RETAINED",1,DrawUtil.GRAY)
        label(Vector2(60,103),"THE ACTIVE JOURNEY WILL START AT THE FLATS",1,DrawUtil.GRAY)
        label(Vector2(60,124),"ABILITIES AND DISCOVERIES START FRESH",1,DrawUtil.WHITE)
        for i in 2:
            var rect := row_rect(i)
            if i == selected: draw_rect(rect,DrawUtil.WHITE)
            label(rect.position+Vector2(8,8),["BACK","RETAIN SAVE / START NEW"][i],1,DrawUtil.BG if i == selected else DrawUtil.WHITE)
        label(Vector2(60,239),recovery_message,1,DrawUtil.GRAY)
    elif page == "recovery_done":
        label(Vector2(60,36),"JOURNEY READY",3)
        label(Vector2(60,82),"YOUR ORIGINAL FILES HAVE BEEN RETAINED",1,DrawUtil.GRAY)
        label(Vector2(60,103),"OPEN THEIR FOLDER TO INSPECT OR COPY THEM",1,DrawUtil.GRAY)
        label(Vector2(60,124),"RETURN TO THE MENU TO START EXPLORING",1,DrawUtil.WHITE)
        for i in 2:
            var rect := row_rect(i)
            if i == selected: draw_rect(rect,DrawUtil.WHITE)
            label(rect.position+Vector2(8,8),["BACK TO MENU","OPEN RETAINED FILES"][i],1,DrawUtil.BG if i == selected else DrawUtil.WHITE)
        label(Vector2(60,239),recovery_message,1,DrawUtil.GRAY)
    elif page in ["recovery","recovery_confirm"]:
        label(Vector2(60,36),"SAVE RECOVERY",3)
        label(Vector2(60,82),"THE EXPLORATION SAVE CANNOT BE READ",1,DrawUtil.GRAY)
        label(Vector2(60,103),"CURRENT AND BACKUP FILES WILL BE RETAINED",1,DrawUtil.GRAY)
        label(Vector2(60,124),"STARTING FRESH RESETS YOUR ACTIVE JOURNEY",1,DrawUtil.WHITE)
        var choices := ["BACK","CONFIRM NEW JOURNEY" if page == "recovery_confirm" else "RETAIN ORIGINALS / START FRESH"]
        for i in 2:
            var rect := row_rect(i)
            if i == selected: draw_rect(rect,DrawUtil.WHITE)
            label(rect.position+Vector2(8,8),choices[i],1,DrawUtil.BG if i == selected else DrawUtil.WHITE)
        label(Vector2(60,239),recovery_message,1,DrawUtil.GRAY)
    elif page == "keyboard":
        label(Vector2(80,25),"KEYBOARD",4)
        var names := ["MOVE LEFT","MOVE RIGHT","JUMP","DASH","USE","RESTORE DEFAULTS","BACK"]
        for i in names.size():
            var rect := row_rect(i)
            if i == selected: draw_rect(rect,DrawUtil.DARK)
            label(rect.position+Vector2(8,7),names[i])
            if i < 5:
                var action: String = GameInput.keyboard.ACTIONS[i]
                label(rect.position+Vector2(308,7),"PRESS KEY..." if GameInput.keyboard.capturing == action else GameInput.keyboard.key_label(action),1,DrawUtil.WHITE,HORIZONTAL_ALIGNMENT_RIGHT)
        label(Vector2(80,230),GameInput.keyboard.error,1,DrawUtil.WHITE)
        label(Vector2(80,249),"ESC / B CANCEL . MENU AND MAP KEYS STAY FIXED",1,DrawUtil.GRAY)
    elif page == "settings":
        label(Vector2(80,35),"SETTINGS",4)
        label(Vector2(80,64),"SOUND AND DISPLAY",1,DrawUtil.GRAY)
        var names := ["MUSIC","EFFECTS","FULLSCREEN","REDUCED FLASH","CAMERA SHAKE","KEYBOARD","BACK"]
        for i in 7:
            var rect := row_rect(i)
            if i == selected:
                draw_rect(rect,DrawUtil.DARK)
                draw_rect(rect,DrawUtil.GRAY,false,1)
                label(rect.position+Vector2(-12,9),">")
            label(rect.position+Vector2(8,8),names[i])
            if i < 2:
                var volume: float = AppSettings.music_volume if i==0 else AppSettings.sfx_volume
                var bar := Rect2(230,rect.position.y+10,120,4)
                draw_rect(bar,DrawUtil.DARK)
                draw_rect(Rect2(bar.position,Vector2(roundf(120*volume),4)),DrawUtil.WHITE)
                draw_rect(Rect2(228+roundf(120*volume),rect.position.y+7,4,10),DrawUtil.WHITE)
                label(Vector2(388,rect.position.y+8),"%d%%"%roundi(volume*100),1,DrawUtil.WHITE,HORIZONTAL_ALIGNMENT_RIGHT)
            elif i == 2:
                label(Vector2(388,rect.position.y+8),"ON" if AppSettings.fullscreen else "OFF",1,DrawUtil.WHITE,HORIZONTAL_ALIGNMENT_RIGHT)
            elif i == 3:
                label(Vector2(388,rect.position.y+8),"ON" if AppSettings.reduced_flashes else "OFF",1,DrawUtil.WHITE,HORIZONTAL_ALIGNMENT_RIGHT)
            elif i == 4:
                label(Vector2(388,rect.position.y+8),"ON" if AppSettings.camera_shake else "OFF",1,DrawUtil.WHITE,HORIZONTAL_ALIGNMENT_RIGHT)
        label(Vector2(80,237),"D-PAD ADJUST . A TOGGLE . B BACK" if GameInput.controller_active else "LEFT/RIGHT ADJUST . ENTER TOGGLE . ESC BACK",1,DrawUtil.GRAY)
        label(Vector2(80,252),"SAVED AUTOMATICALLY" if AppSettings.save_error.is_empty() else AppSettings.save_error,1,DrawUtil.GRAY if AppSettings.save_error.is_empty() else DrawUtil.WHITE)
    elif page == "extras":
        label(Vector2(80,32),"EXTRAS",4)
        label(Vector2(80,74),"BEHIND THE SIGNAL",1,DrawUtil.GRAY)
        var items := ["CREDITS","AFTERLIGHT STUDY","BACK"]
        for i in items.size():
            var rect := row_rect(i)
            if selected == i: draw_rect(rect,DrawUtil.WHITE)
            label(Vector2(240,rect.position.y+8),items[i],2,DrawUtil.BG if selected == i else DrawUtil.GRAY,HORIZONTAL_ALIGNMENT_CENTER)
        label(Vector2(80,227),"A SELECT . B BACK" if GameInput.controller_active else "ENTER SELECT . ESC BACK",1,DrawUtil.GRAY)
    elif page == "credits":
        label(Vector2(80,32),"CREDITS",4)
        var lines := [["ENGINE","GODOT"],["PIXEL ART TOOLS","PIXELLAB . IMAGEGEN"],["EXPLORATION SCORE","DEAD CARRIER . SUNO"],["EFFECTS","PROCEDURAL SYNTHESIS"],["TUTORIAL AUDIO","PROVIDED BY THE CREATOR"]]
        for i in lines.size():
            label(Vector2(80,73+i*27),lines[i][0],1,DrawUtil.GRAY)
            label(Vector2(80,84+i*27),lines[i][1])
        draw_rect(row_rect(0),DrawUtil.WHITE)
        label(Vector2(240,230),"BACK",2,DrawUtil.BG,HORIZONTAL_ALIGNMENT_CENTER)
    else:
        label(Vector2(80,32),"HOW TO PLAY",4)
        var controls := [
            ["MOVE",GameInput.keyboard.key_label("move_left") + " . " + GameInput.keyboard.key_label("move_right")],
            ["JUMP",GameInput.keyboard.key_label("jump") + " . HOLD FOR HEIGHT"],
            ["WALL KICK","HOLD INTO WALL + JUMP"],
            ["EXPLORE",GameInput.keyboard.key_label("interact") + " / DOWN USE . M MAP"],
            ["DASH",GameInput.keyboard.key_label("dash") + " . FIND PROTOCOL IN EXPLORE"],
            ["RESPAWN","R . DISCOVERIES REMAIN IN EXPLORE"],
            ["PAUSE","P / ESC . Q TITLE IN EXPLORE"],
        ]
        if GameInput.controller_active:
            controls = [
                ["MOVE","LEFT STICK / D-PAD"],
                ["JUMP","A . HOLD FOR HEIGHT"],
                ["WALL KICK","HOLD INTO WALL + A"],
                ["EXPLORE","X USE . Y MAP . LB MAP PAGE"],
                ["DASH","RB . FIND PROTOCOL IN EXPLORE"],
                ["BACK","B CLOSE MAP / RESUME"],
                ["PAUSE","START . VIEW TITLE IN EXPLORE"],
            ]
        for i in controls.size():
            label(Vector2(80,73+i*18),controls[i][0],1,DrawUtil.GRAY)
            label(Vector2(160,73+i*18),controls[i][1])
        label(Vector2(80,205),"CLASSIC: A/X/Y CHOOSE . B SKIP" if GameInput.controller_active else "CLASSIC RUN: 5 SHARDS = SURGE . 1/2/3 CHOOSE",1,DrawUtil.GRAY)
        draw_rect(row_rect(0),DrawUtil.WHITE)
        label(Vector2(240,230),"BACK",2,DrawUtil.BG,HORIZONTAL_ALIGNMENT_CENTER)

func activate() -> void:
    if page == "credits":
        back()
        return
    if page == "extras":
        if selected == 0:
            page = "credits"
            selected = 0
        elif selected == 1: RunState.start_lab()
        else: back()
        return
    if page == "new_journey":
        if selected == 0:
            back()
            return
        var profile = preload("res://scripts/exploration_save.gd").new()
        profile.path = exploration_path
        var result: Dictionary = preload("res://scripts/save_recovery.gd").restart_readable(profile)
        recovery_message = result.message
        selected = 0
        if result.ok:
            recovery_archive = result.archive
            refresh_exploration()
            page = "recovery_done"
        return
    if page == "keyboard":
        if selected < 5: GameInput.keyboard.begin_capture(GameInput.keyboard.ACTIONS[selected])
        elif selected == 5: GameInput.keyboard.restore_defaults()
        else: back()
        return
    if page == "settings" and selected == 5:
        page = "keyboard"
        selected = 0
        return
    if page == "recovery_done":
        if selected == 0: back()
        elif not recovery_archive.is_empty():
            if OS.shell_open(ProjectSettings.globalize_path(recovery_archive)) != OK:
                recovery_message = "FOLDER COULD NOT OPEN . FILES STILL RETAINED"
        return
    if page in ["recovery","recovery_confirm"]:
        if selected == 0: back()
        elif page == "recovery":
            page = "recovery_confirm"
            selected = 0
        else:
            var profile = preload("res://scripts/exploration_save.gd").new()
            profile.path = exploration_path
            var result: Dictionary = preload("res://scripts/save_recovery.gd").restart_unreadable(profile)
            recovery_message = result.message
            if result.ok:
                recovery_archive = result.archive
                refresh_exploration()
                page = "recovery_done"
                selected = 0
            else: selected = 0
        return
    if page == "home":
        var action: String = home_items()[selected][2]
        match action:
            "restart_explore":
                return_selected = selected
                page = "new_journey"
                selected = 0
                recovery_message = ""
            "explore":
                if exploration_unreadable:
                    page = "recovery"
                    return_selected = selected
                    selected = 0
                    recovery_message = ""
                else: get_tree().change_scene_to_file("res://scenes/exploration.tscn")
            "continue": RunState.resume_run()
            "new": RunState.start_run()
            "lab": RunState.start_lab()
            "quit": get_tree().quit()
            "extras":
                return_selected = selected
                page = "extras"
                selected = 0
            "settings": open_settings()
            "controls":
                return_selected = selected
                page = "controls"
                selected = 0
    elif page == "controls" or selected == 6:
        back()
    elif selected == 2:
        AppSettings.toggle_fullscreen()
    elif selected == 3:
        AppSettings.toggle_flashes()
    elif selected == 4:
        AppSettings.toggle_shake()

func adjust(amount: float, persist := true) -> void:
    if selected < 2:
        var kind := "music" if selected == 0 else "effects"
        var value: float = AppSettings.music_volume if selected == 0 else AppSettings.sfx_volume
        AppSettings.set_volume(kind,value+amount,persist)
        if selected == 1 and persist: Sfx.beep(440,0.05)
    elif selected == 2:
        AppSettings.toggle_fullscreen()
    elif selected == 3:
        AppSettings.toggle_flashes()
    elif selected == 4:
        AppSettings.toggle_shake()

func slide(x: float) -> void:
    var volume := snappedf(clampf((x-230.0)/120.0,0.0,1.0),0.05)
    AppSettings.set_volume("music" if dragging == 0 else "effects",volume,false)

func handle_input(event: InputEvent) -> bool:
    if RunState.state != "menu" and page == "home": return false
    if page == "keyboard" and GameInput.keyboard.capture(event): return true
    event = GameInput.menu_event(event)
    if event is InputEventMouseMotion:
        var mouse: Vector2 = event.position
        if dragging >= 0: slide(mouse.x)
        else:
            var count := row_count()
            for i in count:
                if row_rect(i).has_point(mouse): selected = i
        return true
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if not event.pressed:
            if dragging >= 0:
                AppSettings.save_preferences()
                if dragging == 1: Sfx.beep(440,0.05)
                dragging = -1
            return true
        var mouse: Vector2 = event.position
        var count := row_count()
        for i in count:
            if row_rect(i).has_point(mouse):
                selected = i
                if page == "settings" and i < 2:
                    if mouse.x >= 225:
                        dragging = i
                        slide(mouse.x)
                else: activate()
                break
        return true
    if event is InputEventKey and event.pressed and not event.echo:
        var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
        if key == KEY_F11:
            AppSettings.toggle_fullscreen()
        elif key == KEY_ESCAPE:
            if page != "home": back()
        elif page == "home" and key == KEY_L:
            RunState.start_lab()
        elif page == "home" and key == KEY_C and get_parent().can_resume:
            RunState.resume_run()
        elif page == "home" and key == KEY_O:
            open_settings()
        elif key in [KEY_UP,KEY_DOWN,KEY_W,KEY_S]:
            var count := row_count()
            selected = posmod(selected + (-1 if key in [KEY_UP,KEY_W] else 1),count)
        elif page == "settings" and key in [KEY_LEFT,KEY_RIGHT,KEY_A,KEY_D]:
            adjust(-0.05 if key in [KEY_LEFT,KEY_A] else 0.05)
        elif key in [KEY_ENTER,KEY_SPACE]:
            activate()
        return true
    return true
