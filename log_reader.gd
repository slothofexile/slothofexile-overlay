extends Node

# out of all the scripts, this one should have the most error handling built around it
# but really don't quite have the time yet to do that
# so all this is very liberal with assumptions for now

signal area_entered(area_name: String)

const INI_PATH: String = "user://overlay_settings.ini"
const DEFAULT_PATH_STANDALONE: String = "C:\\Program Files (x86)\\Grinding Gear Games\\Path of Exile\\logs\\Client.txt"
const DEFAULT_PATH_STEAM: String = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Path of Exile\\logs\\Client.txt"

var current_log_path: String = ""
var last_file_size: int = 0
var poll_timer: Timer
var zone_regex: RegEx

func _ready() -> void:
	_get_log_path()
	
	# setup regex to find "You have entered [Area Name]."
	zone_regex = RegEx.new()
	zone_regex.compile("You have entered (.+?)\\.")
	
	if current_log_path != "" and FileAccess.file_exists(current_log_path):
		var file = FileAccess.open(current_log_path, FileAccess.READ)
		if file:
			# get initial size and close immediately
			last_file_size = file.get_length()
			file.close()
			# ##### print("Log reader initialized. Tracking: ", current_log_path)
		
		# Godot doesn't have a native filewatcher so there's no choice but to set up polling on an arbitrary interval
		# on my own clients.txt, the fastest "[Loading Screen]... Duration" is around 1.1 seconds
		# if a lot of people end up complaining about it, I can expose the polling interval through the settings_manager later on
		poll_timer = Timer.new()
		poll_timer.wait_time = 1 
		poll_timer.autostart = true
		poll_timer.timeout.connect(_on_poll_timer_timeout)
		add_child(poll_timer)
	# ##### else:
		# ##### print("Client.txt not found at: ", current_log_path)

func _get_log_path() -> void:
	var config = ConfigFile.new()
	if config.load(INI_PATH) == OK:
		# ini exists, use the settings saved inside ini
		var saved_mode = config.get_value("Settings", "log_mode", 0)
		if saved_mode == 0:
			current_log_path = DEFAULT_PATH_STANDALONE
		elif saved_mode == 1:
			current_log_path = DEFAULT_PATH_STEAM
		else:
			current_log_path = config.get_value("Settings", "log_path_custom", "")
	else:
		# ini does not exist (like on 1st run or ini deleted), check default paths in order
		if FileAccess.file_exists(DEFAULT_PATH_STANDALONE):
			current_log_path = DEFAULT_PATH_STANDALONE
		elif FileAccess.file_exists(DEFAULT_PATH_STEAM):
			current_log_path = DEFAULT_PATH_STEAM
		else:
			current_log_path = "" # does nothing

func _on_poll_timer_timeout() -> void:
	if not FileAccess.file_exists(current_log_path):
		return
		
	# open as read-only for the duration of the file op
	var file = FileAccess.open(current_log_path, FileAccess.READ)
	if not file:
		return
		
	var current_size = file.get_length()
	
	if current_size > last_file_size:
		# file grew, seek to last known position and read the new chunk
		file.seek(last_file_size)
		
		# extract bytes and convert to string
		var new_data = file.get_buffer(current_size - last_file_size).get_string_from_utf8()
		last_file_size = current_size
		
		_parse_new_log_data(new_data)
		
	elif current_size < last_file_size:
		# if the user deleted or cleared the log file while running, reset the offset
		# case shouldn't happen often, but it can happen
		last_file_size = current_size
		
	# supposedly Windows is good with file read concurrency but better be safe by closing every time
	file.close()

func _parse_new_log_data(data: String) -> void:
	var lines = data.split("\n")
	
	# loop backwards through the chunk (from newest to oldest)
	# assuming that there can be more than one area entered in between polling intervals
	# we don't care about any other area except the one we're in NOW
	for i in range(lines.size() - 1, -1, -1):
		var result = zone_regex.search(lines[i])
		if result:
			# get_string(1) returns the area name
			var area_name = result.get_string(1)
			# ##### print("DEBUG AREA ENTERED: ", area_name)
			area_entered.emit(area_name)
			# ignore all older lines in this chunk
			break
