extends Node3D

# these @exports pre-date the ini, so many of them aren't needed but still keeping them anyway

@export_category("Scene References")
@export var camera: Camera3D
@export var directional_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var target_model: Node3D
@export var rod_model: Node3D
@export var ground_plane: Node3D


@export_category("Position Offsets")

# positive = right, negative = left
@export var offset_x_pixels: float = 0.0:
	set(value):
		offset_x_pixels = value
		_update_cached_offsets()

# positive = down, negative = up
@export var offset_y_pixels: float = 0.0:
	set(value):
		offset_y_pixels = value
		_update_cached_offsets()


@export_category("Mouse Tracking")

# mouse tracking / rotation speed
# eyeballing -- 20 seems to work ok, 10 too slow for me
@export var rotation_speed: float = 60.0
@export_range(-180.0, 180.0) var angle_offset_degrees: float = 0.0


@export_category("Animations & Physics")

# wave motion and sway
# I don't want to expose this in the settings to prevent shenanigans
# extreme values do look funny though
@export var enable_wave_motion: bool = true
@export var wave_speed: float = 2.5
@export var wave_height: float = 0.04
@export var wave_rocking: float = 3.0

# area presets
@export_category("Presets")

@export var active_preset: AreaPreset:
	set(value):
		if active_preset and active_preset.changed.is_connected(_on_preset_changed):
			active_preset.changed.disconnect(_on_preset_changed)

		active_preset = value

		if active_preset:
			if not active_preset.changed.is_connected(_on_preset_changed):
				active_preset.changed.connect(_on_preset_changed)

		if is_node_ready() and active_preset:
			_apply_preset(active_preset)

var time_passed: float = 0.0
var base_position: Vector3 = Vector3.ZERO
var is_setup: bool = false

var cached_meters_per_pixel: float = 0.0
var world_pixel_offset: Vector3 = Vector3.ZERO

var last_mouse_pos: Vector2i = Vector2i.ZERO
var target_yaw: float = 0.0

var is_app_minimized: bool = false

func _ready() -> void:
	# DWM stutter (desync?) if PoE and overlay both at vsync for some reason,
	# cap at 60 FPS fixes it(?)
	# tbh, I can't really tell with my bad/old monitors if it's OOS or just bad pixel afterimage or ghosting
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60

	var win = get_window()

	win.transparent = true
	win.always_on_top = true
	get_viewport().transparent_bg = true

	# resize viewport will recalc x & y offsets
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	# Windows window flags using our WinSetFlags GDExtension. 
	# Godot can't natively set this unlike with the first version/s I wrote in AutoIT
	if Engine.has_singleton("WinSetFlags"):
		var window_id := get_window().get_window_id()

		WinSetFlags.win_set_flag(
			window_id,
			WinSetFlags.WS_EX_LAYERED,
			true
		)

		WinSetFlags.win_set_flag(
			window_id,
			WinSetFlags.WS_EX_TRANSPARENT,
			true
		)

	# apply starting preset if assigned in inspector
	# should probably always be karui shores
	# not advisable to do campaign with this overlay anyway,
	# as I don't plan on making presets for campaign areas
	if active_preset:
		if not active_preset.changed.is_connected(_on_preset_changed):
			active_preset.changed.connect(_on_preset_changed)

		_apply_preset(active_preset)

# pause processing gracefully if minimized with Win+D
# Win+D makes it behave oddly sometimes
func _notification(notification_code: int) -> void:
	if notification_code == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		is_app_minimized = false

	elif notification_code == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
			is_app_minimized = true

func _on_preset_changed() -> void:
	if active_preset:
		_apply_preset(active_preset)

func _on_viewport_size_changed() -> void:
	_update_cached_offsets()

func _update_cached_offsets() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(target_model):
		return

	var screen_size = get_viewport().get_visible_rect().size

	if screen_size.y > 0.0 and (offset_x_pixels != 0.0 or offset_y_pixels != 0.0):
		var target_pos = base_position if is_setup else target_model.position
		var dist_to_camera = camera.global_position.distance_to(target_pos)
		var visible_height_at_depth = 2.0 * dist_to_camera * tan(deg_to_rad(camera.fov) * 0.5)

		cached_meters_per_pixel = visible_height_at_depth / screen_size.y

		var cam_right = camera.global_transform.basis.x
		var cam_up = camera.global_transform.basis.y

		# negative offset_y_pixels so positive inspector values push down in screen space
		world_pixel_offset = (
			cam_right * (offset_x_pixels * cached_meters_per_pixel)
		) + (
			cam_up * (-offset_y_pixels * cached_meters_per_pixel)
		)
	else:
		world_pixel_offset = Vector3.ZERO

func _apply_preset(preset: AreaPreset) -> void:
	if not preset:
		return

	# camera settings
	if camera:
		camera.position = preset.camera_position
		camera.rotation_degrees = preset.camera_rotation_degrees
		camera.fov = preset.camera_fov

	# directional light settings
	if directional_light:
		directional_light.rotation_degrees = preset.light_rotation_degrees
		directional_light.light_color = preset.light_color
		directional_light.light_energy = preset.light_energy
		directional_light.shadow_enabled = preset.shadow_enabled
		directional_light.shadow_blur = preset.shadow_blur

	# model ambient lighting
	if world_environment and world_environment.environment:
		var env = world_environment.environment

		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = preset.ambient_color

		var effective_ambient_energy = (
			preset.ambient_energy * (1.0 - preset.shadow_opacity)
		)

		env.ambient_light_energy = maxf(0.0, effective_ambient_energy)

	# ground plane shadow tinting & opacity
	var target_node: Node3D = ground_plane

	if not is_instance_valid(target_node):
		target_node = find_child("Plane", true, false) as Node3D

	if is_instance_valid(target_node):
		var mesh_inst: MeshInstance3D = null

		if target_node is MeshInstance3D:
			mesh_inst = target_node as MeshInstance3D
		else:
			for child in target_node.get_children():
				if child is MeshInstance3D:
					mesh_inst = child
					break

		if is_instance_valid(mesh_inst):
			var mat = mesh_inst.material_override

			if not mat:
				mat = mesh_inst.get_active_material(0)

			if mat is ShaderMaterial:
				var shadow_rgb = Vector3(
					preset.shadow_tint.r,
					preset.shadow_tint.g,
					preset.shadow_tint.b
				)

				mat.set_shader_parameter("shadow_color", shadow_rgb)
				mat.set_shader_parameter("shadow_opacity", preset.shadow_opacity)

	# recalc pixel offset math since camera fov or distance might have changed
	_update_cached_offsets()

func _process(delta: float) -> void:
	# skip all processing if window is minimized
	if is_app_minimized:
		return

	if not target_model:
		if get_child_count() > 3:
			target_model = get_child(3) as Node3D
		else:
			return

	if not camera:
		camera = get_viewport().get_camera_3d()

		if not camera:
			return

	if not is_setup:
		base_position = target_model.position
		target_yaw = target_model.rotation.y
		is_setup = true
		_update_cached_offsets()

	time_passed += delta

	# run heavy raycast math only if the mouse moved from last pos
	var global_mouse = DisplayServer.mouse_get_position()

	if global_mouse != last_mouse_pos:
		last_mouse_pos = global_mouse

		var window_pos = get_window().position
		var mouse_pos = Vector2(global_mouse - window_pos)

		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)

		if abs(ray_dir.y) > 0.01:
			var pivot_pos = base_position + world_pixel_offset
			var plane_y = pivot_pos.y
			var distance = (plane_y - ray_origin.y) / ray_dir.y

			if distance > 0:
				var hit_point = ray_origin + ray_dir * distance
				var dir = hit_point - pivot_pos
				dir.y = 0

				# same as used in the old au3
				if dir.length_squared() > 0.001:
					var calc_yaw = atan2(dir.x, dir.z) + deg_to_rad(angle_offset_degrees)

					if not is_nan(calc_yaw):
						target_yaw = calc_yaw

	target_model.rotation.y = lerp_angle(
		target_model.rotation.y,
		target_yaw,
		delta * rotation_speed
	)

	# lightweight wave motion phase (single trig evaluation drives heave, pitch, and roll)
	var wave_y: float = 0.0
	var wave_pitch: float = 0.0
	var wave_roll: float = 0.0

	if enable_wave_motion:
		var wave_phase: float = sin(time_passed * wave_speed)
		wave_y = wave_phase * wave_height
		wave_pitch = wave_phase * deg_to_rad(wave_rocking)
		wave_roll = wave_phase * deg_to_rad(wave_rocking * 0.5)

	target_model.position = (
		base_position
		+ world_pixel_offset
		+ Vector3(0, wave_y, 0)
	)

	target_model.rotation.x = wave_pitch
	target_model.rotation.z = wave_roll


func set_click_through(enabled: bool) -> void:
	# the tray_manager has to toggle this whenever the settings window is open to allow interaction with it
	var window_id := get_window().get_window_id()
	if enabled:
		WinSetFlags.win_set_flag(
			window_id,
			WinSetFlags.WS_EX_LAYERED,
			true
		)
	else:
		WinSetFlags.win_set_flag(
			window_id,
			WinSetFlags.WS_EX_LAYERED,
			false
		)
