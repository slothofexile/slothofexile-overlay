extends Node

# for some reason this doesn't work and the field in the inspector goes missing: @export var overlay_main: Node3D
@onready var overlay_main: Node3D = get_parent()

var tray_menu: PopupMenu
var tray_icon: StatusIndicator
var settings_window: Window

var offset_x_spinbox: SpinBox
var offset_y_spinbox: SpinBox
var rotation_speed_spinbox: SpinBox
var max_fps_spinbox: SpinBox
var wave_motion_checkbox: CheckBox

const CONFIG_PATH: String = "user://overlay_settings.ini"

# screen x/y offsets
# shouldn't ever need to touch X offset unless/until shifting left/right is ever implemented which I probably never will
const DEFAULT_OFFSET_X: float = 0.0

# on my 1920x1080, -75 Y offset looks ok with a hiero char
# will probably need to change it to a function of screensize for other resolutions
const DEFAULT_OFFSET_Y: float = -75.0

# mouse tracking/rotation speed
# eyeballing -- 20 seems to work ok, 10 too slow for me
const DEFAULT_ROTATION_SPEED: float = 20.0

const DEFAULT_MAX_FPS: float = 60.0
const DEFAULT_WAVE_MOTION: bool = true

func _ready() -> void:
	_setup_tray()
	_setup_settings_window()
	_load_ini()

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
	settings_window = Window.new()
	settings_window.title = "Settings"
	settings_window.size = Vector2i(380, 320)
	settings_window.unresizable = true
	settings_window.borderless = true
	settings_window.transient = true
	settings_window.hide()
	settings_window.close_requested.connect(_on_cancel_pressed)
	
	# Create a theme to globally reduce font sizes for this window
	var small_theme = Theme.new()
	small_theme.set_default_font_size(13)
	settings_window.theme = small_theme
	
	# disable win_set_flag layered clickthrough when menu opens to accept inputs
	settings_window.about_to_popup.connect(func():
		if is_instance_valid(overlay_main) and overlay_main.has_method("set_click_through"):
			overlay_main.set_click_through(false)
	)
	
	# re-enable win_set_flag layered clickthrough on close
	settings_window.visibility_changed.connect(func():
		if not settings_window.visible:
			if is_instance_valid(overlay_main) and overlay_main.has_method("set_click_through"):
				overlay_main.set_click_through(true)
	)
	
	add_child(settings_window)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_window.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = "Overlay Settings"
	title_label.add_theme_font_size_override("font_size", 15) 
	vbox.add_child(title_label)
	
	# Display Offset Category Label
	var offset_header = Label.new()
	offset_header.text = "Display Offset (-512 to +512 px):"
	vbox.add_child(offset_header)
	
	# X pixels UI (-512 to 512)
	var hbox_x = HBoxContainer.new()
	var label_x = Label.new()
	label_x.text = "  X pixels:" # Slightly indented for visual hierarchy
	label_x.custom_minimum_size.x = 240 # Increased to push spinboxes to a uniform column
	offset_x_spinbox = SpinBox.new()
	offset_x_spinbox.min_value = -512
	offset_x_spinbox.max_value = 512
	offset_x_spinbox.value = DEFAULT_OFFSET_X
	offset_x_spinbox.custom_minimum_size.x = 80
	hbox_x.add_child(label_x)
	hbox_x.add_child(offset_x_spinbox)
	vbox.add_child(hbox_x)
	
	# Y pixels UI (-512 to 512)
	var hbox_y = HBoxContainer.new()
	var label_y = Label.new()
	label_y.text = "  Y pixels:"
	label_y.custom_minimum_size.x = 240
	offset_y_spinbox = SpinBox.new()
	offset_y_spinbox.min_value = -512
	offset_y_spinbox.max_value = 512
	offset_y_spinbox.value = DEFAULT_OFFSET_Y
	offset_y_spinbox.custom_minimum_size.x = 80
	hbox_y.add_child(label_y)
	hbox_y.add_child(offset_y_spinbox)
	vbox.add_child(hbox_y)
	
	# mouse tracking / rotation speed (10 to 60)
	var hbox_rot = HBoxContainer.new()
	var label_rot = Label.new()
	label_rot.text = "Rotation Speed (10 to 60). Default 20:"
	label_rot.custom_minimum_size.x = 240
	rotation_speed_spinbox = SpinBox.new()
	rotation_speed_spinbox.min_value = 10
	rotation_speed_spinbox.max_value = 60
	rotation_speed_spinbox.value = DEFAULT_ROTATION_SPEED
	rotation_speed_spinbox.custom_minimum_size.x = 80
	hbox_rot.add_child(label_rot)
	hbox_rot.add_child(rotation_speed_spinbox)
	vbox.add_child(hbox_rot)
	
	# max FPS
	# there's probably some desync issues lurking around when fps approaching/exceeding monitor refresh
	var hbox_fps = HBoxContainer.new()
	var label_fps = Label.new()
	label_fps.text = "Max FPS (10 to 60). Default 60:"
	label_fps.custom_minimum_size.x = 240
	max_fps_spinbox = SpinBox.new()
	max_fps_spinbox.min_value = 10
	max_fps_spinbox.max_value = 60
	max_fps_spinbox.value = DEFAULT_MAX_FPS
	max_fps_spinbox.custom_minimum_size.x = 80
	hbox_fps.add_child(label_fps)
	hbox_fps.add_child(max_fps_spinbox)
	vbox.add_child(hbox_fps)
	
	# wave motion
	wave_motion_checkbox = CheckBox.new()
	wave_motion_checkbox.text = "Wave Motion"
	wave_motion_checkbox.button_pressed = DEFAULT_WAVE_MOTION
	vbox.add_child(wave_motion_checkbox)
	
	# buttons UI
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 6)
	
	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_pressed)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_on_cancel_pressed)
	
	var reset_btn = Button.new()
	reset_btn.text = "Reset to Default"
	reset_btn.pressed.connect(_reset_defaults)
	
	btn_hbox.add_child(save_btn)
	btn_hbox.add_child(cancel_btn)
	btn_hbox.add_child(reset_btn)
	vbox.add_child(btn_hbox)
	
	# connect value changed signals for live previews
	offset_x_spinbox.value_changed.connect(_on_x_changed)
	offset_y_spinbox.value_changed.connect(_on_y_changed)
	rotation_speed_spinbox.value_changed.connect(_on_rotation_speed_changed)
	max_fps_spinbox.value_changed.connect(_on_max_fps_changed)
	wave_motion_checkbox.toggled.connect(_on_wave_motion_toggled)

func _on_tray_menu_pressed(id: int) -> void:
	if id == 0:
		settings_window.popup_centered()
	elif id == 1:
		get_tree().quit()

func _on_x_changed(val: float) -> void:
	if is_instance_valid(overlay_main) and "offset_x_pixels" in overlay_main:
		overlay_main.offset_x_pixels = val

func _on_y_changed(val: float) -> void:
	if is_instance_valid(overlay_main) and "offset_y_pixels" in overlay_main:
		overlay_main.offset_y_pixels = val

func _on_rotation_speed_changed(val: float) -> void:
	if is_instance_valid(overlay_main) and "rotation_speed" in overlay_main:
		overlay_main.rotation_speed = val

func _on_max_fps_changed(val: float) -> void:
	Engine.max_fps = int(val)

func _on_wave_motion_toggled(val: bool) -> void:
	if is_instance_valid(overlay_main) and "enable_wave_motion" in overlay_main:
		overlay_main.enable_wave_motion = val

func _on_save_pressed() -> void:
	_save_ini()
	settings_window.hide()

func _on_cancel_pressed() -> void:
	_load_ini()
	settings_window.hide()

func _set_signals_blocked(blocked: bool) -> void:
	offset_x_spinbox.set_block_signals(blocked)
	offset_y_spinbox.set_block_signals(blocked)
	rotation_speed_spinbox.set_block_signals(blocked)
	max_fps_spinbox.set_block_signals(blocked)
	wave_motion_checkbox.set_block_signals(blocked)

func _sync_all_to_overlay() -> void:
	if is_instance_valid(overlay_main):
		if "offset_x_pixels" in overlay_main:
			overlay_main.offset_x_pixels = offset_x_spinbox.value
		if "offset_y_pixels" in overlay_main:
			overlay_main.offset_y_pixels = offset_y_spinbox.value
		if "rotation_speed" in overlay_main:
			overlay_main.rotation_speed = rotation_speed_spinbox.value
		if "enable_wave_motion" in overlay_main:
			overlay_main.enable_wave_motion = wave_motion_checkbox.button_pressed
	
	Engine.max_fps = int(max_fps_spinbox.value)

func _load_ini() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		_set_signals_blocked(true)
		offset_x_spinbox.value = config.get_value("Offsets", "offset_x", DEFAULT_OFFSET_X)
		offset_y_spinbox.value = config.get_value("Offsets", "offset_y", DEFAULT_OFFSET_Y)
		rotation_speed_spinbox.value = config.get_value("Settings", "rotation_speed", DEFAULT_ROTATION_SPEED)
		max_fps_spinbox.value = config.get_value("Settings", "max_fps", DEFAULT_MAX_FPS)
		wave_motion_checkbox.button_pressed = config.get_value("Settings", "wave_motion", DEFAULT_WAVE_MOTION)
		_set_signals_blocked(false)
		
		_sync_all_to_overlay()
	else:
		_reset_defaults()

func _save_ini() -> void:
	var config = ConfigFile.new()
	config.set_value("Offsets", "offset_x", offset_x_spinbox.value)
	config.set_value("Offsets", "offset_y", offset_y_spinbox.value)
	config.set_value("Settings", "rotation_speed", rotation_speed_spinbox.value)
	config.set_value("Settings", "max_fps", max_fps_spinbox.value)
	config.set_value("Settings", "wave_motion", wave_motion_checkbox.button_pressed)
	config.save(CONFIG_PATH)

func _reset_defaults() -> void:
	_set_signals_blocked(true)
	offset_x_spinbox.value = DEFAULT_OFFSET_X
	offset_y_spinbox.value = DEFAULT_OFFSET_Y
	rotation_speed_spinbox.value = DEFAULT_ROTATION_SPEED
	max_fps_spinbox.value = DEFAULT_MAX_FPS
	wave_motion_checkbox.button_pressed = DEFAULT_WAVE_MOTION
	_set_signals_blocked(false)
	
	_sync_all_to_overlay()
