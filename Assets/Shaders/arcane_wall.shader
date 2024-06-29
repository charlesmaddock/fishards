shader_type spatial;
render_mode unshaded;

uniform vec4 color : hint_color;
uniform sampler2D noise_tex;
uniform sampler2D gradient_tex;

uniform float outer_cutout = 0.7;
uniform float inner_cutout = 0.1;

uniform float scroll_speed = 0.25;

void fragment(){
	
	float noise = texture( noise_tex, vec2(UV.x *0.25, UV.y - TIME * scroll_speed)).r;
	float gradient = texture( gradient_tex, vec2(UV.y, UV.x)).r;
	
	noise = 1.0 - (noise + gradient) * gradient;

	float shape = step( 0, outer_cutout - noise);
	
	ALBEDO = color.rgb;
	ALPHA = shape;
	ALPHA_SCISSOR = 0.01;
	
}