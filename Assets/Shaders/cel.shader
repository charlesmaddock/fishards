shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 base_color : hint_color = vec4(1.0);
uniform vec4 shade_color : hint_color = vec4(1.0);

uniform float shade_threshold : hint_range(-1.0, 1.0, 0.001) = 0.0;

uniform sampler2D base_texture: hint_albedo;
uniform sampler2D shade_texture: hint_albedo;
uniform sampler2D alpha_texture: hint_albedo;

uniform bool use_attenuation = false;

void light()
{
	float attenuation = 1.0f;
	if (use_attenuation) {
		attenuation = ATTENUATION.x;
	}
	
	float NdotL = dot(normalize(NORMAL), normalize(LIGHT));
	float angle = acos(NdotL);
	vec4 base = base_color.rgba;
	vec4 shade = shade_color.rgba;
	vec4 diffuse = base;

	float shade_value = step(0 ,shade_threshold + NdotL);
	diffuse = mix(shade, base, shade_value);

	float alpha_cutout = texture(alpha_texture,UV).a;
	
	DIFFUSE_LIGHT = diffuse.rgb;
	ALPHA = diffuse.a * alpha_cutout;
}

void fragment(){
	ALPHA_SCISSOR = 1.0;
}
