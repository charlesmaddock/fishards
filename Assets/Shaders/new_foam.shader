shader_type spatial;
render_mode unshaded;

uniform vec4 foam_color: hint_color;
uniform sampler2D noise_tex;
uniform vec2 noise_scale = vec2(3.0, 1.0);
uniform sampler2D foam_gradient;


uniform float dark_color_cutout = 0.7;

uniform vec4 dark_color: hint_color;

uniform float scroll_speed = 0.25;

void fragment(){
	
	float noise = texture( noise_tex, vec2(UV.x  * noise_scale.x, UV.y * noise_scale.y - TIME  * scroll_speed)).r;
	float cutout_gradient = 1.0 - texture(foam_gradient, vec2(UV.y, UV.x)).r;
	float inner_color_gradient = UV.y;
	
	
	float foam_shape = step(cutout_gradient, noise);
	float inner_shape = step(dark_color_cutout, inner_color_gradient);

	inner_shape *= 1.0  - foam_shape;
	
	vec3 inner_color = inner_shape * dark_color.rgb;
	vec3 outer_color = foam_shape * foam_color.rgb;
	
	vec3 color = inner_color + outer_color;
	float alpha = inner_shape + foam_shape;
	
	ALBEDO = vec3(color);
	ALPHA = alpha;
	ALPHA_SCISSOR = 0.01;
	
}