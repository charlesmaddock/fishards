shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D alpha_texture;
uniform bool alpha_grayscale = false;
uniform vec4 light_color : hint_color;
uniform vec4 dark_color : hint_color;
uniform bool billboard = true;
uniform bool circle_shape = false;
uniform bool gradient_color = true;
uniform bool random_between_colors = false;

void fragment(){
	float alpha = texture(alpha_texture, vec2(UV)).w;
	if (alpha_grayscale) {
		alpha = texture(alpha_texture, vec2(UV)).r;
	}
	if(circle_shape){
		alpha = 1.0 - distance(UV, vec2(0.5, 0.5));
	}
	
	vec3 color = COLOR.g * light_color.rgb + COLOR.r * dark_color.rgb;
	if (random_between_colors){
		color = mix(dark_color.rgb, light_color.rgb, COLOR.r)
	}
	ALBEDO = color;
	ALPHA = alpha;
	ALPHA_SCISSOR = 0.5;
}

void vertex()
{
	if(billboard){
		mat4 mat_world = mat4(normalize(CAMERA_MATRIX[0])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[1])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[2])*length(WORLD_MATRIX[2]),WORLD_MATRIX[3]);
		mat_world = mat_world * mat4( vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat_world;
	}
}