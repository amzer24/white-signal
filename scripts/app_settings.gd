extends Node
## User preferences are separate from campaign progress.

var save_path := "user://ws_settings.cfg"
var music_volume := 0.65
var sfx_volume := 0.8
var fullscreen := false
var reduced_flashes := true
var camera_shake := true
var save_error := ""

func _ready() -> void:
    for bus in ["Music","SFX"]:
        if AudioServer.get_bus_index(bus) < 0:
            AudioServer.add_bus()
            AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
    if OS.has_environment("WS_SETTINGS_PATH"):
        save_path = OS.get_environment("WS_SETTINGS_PATH")
    fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    load_preferences()
    apply_audio()

func safe_volume(value: Variant, fallback: float) -> float:
    if not (value is float or value is int) or not is_finite(float(value)):
        return fallback
    return clampf(float(value),0.0,1.0)

func load_preferences() -> void:
    var config := ConfigFile.new()
    if config.load(save_path) != OK: return
    music_volume = safe_volume(config.get_value("audio","music",0.65),0.65)
    sfx_volume = safe_volume(config.get_value("audio","effects",0.8),0.8)
    var display: Variant = config.get_value("display","fullscreen",false)
    var flashes: Variant = config.get_value("display","reduced_flashes",true)
    reduced_flashes = flashes if flashes is bool else true
    var shake: Variant = config.get_value("display","camera_shake",true)
    camera_shake = shake if shake is bool else true
    if display is bool:
        fullscreen = display
        apply_display()

func apply_audio() -> void:
    for pair in [["Music",music_volume],["SFX",sfx_volume]]:
        var index := AudioServer.get_bus_index(pair[0])
        AudioServer.set_bus_mute(index,float(pair[1]) <= 0.0)
        AudioServer.set_bus_volume_db(index,linear_to_db(maxf(float(pair[1]),0.0001)))

func set_volume(kind: String, value: float, persist := true) -> void:
    if kind == "music": music_volume = clampf(value,0.0,1.0)
    elif kind == "effects": sfx_volume = clampf(value,0.0,1.0)
    apply_audio()
    if persist: save_preferences()

func toggle_fullscreen() -> void:
    fullscreen = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
    apply_display()
    save_preferences()

func toggle_flashes() -> void:
    reduced_flashes = not reduced_flashes
    save_preferences()

func toggle_shake() -> void:
    camera_shake = not camera_shake
    save_preferences()

func apply_display() -> void:
    if DisplayServer.get_name() == "headless": return
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
    if not fullscreen: DisplayServer.window_set_size(Vector2i(960,540))

func save_preferences() -> void:
    var config := ConfigFile.new()
    config.set_value("audio","music",music_volume)
    config.set_value("audio","effects",sfx_volume)
    config.set_value("display","fullscreen",fullscreen)
    config.set_value("display","reduced_flashes",reduced_flashes)
    config.set_value("display","camera_shake",camera_shake)
    var error := config.save(save_path)
    save_error = "COULD NOT SAVE SETTINGS" if error != OK else ""
    if error != OK: push_warning(save_error+": "+error_string(error))
