shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D noise_tex;
uniform vec2 noise_scale = vec2(1.0, 1.0);
uniform vec4 light_color : hint_color;
uniform vec4 dark_color : hint_color;
uniform bool billboard = true;
uniform float speed = 10.0;
uniform int polar_scale = 2;


void fragment(){
	float circle_gradient = distance(UV, vec2(0.5,0.5))*2.0;
	float inner_circle_gradient = distance(UV, vec2(0.5,0.5))*4.0;
	
	float torus_gradient = 1.0 - ((1.0-circle_gradient) * inner_circle_gradient);
	
	float x = (UV.x - 0.5)*noise_scale.x;
	float y = (UV.y - 0.5)*noise_scale.y;
	vec2 polar_coordinates = vec2(sqrt(pow(x, 2)+ pow(y, 2)) - TIME*speed, atan(y/x)/3.14159265359*float(polar_scale));
	float noise = texture(noise_tex, polar_coordinates).r;
	
	
	float shape = step(torus_gradient, noise);
	
	vec3 color = COLOR.g * light_color.rgb + COLOR.r * dark_color.rgb;
	ALBEDO = vec3(color);
	ALPHA = shape;
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