# this file is 100% AI boilerplate except for 3 lines

# I asked for a quick way to bind keystrokes to change lighting and shadow settings
# on the fly to help me eyeball values for the area presets

# functional, but AI put some wierd/unecessary/hallucinated logic though, like:

# setting up SHIFT keys to do the opposite of the base key
# (like SHIFT+UP does the opposite of UP)
# which is unnecessary because DOWN already does the exact same thing

# and the CTRL key modifier is also defined
# but then is never used/assigned to an action

# or that it outputs debug camera settings, but there's no logic to change camera settings
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
@export var target_preset_name: String = "Monastery of the Keepers"

@export_category("Tuning Step Amounts")
@export var angle_step_degrees: float = 5.0
@export var energy_step: float = 0.05
@export var opacity_step: float = 0.05


# added func to disable hotkeys for release versions
# supposedly, best practice is to manually unbind AreaManager before compiling release
# but this method seems to me as easier/cleaner/more dev friendly 
# at least while the project is in a stage where new presets are still actively being made
func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var key_event := event as InputEventKey
	var key := key_event.keycode
	var shift := key_event.shift_pressed
	@warning_ignore("unused_variable")
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
	print("[PresetTuner] Current values:")

	if camera:
		print("  ├─ Camera Pos: %s | Rot: %s" % [camera.position, camera.rotation_degrees])

	if directional_light:
		var lc := directional_light.light_color
		print("  ├─ Light Energy: %.2f | Color: #%s | A: %d | Rotation: %s" % [directional_light.light_energy, lc.to_html(false), roundi(lc.a * 255.0), directional_light.rotation_degrees])

	if world_environment and world_environment.environment:
		var env = world_environment.environment
		var ac: Color = env.ambient_light_color
		print("  ├─ Ambient Energy: %.2f | Color: #%s | Alpha: %d" % [env.ambient_light_energy, ac.to_html(false), roundi(ac.a * 255.0)])

	if shadow_plane and shadow_plane.material_override is ShaderMaterial:
		var mat = shadow_plane.material_override as ShaderMaterial
		var lin: Vector3 = mat.get_shader_parameter("shadow_color")
		var tint := Color(lin.x, lin.y, lin.z).linear_to_srgb()
		print("  └─ Shadow Opacity: %.2f | Tint: #%s | Alpha: %d" % [float(mat.get_shader_parameter("shadow_opacity")), tint.to_html(false), roundi(tint.a * 255.0)])
