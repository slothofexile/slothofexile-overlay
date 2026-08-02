class_name AreaManager
extends Node

@export_group("Global Settings")
@export var window_pixel_offset: Vector2i = Vector2i.ZERO 

@export_group("Area Settings")
@export var camera: Camera3D
@export var directional_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var shadow_plane: GeometryInstance3D

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

	# automatically apply default preset on start
	if default_preset_name != "":
		apply_preset(default_preset_name)

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
		env.ambient_light_energy = data.ambient_energy

	# apply shadow opacity to the shader
	if shadow_plane and shadow_plane.material_override != null:
		var shader_mat = shadow_plane.material_override as ShaderMaterial
		if shader_mat:
			shader_mat.set_shader_parameter("shadow_opacity", data.shadow_opacity)
