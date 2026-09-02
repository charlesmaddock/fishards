shader_type canvas_item;

uniform vec4 color: source_color;

void fragment(){
	float circle = 1.0 - step(0.5, distance(vec2(0.5), UV));
	COLOR = vec4(color.rgb, circle);
}