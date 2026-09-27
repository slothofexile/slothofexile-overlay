# this file is 100% AI boilerplate

# I asked for a quick way to bind keystrokes to change lighting and shadow settings
# on the fly to help me eyeball values for the area presets

# functional, but AI put some wierd/unecessary/hallucinated logic though, like:

# setting up SHIFT keys to do the opposite of the base key
# (like SHIFT+UP does the opposite of UP)
# which is unnecessary because DOWN already does the exact same thing

# and the CTRL key modifier is also defined
# but then is never used/assigned to an action

# or that it outputs debug camera position, but there's no logic to change it
# (nor was any asked for)

# ಠ_ಠ >>> └[•-•]┘

class_name PresetTuner
extends Node

@export_category("Scene Target References")
@export var camera: Camera3D
@export var directional_light: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var shadow_plane: GeometryInstance3D
@export var area_manager: Node
@export var target_preset_name: String = "The Sovereign"

@export_category("Tuning Step Amounts")
@export var angle_step_degrees: float = 5.0
@export var energy_step: float = 0.05
@export var opacity_step: float = 0.05

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var key_event := event as InputEventKey
	var key := key_event.keycode
	var shift := key_event.shift_pressed
	var ctrl := key_event.ctrl_pressed

	var handled := false

	# ----------------------------------------------------
	# 1. LIGHT ROTATION (Arrow Keys / Q & E)
	# ----------------------------------------------------
	if directional_light:
		var rot = directional_light.rotation_degrees

		if key == KEY_UP:
			rot.x += angle_step_degrees * (-1.0 if shift else 1.0)
			handled = true
		elif key == KEY_DOWN:
			rot.x -= angle_step_degrees * (-1.0 if shift else 1.0)
			handled = true
		elif key == KEY_LEFT:
			rot.y += angle_step_degrees * (-1.0 if shift else 1.0)
			handled = true
		elif key == KEY_RIGHT:
			rot.y -= angle_step_degrees * (-1.0 if shift else 1.0)
			handled = true
		elif key == KEY_Q:
			rot.z += angle_step_degrees * (-1.0 if shift else 1.0)
			handled = true
		elif key == KEY_E:
			rot.z -= angle_step_degrees * (-1.0 if shift else 1.0)
			handled = true

		if handled:
			directional_light.rotation_degrees = rot
			print("[PresetTuner] Light Rotation: %s" % rot)

	# ----------------------------------------------------
	# 2. LIGHT & AMBIENT ENERGY (PageUp / PageDown, Home / End)
	# ----------------------------------------------------
	if key == KEY_PAGEUP and directional_light:
		directional_light.light_energy += energy_step
		print("[PresetTuner] Light Energy: %.2f" % directional_light.light_energy)
		handled = true
	elif key == KEY_PAGEDOWN and directional_light:
		directional_light.light_energy = maxf(0.0, directional_light.light_energy - energy_step)
		print("[PresetTuner] Light Energy: %.2f" % directional_light.light_energy)
		handled = true

	if key == KEY_HOME and world_environment and world_environment.environment:
		var env = world_environment.environment
		env.ambient_light_energy += energy_step
		print("[PresetTuner] Ambient Energy: %.2f" % env.ambient_light_energy)
		handled = true
	elif key == KEY_END and world_environment and world_environment.environment:
		var env = world_environment.environment
		env.ambient_light_energy = maxf(0.0, env.ambient_light_energy - energy_step)
		print("[PresetTuner] Ambient Energy: %.2f" % env.ambient_light_energy)
		handled = true

	# ----------------------------------------------------
	# 3. SHADOW OPACITY (Numpad + / Numpad -)
	# ----------------------------------------------------
	if shadow_plane and shadow_plane.material_override is ShaderMaterial:
		var mat = shadow_plane.material_override as ShaderMaterial
		var current_opacity: float = mat.get_shader_parameter("shadow_opacity")

		if key == KEY_KP_ADD or key == KEY_EQUAL:
			current_opacity = clampf(current_opacity + opacity_step, 0.0, 1.0)
			mat.set_shader_parameter("shadow_opacity", current_opacity)
			print("[PresetTuner] Shadow Opacity: %.2f" % current_opacity)
			handled = true
		elif key == KEY_KP_SUBTRACT or key == KEY_MINUS:
			current_opacity = clampf(current_opacity - opacity_step, 0.0, 1.0)
			mat.set_shader_parameter("shadow_opacity", current_opacity)
			print("[PresetTuner] Shadow Opacity: %.2f" % current_opacity)
			handled = true

	# ----------------------------------------------------
	# 4. REAPPLY TARGET PRESET (Key L / Key F5)
	# ----------------------------------------------------
	if key == KEY_L or key == KEY_F5:
		if area_manager and target_preset_name != "":
			if area_manager.has_method("apply_preset"):
				area_manager.apply_preset(target_preset_name)
				print("[PresetTuner] Reapplied preset: %s" % target_preset_name)
				handled = true
			elif area_manager.has_method("apply_area"):
				area_manager.apply_area(target_preset_name)
				print("[PresetTuner] Reapplied area: %s" % target_preset_name)
				handled = true

	# ----------------------------------------------------
	# 5. PRINT PRESET CONFIGURATION (Key P / Key Space)
	# ----------------------------------------------------
	if key == KEY_P or key == KEY_SPACE:
		_print_current_preset_values()
		handled = true

func _print_current_preset_values() -> void:
	print("\n==================================================")
	print("        PRESET TUNER OUTPUT (AreaPreset Data)      ")
	print("==================================================")

	if camera:
		print("camera_position = Vector3(%.2f, %.2f, %.2f)" % [camera.position.x, camera.position.y, camera.position.z])
		print("camera_rotation_degrees = Vector3(%.2f, %.2f, %.2f)" % [camera.rotation_degrees.x, camera.rotation_degrees.y, camera.rotation_degrees.z])

	if directional_light:
		print("light_rotation_degrees = Vector3(%.2f, %.2f, %.2f)" % [directional_light.rotation_degrees.x, directional_light.rotation_degrees.y, directional_light.rotation_degrees.z])
		print("light_energy = %.2f" % directional_light.light_energy)
		print("light_color = Color(%s)" % directional_light.light_color.to_html(false))

	if world_environment and world_environment.environment:
		var env = world_environment.environment
		print("ambient_energy = %.2f" % env.ambient_light_energy)
		print("ambient_color = Color(%s)" % env.ambient_light_color.to_html(false))

	if shadow_plane and shadow_plane.material_override is ShaderMaterial:
		var mat = shadow_plane.material_override as ShaderMaterial
		print("shadow_opacity = %.2f" % float(mat.get_shader_parameter("shadow_opacity")))

	print("==================================================\n")
