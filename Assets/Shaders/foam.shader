shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 color: hint_color;
uniform sampler2D noise_tex;
uniform float x_tiling = 3.0;
uniform float noise_scale = 2.0;
uniform sampler2D foam_gradient;


uniform sampler2D dark_color_gradient;
uniform vec4 dark_color: hint_color;

uniform float cutout = 0.2;

uniform float scroll_speed = 0.25;

void fragment(){
	
	float noise = texture( noise_tex, vec2(UV.x * x_tiling * noise_scale, UV.y * noise_scale- TIME  * scroll_speed)).r;
	float gradient = texture( foam_gradient, vec2(UV.y, UV.x)).r;
	float inner_color_gradient = texture( dark_color_gradient, vec2(UV.y, UV.x)).r;
	
	noise = 1.0 - (noise + gradient) * gradient;

	float shape = step( 0, cutout - noise);
	inner_color_gradient = step(0, 0.5 - (inner_color_gradient - shape));
	
	vec3 foam_color = color.rgb * shape + dark_color.rgb * inner_color_gradient;
	
	
	ALBEDO = foam_color;
	ALPHA = shape + inner_color_gradient;
	ALPHA_SCISSOR = 0.01;
	
}