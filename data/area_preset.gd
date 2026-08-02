class_name AreaPreset
extends Resource

@export_group("Camera")
@export var camera_position: Vector3 = Vector3(0.0, 7.0, 5.5)
@export var camera_rotation_degrees: Vector3 = Vector3(-52.0, 0.0, 0.0)
@export var camera_fov: float = 40.0

@export_group("Lighting")
@export var light_rotation_degrees: Vector3 = Vector3(-32.0, -135.0, 0.0)
@export var light_color: Color = Color("fff1d0")
@export var light_energy: float = 1.6
@export var shadow_enabled: bool = true
@export var shadow_blur: float = 0.5

@export_group("Environment")
@export var ambient_color: Color = Color("333a42")
@export var ambient_energy: float = 0.4

@export_group("Shadow Settings")
@export_range(0.0, 1.0) var shadow_opacity: float = 0.55
@export var shadow_tint: Color = Color("1a2026")
