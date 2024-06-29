shader_type spatial;
render_mode unshaded;

uniform vec4 color: hint_color;
uniform float radius = 0.5;
uniform float stroke_width = 0.03;
uniform bool use_noise = false;
uniform sampler2D noise_tex;
uniform vec2 noise_scale = vec2(1.0);
uniform float noise_cutout = 0.5;

void fragment() {
	float noise = 1.0;
	if(use_noise){
		noise = step(noise_cutout, texture(noise_tex, UV * noise_scale).r);
	}
	
	float outer_circle = 1.0 - step(radius*noise, distance(vec2(0.5), UV));
	float inner_circle = 1.0 - step((radius-stroke_width)*noise, distance(vec2(0.5), UV));
	
	float circle = outer_circle - inner_circle;
	
	
	
	
	
	
	
	ALBEDO = color.rgb;
	ALPHA = circle;
}