shader_type spatial; render_mode unshaded;

uniform float frequency = 10.0;
uniform float speed = 8.0;
uniform sampler2D cutout_gradient;
uniform vec2 noise_scale = vec2(8.0,2.0);



float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

//simplex
vec3 v3_mod289(vec3 x) { 
	return x - floor(x * (1.0 / 289.0)) * 289.0;
	}
vec2 v2_mod289(vec2 x) { 
	return x - floor(x * (1.0 / 289.0)) * 289.0; 
	}
vec3 permute(vec3 x) { 
	return v3_mod289(((x*34.0)+1.0)*x); 
	}
float simplex(vec2 v) {

    const vec4 C = vec4(0.211324865405187,
                        0.366025403784439,
                        -0.577350269189626,
                        0.024390243902439);

    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    vec2 i1 = vec2(0.0);
    i1 = (x0.x > x0.y)? vec2(1.0, 0.0):vec2(0.0, 1.0);
    vec2 x1 = x0.xy + C.xx - i1;
    vec2 x2 = x0.xy + C.zz;

    i = v2_mod289(i);
    vec3 p = permute(
            permute( i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(
                        dot(x0,x0),
                        dot(x1,x1),
                        dot(x2,x2)
                        ), 0.0);

    m = m*m ;
    m = m*m ;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);

    vec3 g = vec3(0.0);
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * vec2(x1.x,x2.x) + h.yz * vec2(x1.y,x2.y);
    return 130.0 * dot(m, g) * 0.5 + 0.5;
}

void fragment(){
	float noise = simplex(vec2(UV.x * noise_scale.x, UV.y * noise_scale.y));
	float sin_pattern = abs(sin(frequency * UV.y - TIME*speed));
	float gradient = texture(cutout_gradient, vec2(UV.y, UV.x)).r;
	
	float shape = (sin_pattern + noise) / 2.0;
	float cut_shape = step(gradient, shape);
	
	ALBEDO = vec3(cut_shape);
	ALPHA = cut_shape;
	
}