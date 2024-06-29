shader_type spatial;
render_mode unshaded;

uniform vec4 light_color : hint_color;
uniform vec4 dark_color : hint_color;
uniform sampler2D noise_tex;
uniform sampler2D shape_tex;
uniform float noise_scale = 1.0;
uniform float shape_scale = 1.0;
uniform float shape_strength = 0.7;

uniform float scroll_speed = 0.05;

void fragment(){
	float noise = texture( noise_tex, vec2(UV.x*noise_scale, UV.y*noise_scale + TIME * scroll_speed)).r;
	float shape = 1.0  - texture( shape_tex, vec2(UV.x*shape_scale, UV.y*shape_scale)).r;
	
	float shape_cutout = step(noise, shape * shape_strength);
	vec3 color = mix(dark_color.rgb, light_color.rgb, shape_cutout).rgb;
	
	ALBEDO = color;
}