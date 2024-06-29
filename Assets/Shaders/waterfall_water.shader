shader_type spatial; render_mode unshaded, cull_disabled;

uniform vec2 scaling = vec2(20.0,2.0);
uniform float cutout = 0.2;
uniform float speed = 2;
uniform sampler2D gradient_tex: hint_black;

uniform vec4 dark_color: hint_color;
uniform vec4 light_color: hint_color;

// Noise functions
float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}
vec3 v3_mod289(vec3 x) { 
	return x - floor(x * (1.0 / 289.0)) * 289.0;
	}
vec2 v2_mod289(vec2 x) { 
	return x - floor(x * (1.0 / 289.0)) * 289.0; 
	}
vec3 permute(vec3 x) { 
	return v3_mod289(((x*34.0)+1.0)*x); 
	}
float noise (in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}
float fbm (in vec2 uv, int octaves) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(uv);
        uv *= 2.;
        amplitude *= .5;
    }
    return value;
}


void fragment(){
	float noise = fbm(vec2(UV.x*scaling.x, UV.y*scaling.y - TIME * speed), 3);
	vec3 gradient = texture(gradient_tex, vec2(UV.y, UV.x)).rgb;
	float shape = step(gradient.r, noise ) ;
	vec3 color = mix(dark_color, light_color, shape).rgb;
	
	ALBEDO = color;
}