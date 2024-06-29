shader_type spatial;
render_mode unshaded;

uniform vec4 color: hint_color;
uniform sampler2D noise_tex;
uniform vec2 noise_scale = vec2(1.0,1.0);
uniform float noise_speed = 1.0;

uniform sampler2D vertex_disp_gradient;
uniform float cutout= 1.0;

void fragment() {
	float gradient = texture(vertex_disp_gradient, vec2(UV.y, UV.x)).r;
	float noise = texture(noise_tex, UV*noise_scale + vec2(0, -TIME*noise_speed)).r;
	
	float alpha = step(gradient*cutout, noise) * color.a;
	
	ALBEDO = color.rgb;
	ALPHA = alpha;
	ALPHA_SCISSOR = 1.0;
}

void vertex() {
	float gradient = texture(vertex_disp_gradient, vec2(UV.y, UV.x)).r;
	float noise = texture(noise_tex, UV*noise_scale + vec2(0, -TIME*noise_speed)).r;
	VERTEX += noise*NORMAL*gradient;
	VERTEX.y -= noise*gradient;
}