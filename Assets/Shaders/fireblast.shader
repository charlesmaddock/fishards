shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D noise_texture;
uniform sampler2D shape_texture;
uniform float noise_outer_cutout = 0.2;
uniform float noise_inner_cutout = 0.4;
uniform float noise_scale = 0.8;
uniform vec2 noise_scroll_speed = vec2(0.0,0.0);
uniform vec4 light_color : hint_color;
uniform vec4 dark_color : hint_color;
uniform bool flip_shape_tex = false;
uniform bool use_color_for_time = true;
uniform float impulse_progress = 0.0;


float impulse( float k, float x, float time){
    float h = k*x+time;
    return h*exp(1.0-h);
}

void fragment(){
	float noise = texture(noise_texture, vec2(UV.x, UV.y*0.8)/noise_scale  + noise_scroll_speed*TIME).r;
	float shape = texture(shape_texture, UV).r;
	if(flip_shape_tex){
		shape = texture(shape_texture, vec2(UV.y, UV.x)).r;
	}
	float wave = impulse(4, UV.y, COLOR.r*17.0-3.0);
	if(!use_color_for_time){
		wave = impulse(4, UV.y, impulse_progress*17.0-3.0);
	}
	
	float outline_shape = step(noise_outer_cutout, wave * noise *shape);
	float outer_shape = step(noise_outer_cutout, wave * noise *shape) - 
			step(noise_inner_cutout, wave * noise * shape);
	float inner_shape = step(noise_inner_cutout, wave * noise * shape);
	//vec3 color = outer_shape * dark_color.rgb + inner_shape * light_color.rgb;
	
	vec3 color = dark_color.rgb * outer_shape + light_color.rgb * inner_shape;
	ALBEDO = color;
	ALPHA = outline_shape;
	ALPHA_SCISSOR = 0.9;
}