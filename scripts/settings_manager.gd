extends Node

# signal emitted when settings are saved or loaded to update overlay properties
signal settings_changed

# for some reason this doesn't work and the field in the inspector goes missing: @export var overlay_main: Node3D
@onready var overlay_main: Node3D = get_parent()

var tray_menu: PopupMenu
var tray_icon: StatusIndicator

# reference to the instantiated SettingsWindow scene
const SETTINGS_WINDOW_SCENE = preload("res://scenes/settingswindow.tscn")
var settings_window: Window

# baseline state tracking strictly for the only setting/s that require a full restart
# (log file path)
var loaded_log_mode: int = 0
var loaded_log_path: String = ""

# would really like to have persistent settings (locally) AND just a standalone exe but having both # aren't possible
# this is the least obtrusive way to get persistent settings saved locally
const CONFIG_PATH: String = "user://overlay_settings.ini"

# screen x/y offsets
# shouldn't ever need to touch X offset unless/until shifting left/right is ever implemented which I probably never will
const DEFAULT_OFFSET_X: float = 0.0

# on my 1920x1080, -75 Y offset looks ok with a hiero char
# will probably need to change it to a function of screensize for other resolutions
# and/or for smaller chars like... the ranger? IDK, I don't play rangers.
const DEFAULT_OFFSET_Y: float = -75.0

# mouse tracking/rotation speed
# eyeballing -- 20 seems to work ok, 10 too slow for me
const DEFAULT_ROTATION_SPEED: float = 20.0

const DEFAULT_MAX_FPS: float = 60.0
const DEFAULT_WAVE_MOTION: bool = true

# 90 looks ok on my 1920 x 1080 reso on top of a hiero
# higher or lower resolutions (or diff size chars) might need adjustment
const DEFAULT_CAMERA_ZOOM: float = 90.0

# Client.txt defined paths
const DEFAULT_LOG_PATH_STANDALONE: String = "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt"
const DEFAULT_LOG_PATH_STEAM: String = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt"
const DEFAULT_LOG_MODE: int = 0

# runtime settings variables cached in memory
var offset_x: float = DEFAULT_OFFSET_X
var offset_y: float = DEFAULT_OFFSET_Y
var rotation_speed: float = DEFAULT_ROTATION_SPEED
var max_fps: float = DEFAULT_MAX_FPS
var wave_motion: bool = DEFAULT_WAVE_MOTION
var camera_zoom: float = DEFAULT_CAMERA_ZOOM
var log_mode: int = DEFAULT_LOG_MODE
var log_path_custom: String = ""

func _ready() -> void:
	_setup_tray()
	_setup_settings_window()
	load_ini()

func _setup_tray() -> void:
	tray_menu = PopupMenu.new()
	tray_menu.name = "PopupMenu"
	tray_menu.add_item("Settings", 0)
	tray_menu.add_separator()
	tray_menu.add_item("Exit", 1)
	tray_menu.id_pressed.connect(_on_tray_menu_pressed)
	add_child(tray_menu)
	
	tray_icon = StatusIndicator.new()
	tray_icon.name = "StatusIndicator"
	tray_icon.tooltip = "Overlay Settings"
	tray_icon.icon = preload("res://icon.svg") 
	add_child(tray_icon)
	
	_assign_tray_menu.call_deferred()

func _assign_tray_menu() -> void:
	if is_instance_valid(tray_icon) and is_instance_valid(tray_menu):
		tray_icon.menu = tray_menu.get_path()

func _setup_settings_window() -> void:
	settings_window = SETTINGS_WINDOW_SCENE.instantiate()
	
	# disable window click-through while editing settings
	settings_window.about_to_popup.connect(func():
		if is_instance_valid(overlay_main) and overlay_main.has_method("set_click_through"):
			overlay_main.set_click_through(false)
	)
	
	# re-enable window click-through when closing settings
	settings_window.visibility_changed.connect(func():
		if not settings_window.visible:
			if is_instance_valid(overlay_main) and overlay_main.has_method("set_click_through"):
				overlay_main.set_click_through(true)
	)

	connect_settings_window(settings_window)
	add_child(settings_window)

func _on_tray_menu_pressed(id: int) -> void:
	if id == 0:
		if is_instance_valid(settings_window):
			var data = {
				"offset_x": offset_x,
				"offset_y": offset_y,
				"rotation_speed": rotation_speed,
				"max_fps": max_fps,
				"wave_motion": wave_motion,
				"camera_zoom": camera_zoom,
				"log_mode": log_mode,
				"log_path": get_current_log_path()
			}
			settings_window.populate_ui(data)
			settings_window.popup_centered()
	elif id == 1:
		get_tree().quit()

func get_current_log_path() -> String:
	match log_mode:
		0:
			return DEFAULT_LOG_PATH_STANDALONE
		1:
			return DEFAULT_LOG_PATH_STEAM
		2:
			return log_path_custom
		_:
			return DEFAULT_LOG_PATH_STANDALONE

func load_ini() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		offset_x = config.get_value("Offsets", "offset_x", DEFAULT_OFFSET_X)
		offset_y = config.get_value("Offsets", "offset_y", DEFAULT_OFFSET_Y)
		rotation_speed = config.get_value("Settings", "rotation_speed", DEFAULT_ROTATION_SPEED)
		max_fps = config.get_value("Settings", "max_fps", DEFAULT_MAX_FPS)
		wave_motion = config.get_value("Settings", "wave_motion", DEFAULT_WAVE_MOTION)
		camera_zoom = config.get_value("Settings", "camera_zoom", DEFAULT_CAMERA_ZOOM)
		log_mode = config.get_value("Settings", "log_mode", DEFAULT_LOG_MODE)
		log_path_custom = config.get_value("Settings", "log_path_custom", "")
		
		
	# validate settings if reading from file
	# to prevent insertion of values outside types and min/max already set in settings window
	# simplest way to handle anything outside is to just trigger reset to default
	if (
			_is_setting_valid(offset_x, -128.0, 128.0) and
			_is_setting_valid(offset_y, -128.0, 128.0) and
			_is_setting_valid(rotation_speed, 10.0, 60.0) and
			_is_setting_valid(max_fps, 10.0, 60.0) and
			_is_setting_valid(camera_zoom, 10.0, 180.0) and
			typeof(wave_motion) == TYPE_BOOL and
			typeof(log_mode) == TYPE_INT and log_mode in [0, 1, 2] and
			typeof(log_path_custom) == TYPE_STRING
		):
		
		_update_loaded_state()
		_apply_engine_settings()
		settings_changed.emit()
	else:
		reset_to_defaults()
		save_ini()

func _is_setting_valid(val: Variant, min_val: float, max_val: float) -> bool:
	return (val is float or val is int) and val >= min_val and val <= max_val

func save_ini() -> void:
	var config = ConfigFile.new()
	config.set_value("Offsets", "offset_x", offset_x)
	config.set_value("Offsets", "offset_y", offset_y)
	config.set_value("Settings", "rotation_speed", rotation_speed)
	config.set_value("Settings", "max_fps", max_fps)
	config.set_value("Settings", "wave_motion", wave_motion)
	config.set_value("Settings", "camera_zoom", camera_zoom)
	config.set_value("Settings", "log_mode", log_mode)
	if log_mode == 2:
		config.set_value("Settings", "log_path_custom", log_path_custom)
		
	config.save(CONFIG_PATH)
	
	# only restart if the log path actually changed, as all other variables can be dynamically set/reset
	# easier to just restart than to build logic to handle log path changes dynamically
	# especially since the path isn't a setting that should change frequently
	var log_path_changed = (
		log_mode != loaded_log_mode or
		get_current_log_path() != loaded_log_path
	)
	
	_update_loaded_state()
	_apply_engine_settings()
	settings_changed.emit()

	if log_path_changed:
		#### print("Log path changed. Restarting overlay...")
		OS.create_process(OS.get_executable_path(), OS.get_cmdline_args())
		get_tree().quit()

func reset_to_defaults() -> void:
	offset_x = DEFAULT_OFFSET_X
	offset_y = DEFAULT_OFFSET_Y
	rotation_speed = DEFAULT_ROTATION_SPEED
	max_fps = DEFAULT_MAX_FPS
	wave_motion = DEFAULT_WAVE_MOTION
	camera_zoom = DEFAULT_CAMERA_ZOOM
	log_mode = DEFAULT_LOG_MODE
	log_path_custom = ""
	
	_apply_engine_settings()
	settings_changed.emit()

func _apply_engine_settings() -> void:
	Engine.max_fps = int(max_fps)

func _update_loaded_state() -> void:
	loaded_log_mode = log_mode
	loaded_log_path = get_current_log_path()

func connect_settings_window(window: Window) -> void:
	if not is_instance_valid(window):
		return
		
	window.save_requested.connect(_on_window_save_requested)
	window.preview_changed.connect(_on_window_preview_changed)
	window.reset_requested.connect(func(): _on_window_reset_requested(window))
	# reload from INI to undo real-time preview changes
	window.cancel_requested.connect(load_ini) 

func _on_window_save_requested(new_settings: Dictionary, _log_changed: bool) -> void:
	offset_x = new_settings.get("offset_x", DEFAULT_OFFSET_X)
	offset_y = new_settings.get("offset_y", DEFAULT_OFFSET_Y)
	rotation_speed = new_settings.get("rotation_speed", DEFAULT_ROTATION_SPEED)
	max_fps = new_settings.get("max_fps", DEFAULT_MAX_FPS)
	wave_motion = new_settings.get("wave_motion", DEFAULT_WAVE_MOTION)
	camera_zoom = new_settings.get("camera_zoom", DEFAULT_CAMERA_ZOOM)
	log_mode = new_settings.get("log_mode", DEFAULT_LOG_MODE)
	
	if log_mode == 2:
		log_path_custom = new_settings.get("log_path", "")
		
	save_ini()

func _on_window_preview_changed(key: String, value: Variant) -> void:
	match key:
		"offset_x": offset_x = value
		"offset_y": offset_y = value
		"rotation_speed": rotation_speed = value
		"max_fps": 
			max_fps = value
			_apply_engine_settings()
		"wave_motion": wave_motion = value
		"camera_zoom": camera_zoom = value
	settings_changed.emit()

func _on_window_reset_requested(window: Window) -> void:
	reset_to_defaults()
	if is_instance_valid(window):
		var data = {
			"offset_x": offset_x,
			"offset_y": offset_y,
			"rotation_speed": rotation_speed,
			"max_fps": max_fps,
			"wave_motion": wave_motion,
			"camera_zoom": camera_zoom,
			"log_mode": log_mode,
			"log_path": get_current_log_path()
		}
		window.populate_ui(data)
