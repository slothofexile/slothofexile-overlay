extends Window

# signals emitted when the user clicks Save, Cancel, etc...
signal save_requested(new_settings, log_changed)
signal preview_changed(key, value)
signal reset_requested()
signal cancel_requested()

@onready var offset_x_spinbox: SpinBox = $MarginContainer/VBoxContainer/HBoxX/OffsetXSpinBox
@onready var offset_y_spinbox: SpinBox = $MarginContainer/VBoxContainer/HBoxY/OffsetYSpinBox
@onready var rotation_speed_spinbox: SpinBox = $MarginContainer/VBoxContainer/HBoxRotation/RotationSpeedSpinBox
@onready var max_fps_spinbox: SpinBox = $MarginContainer/VBoxContainer/HBoxFPS/MaxFPSSpinBox
@onready var wave_motion_checkbox: CheckBox = $MarginContainer/VBoxContainer/WaveMotionCheckBox
@onready var camera_zoom_spinbox: SpinBox = $MarginContainer/VBoxContainer/HBoxCameraZoom/CameraZoomSpinBox
@onready var log_mode_option: OptionButton = $MarginContainer/VBoxContainer/HBoxLogMode/LogModeOption
@onready var log_path_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxLogPath/LogPathEdit

@onready var save_btn: Button = $MarginContainer/VBoxContainer/HBoxButtons/SaveButton
@onready var cancel_btn: Button = $MarginContainer/VBoxContainer/HBoxButtons/CancelButton
@onready var reset_btn: Button = $MarginContainer/VBoxContainer/HBoxButtons/ResetButton

var loaded_log_mode: int = 0
var loaded_log_path: String = ""

const DEFAULT_LOG_PATH_STANDALONE: String = "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt"
const DEFAULT_LOG_PATH_STEAM: String = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt"

func _ready() -> void:
	# set small font theme globally for window
	# could be something programmatically adjusted later on, but not now
	var small_theme = Theme.new()
	small_theme.set_default_font_size(13)
	theme = small_theme

	close_requested.connect(_on_cancel_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	
	log_mode_option.item_selected.connect(_on_log_mode_selected)
	log_path_edit.text_changed.connect(func(t): log_path_edit.tooltip_text = t)

	# connections for dynamic updates
	offset_x_spinbox.value_changed.connect(func(v): preview_changed.emit("offset_x", v))
	offset_y_spinbox.value_changed.connect(func(v): preview_changed.emit("offset_y", v))
	rotation_speed_spinbox.value_changed.connect(func(v): preview_changed.emit("rotation_speed", v))
	max_fps_spinbox.value_changed.connect(func(v): preview_changed.emit("max_fps", v))
	wave_motion_checkbox.toggled.connect(func(v): preview_changed.emit("wave_motion", v))
	camera_zoom_spinbox.value_changed.connect(func(v): preview_changed.emit("camera_zoom", v))

func populate_ui(data: Dictionary) -> void:
	_set_signals_blocked(true)
	offset_x_spinbox.value = data.get("offset_x", 0.0)
	offset_y_spinbox.value = data.get("offset_y", -75.0)
	rotation_speed_spinbox.value = data.get("rotation_speed", 20.0)
	max_fps_spinbox.value = data.get("max_fps", 60.0)
	wave_motion_checkbox.button_pressed = data.get("wave_motion", true)
	camera_zoom_spinbox.value = data.get("camera_zoom", 90.0)
	
	loaded_log_mode = data.get("log_mode", 0)
	loaded_log_path = data.get("log_path", DEFAULT_LOG_PATH_STANDALONE)
	
	log_mode_option.selected = loaded_log_mode
	log_path_edit.text = loaded_log_path
	log_path_edit.editable = (loaded_log_mode == 2)
	log_path_edit.tooltip_text = log_path_edit.text
	_set_signals_blocked(false)

func _on_log_mode_selected(index: int) -> void:
	if index == 0:
		log_path_edit.text = DEFAULT_LOG_PATH_STANDALONE
		log_path_edit.editable = false
	elif index == 1:
		log_path_edit.text = DEFAULT_LOG_PATH_STEAM
		log_path_edit.editable = false
	elif index == 2:
		log_path_edit.editable = true
	log_path_edit.tooltip_text = log_path_edit.text

func _on_save_pressed() -> void:
	var log_changed = (log_mode_option.selected != loaded_log_mode or log_path_edit.text != loaded_log_path)
	var new_settings = {
		"offset_x": offset_x_spinbox.value,
		"offset_y": offset_y_spinbox.value,
		"rotation_speed": rotation_speed_spinbox.value,
		"max_fps": max_fps_spinbox.value,
		"wave_motion": wave_motion_checkbox.button_pressed,
		"camera_zoom": camera_zoom_spinbox.value,
		"log_mode": log_mode_option.selected,
		"log_path": log_path_edit.text
	}
	save_requested.emit(new_settings, log_changed)
	hide()

func _on_cancel_pressed() -> void:
	cancel_requested.emit()
	hide()

func _on_reset_pressed() -> void:
	reset_requested.emit()

func _set_signals_blocked(blocked: bool) -> void:
	offset_x_spinbox.set_block_signals(blocked)
	offset_y_spinbox.set_block_signals(blocked)
	rotation_speed_spinbox.set_block_signals(blocked)
	max_fps_spinbox.set_block_signals(blocked)
	wave_motion_checkbox.set_block_signals(blocked)
	camera_zoom_spinbox.set_block_signals(blocked)
	log_mode_option.set_block_signals(blocked)
