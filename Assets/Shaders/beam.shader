shader_type spatial; render_mode unshaded, cull_disabled;

uniform vec4 color: hint_color;
uniform sampler2D noise_tex;
uniform vec2 noise_scale = vec2(1.0,1.0);
uniform sampler2D gradient_tex;



void fragment() {
	float gradient = texture(gradient_tex,vec2(UV.y, UV.x)).r;
	float noise = texture(noise_tex, UV*noise_scale).r;
	
	gradient *= COLOR.r;
	float shape = step(gradient*1.5, noise-gradient);
	
	
	ALBEDO = vec3(shape) * color.rgb;
	ALPHA = shape;
	ALPHA_SCISSOR = 0.5;
}