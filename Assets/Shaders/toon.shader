shader_type spatial;

render_mode ambient_light_disabled;

uniform vec4 albedo : hint_color = vec4(1.0f);
uniform vec4 shadow_color: hint_color = vec4(0.0);
uniform bool clamp_diffuse_to_max = false;

uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0f, 2.0f) = 0.0f;
uniform float steepness : hint_range(1.0f, 8.0f) = 1.0f;

uniform bool use_attenuation = false;

uniform bool use_ramp = false;
uniform sampler2D ramp : hint_albedo;

float staircase(int n, float x) {
	float res = 0.0f;
	float inc = 1.0f / float(n+1);
	for (float edge = 0.0f; edge < 1.0f - inc; edge+=inc) {
		res += step(edge, x);
	}
	return res / float(n);
}

float split_diffuse(float diffuse) {
	return staircase(cuts, diffuse*steepness);
}


void fragment() {
	ALBEDO = albedo.rgb;
}

void light() {
	// Attenuation.
	float attenuation = 1.0f;
	if (use_attenuation) {
		attenuation = ATTENUATION.x;
	}
	
	// Diffuse lighting.
	float NdotL = dot(NORMAL, LIGHT);
	float diffuse_amount = split_diffuse((NdotL * attenuation + wrap));
	
	
	vec3 diffuse = vec3(1.0);
	diffuse *= diffuse_amount;
	vec3 light_color = diffuse * ALBEDO.rgb;
	vec3 dark_color = (1.0 - diffuse) * shadow_color.rgb;
	diffuse = light_color + dark_color;
	
	if (clamp_diffuse_to_max) {
		// Clamp diffuse to max for multiple light sources.
		DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
	} else {
		DIFFUSE_LIGHT += diffuse;
	}
}