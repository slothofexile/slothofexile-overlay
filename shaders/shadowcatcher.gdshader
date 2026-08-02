shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, ambient_light_disabled;

uniform vec3 shadow_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.65;

void fragment() {
	// EMISSION ignores lighting entirely, forcing shadow tint to show
	// even when the directional light is blocked by the model
	EMISSION = shadow_color;
	ALPHA = 0.0;
}

void light() {
	// ATTENUATION is 1.0 in direct light, 0.0 in full shadow.
	float shadow_factor = 1.0 - ATTENUATION;
	
	// make the plane visible ONLY where the shadow falls.
	ALPHA = max(ALPHA, shadow_opacity * shadow_factor);
}