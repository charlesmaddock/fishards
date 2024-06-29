shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 light_color : hint_color;
uniform vec4 dark_color : hint_color;
uniform sampler2D noise_tex;
uniform sampler2D shape_tex;

uniform float outer_cutout = 0.7;
uniform float inner_cutout = 0.1;

uniform float scroll_speed = 0.25;

void fragment(){
	vec2 displ = texture( noise_tex, UV*0.5 - TIME / 8.0).rg;
	displ = ((displ * 2.0) -1.0) * 0.01;
	
	float noise = texture( noise_tex, vec2(UV.x, UV.y + TIME * scroll_speed)).r;
	float shape = texture( shape_tex, vec2(UV.x, UV.y)).r;
	
	noise = 1.0 - (noise + shape) * shape;
	
	float inner_fire_shape = step(0, inner_cutout -noise);
	vec3 inner_fire_rgb = vec3(light_color.rgb) * inner_fire_shape;
	
	float outer_fire_shape = step( 0, outer_cutout - noise) * (1.0 - inner_fire_shape);
	vec3 outer_fire_rgb = vec3(dark_color.rgb) * outer_fire_shape;
	
	float fire_shape = inner_fire_shape + outer_fire_shape;
	vec3 fire_color = outer_fire_rgb + inner_fire_rgb;
	
	ALBEDO = fire_color;
	ALPHA = fire_shape;
	ALPHA_SCISSOR = 0.01;
	
}

