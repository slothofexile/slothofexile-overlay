# used AI to add mindless implementation of debug output messages

class_name AreaManager
extends Node

signal preset_changed(preset_name: String)

const PRESET_DIR_PATH: String = "res://data/presets/"

@export_group("Global Settings")
@export var window_pixel_offset: Vector2i = Vector2i.ZERO 

@export_group("Area Settings")
@export var overlay_main: Node3D
@export var camera: Camera3D
@export var directional_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var shadow_plane: GeometryInstance3D
@export var log_reader: Node

# drag/drop .tres files into this array in the inspector
@export var presets: Array[AreaPreset] = []

# preset to apply automatically when the scene loads
@export var default_preset_name: String = "The Sovereign"

var preset_map: Dictionary = {}

func _ready() -> void:
	# offset OS window 
	if window_pixel_offset != Vector2i.ZERO:
		var current_pos = DisplayServer.window_get_position()
		DisplayServer.window_set_position(current_pos + window_pixel_offset)

	_load_presets_from_dir()

	# index presets manually assigned in inspector
	for p in presets:
		if p and p.preset_name != "":
			preset_map[p.preset_name] = p

	print("[AreaManager] Final loaded preset keys in map (%d): %s" % [preset_map.size(), preset_map.keys()])

	# connect log reader signal if assigned
	if is_instance_valid(log_reader) and log_reader.has_signal("area_entered"):
		log_reader.area_entered.connect(_on_area_entered)

	# automatically apply default preset on start
	if default_preset_name != "":
		apply_preset(default_preset_name)

func _load_presets_from_dir() -> void:
	var dir = DirAccess.open(PRESET_DIR_PATH)
	if not dir:
		print("[AreaManager] ERROR: Could not open directory at path: ", PRESET_DIR_PATH)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			# handle .remap / .import files in editor or exported builds
			var clean_file_name = file_name.replace(".remap", "").replace(".import", "")
			if clean_file_name.ends_with(".tres"):
				var full_path = PRESET_DIR_PATH.path_join(clean_file_name)
				var resource = load(full_path)
				
				if resource is AreaPreset:
					if resource.preset_name != "":
						preset_map[resource.preset_name] = resource
						print("[AreaManager] Registered preset file: '%s' -> key: '%s'" % [file_name, resource.preset_name])
					else:
						print("[AreaManager] WARN: Resource at '%s' loaded, but its 'preset_name' property is empty!" % full_path)
				else:
					var res_type = resource.get_class() if resource else "null"
					print("[AreaManager] WARN: Resource at '%s' is not an AreaPreset (Type: %s)" % [full_path, res_type])

		file_name = dir.get_next()

	dir.list_dir_end()

func _on_area_entered(raw_area_name: String) -> void:
	print("[AreaManager] Signal received for area: '%s'" % raw_area_name)
	apply_preset(raw_area_name)

func apply_preset(preset_name: String) -> void:
	print("[AreaManager] Attempting to apply preset: '%s'" % preset_name)

	if not preset_map.has(preset_name):
		push_warning("[AreaManager] Area preset '%s' not found! Registered keys: %s" % [preset_name, preset_map.keys()])
		return
		
	var data: AreaPreset = preset_map[preset_name]
	
	print("[AreaManager] Applying '%s':" % preset_name)
	print("  ├─ Camera Pos: %s | Rot: %s" % [data.camera_position, data.camera_rotation_degrees])
	print("  ├─ Light Energy: %.2f | Color: %s | Rot: %s" % [data.light_energy, data.light_color, data.light_rotation_degrees])
	print("  ├─ Ambient Energy: %.2f | Color: %s" % [data.ambient_energy, data.ambient_color])
	print("  └─ Shadow Opacity: %.2f | Tint: %s" % [data.shadow_opacity, data.shadow_tint])

	# apply camera position/rotation
	if camera:
		camera.position = data.camera_position
		camera.rotation_degrees = data.camera_rotation_degrees
		
	# apply lighting
	if directional_light:
		directional_light.rotation_degrees = data.light_rotation_degrees
		directional_light.light_color = data.light_color
		directional_light.light_energy = data.light_energy
		directional_light.shadow_enabled = data.shadow_enabled
		directional_light.shadow_blur = data.shadow_blur
		
	# apply env
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = data.ambient_color
		
		var effective_ambient_energy = (
			data.ambient_energy * (1.0 - data.shadow_opacity)
		)
		env.ambient_light_energy = maxf(0.0, effective_ambient_energy)

	# direct material override update
	if shadow_plane:
		var mat = shadow_plane.material_override
		if mat is ShaderMaterial:
			var shadow_rgb = Vector3(data.shadow_tint.r, data.shadow_tint.g, data.shadow_tint.b)
			mat.set_shader_parameter("shadow_color", shadow_rgb)
			mat.set_shader_parameter("shadow_opacity", data.shadow_opacity)

	preset_changed.emit(preset_name)

	if is_instance_valid(overlay_main) and overlay_main.has_method("_update_cached_offsets"):
		overlay_main._update_cached_offsets()
