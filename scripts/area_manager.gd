# told AI to add debug output scaffolding all over
# why doesn't Godot have watch variables? ;(
# Remote view is not a direct substitute

class_name AreaManager
extends Node

signal preset_changed(preset_name: String)

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
# @export var presets: Array[AreaPreset] = []

# I just use this to more easily make area presets 
# (loading an area without needing to read log file)
# but this is almost immediately overwritten by the 1st town loading when in-game
## @export var default_preset_name: String = "Karui Shores"
@export var default_preset_name: String = "Karui Shores"


var preset_map: Dictionary = {}

func _ready() -> void:
	if window_pixel_offset != Vector2i.ZERO:
		DisplayServer.window_set_position(DisplayServer.window_get_position() + window_pixel_offset)
	
	
	# presets were originally programatically added but AI recommended otherwise
	# after adding presets to the array manually, I now realize that it's not practical with 150+ areas
	# so we're going back to the old way
	
	# ಠ_ಠ >>> └[•-•]┘
	
 
 
	var dir := DirAccess.open("res://data/presets/")
	if dir == null:
		# fail loudly instead of silently ending up with an empty preset_map
		push_error("[AreaManager] Cannot open res://data/presets/ (error %d)" % DirAccess.get_open_error())
	else:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			
			# turns out that in an exported build, the folder structure becomes <area>.tres.remap instead of <area>.tres
			# (and ".import" for some resource types), so the extension needs to be stripped to get the real path
			var clean_name := file_name.trim_suffix(".remap").trim_suffix(".import")
			if not dir.current_is_dir() and clean_name.get_extension() == "tres":
				var p := load("res://data/presets/" + clean_name) as AreaPreset
				if p and p.preset_name != "":
					preset_map[p.preset_name] = p
				else:
					push_warning("[AreaManager] Skipped '%s' (not an AreaPreset or has no preset_name)" % clean_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	print("[AreaManager] Loaded %d presets: %s" % [preset_map.size(), preset_map.keys()])

	log_reader.area_entered.connect(_on_area_entered)
	apply_preset(default_preset_name)


func _on_area_entered(raw_area_name: String) -> void:
	print("[AreaManager] Signal received for area: '%s'" % raw_area_name)
	apply_preset(raw_area_name)


func apply_preset(preset_name: String) -> void:
	print("[AreaManager] Attempting to apply preset: '%s'" % preset_name)

	if not preset_map.has(preset_name):
		push_warning("[AreaManager] Area preset '%s' not found! Registered keys: %s" % [preset_name, preset_map.keys()])
		
		# just so a missing preset doesn't crash the whole thing
		# setting the default as Karui Shores which I think 95% of player's starting town by endgame
		# though I do wish GGG could just set our HO as the starting town like players have been asking for
		preset_name = "Karui Shores"
		
		# if even the fallback is missing (e.g. presets failed to load in an export) there is nothing to apply
		if not preset_map.has(preset_name):
			push_error("[AreaManager] Fallback preset '%s' is missing too, nothing to apply" % preset_name)
			return
		
	var data: AreaPreset = preset_map[preset_name]
	
	print("[AreaManager] Applying '%s':" % preset_name)
	print("  ├─ Camera Pos: %s | Rot: %s" % [data.camera_position, data.camera_rotation_degrees])
	print("  ├─ Light Energy: %.2f | Color: #%s | A: %d | Rotation: %s" % [data.light_energy, data.light_color.to_html(false), roundi(data.light_color.a * 255.0), data.light_rotation_degrees])
	print("  ├─ Ambient Energy: %.2f | Color: #%s | Alpha: %d" % [data.ambient_energy, data.ambient_color.to_html(false), roundi(data.ambient_color.a * 255.0)])
	print("  └─ Shadow Opacity: %.2f | Tint: #%s | Alpha: %d" % [data.shadow_opacity, data.shadow_tint.to_html(false), roundi(data.shadow_tint.a * 255.0)])

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
		env.ambient_light_energy = data.ambient_energy
		

	# allows tinting of the shadow falling on the shadowcatcher plane, 
	# separate from light color or ambient color
	var mat = shadow_plane.material_override
	var linear_tint = data.shadow_tint.srgb_to_linear()
	var shadow_rgb = Vector3(linear_tint.r, linear_tint.g, linear_tint.b)

	mat.set_shader_parameter("shadow_color", shadow_rgb)
	mat.set_shader_parameter("shadow_opacity", data.shadow_opacity)

	preset_changed.emit(preset_name)

	if is_instance_valid(overlay_main) and overlay_main.has_method("_update_cached_offsets"):
		overlay_main._update_cached_offsets()
