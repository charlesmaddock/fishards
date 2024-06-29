shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 color: hint_color;
uniform float max_length = 10.0;
uniform float beam_length = 1.0;
uniform sampler2D noise_tex;
uniform vec2 noise_scale = vec2(1.0);
uniform float cylinder_diameter = 1.0;
uniform float fadeout_multiplier = 1.0;
uniform bool animate_beam = false;


void fragment() {
	float y_tiling = beam_length;
	if(beam_length > max_length){
		y_tiling = max_length
	}
	
	float noise = texture(noise_tex, UV * vec2(1.0, y_tiling) * noise_scale).r;
	
	ALBEDO = color.rgb;
	ALPHA = 1.0;
	ALPHA = step(COLOR.a*fadeout_multiplier, noise);
	ALPHA_SCISSOR = 0.1;
}

void vertex() {
	VERTEX.zy *= cylinder_diameter;
	if(animate_beam){
		VERTEX.zy *= sin(COLOR.a*10.0)+2.0;
	}
	VERTEX.x += clamp((beam_length)*ceil(COLOR.r), 0.0, max_length) -1.0*ceil(COLOR.r);
}