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

# drag/drop  .tres files into this array in the inspector
@export var presets: Array[AreaPreset] = []

# preset to apply automatically when the scene loads
@export var default_preset_name: String = "coastal_hideout"

var preset_map: Dictionary = {}

func _ready() -> void:
	# offset OS window 
	if window_pixel_offset != Vector2i.ZERO:
		var current_pos = DisplayServer.window_get_position()
		DisplayServer.window_set_position(current_pos + window_pixel_offset)

	# index presets by their filename (ex. "coastal_hideout.tres" -> "coastal_hideout")
	for p in presets:
		if p and p.resource_path:
			var preset_name = p.resource_path.get_file().get_basename()
			preset_map[preset_name] = p

	# connect log reader signal if assigned
	if is_instance_valid(log_reader) and log_reader.has_signal("area_entered"):
		log_reader.area_entered.connect(_on_area_entered)

	# automatically apply default preset on start
	if default_preset_name != "":
		apply_preset(default_preset_name)

func _on_area_entered(raw_area_name: String) -> void:
	# convert log string "Coastal Hideout" to preset key "coastal_hideout"
	var formatted_key = raw_area_name.to_lower().replace(" ", "_")
	apply_preset(formatted_key)

func apply_preset(preset_name: String) -> void:
	if not preset_map.has(preset_name):
		push_warning("Area preset '%s' not found!" % preset_name)
		return
		
	var data: AreaPreset = preset_map[preset_name]
	
	# apply camera
	if camera:
		camera.position = data.camera_position
		camera.rotation_degrees = data.camera_rotation_degrees
		camera.fov = data.camera_fov
		
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

	# apply shadow opacity to the shader
	if is_instance_valid(shadow_plane):
		var mesh_inst: MeshInstance3D = null

		if shadow_plane is MeshInstance3D:
			mesh_inst = shadow_plane as MeshInstance3D
		else:
			for child in shadow_plane.get_children():
				if child is MeshInstance3D:
					mesh_inst = child
					break

		if is_instance_valid(mesh_inst):
			var mat = mesh_inst.material_override
			if not mat:
				mat = mesh_inst.get_active_material(0)

			if mat is ShaderMaterial:
				var shadow_rgb = Vector3(
					data.shadow_tint.r,
					data.shadow_tint.g,
					data.shadow_tint.b
				)
				mat.set_shader_parameter("shadow_color", shadow_rgb)
				mat.set_shader_parameter("shadow_opacity", data.shadow_opacity)

	preset_changed.emit(preset_name)

	if is_instance_valid(overlay_main) and overlay_main.has_method("_update_cached_offsets"):
		overlay_main._update_cached_offsets()
