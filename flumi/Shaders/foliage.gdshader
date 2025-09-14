shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float x_intensity = 3.0;
uniform float y_intensity = 0.5;
uniform float offset = 0.0;
uniform float speed : hint_range(0, 20) = 2.0;
uniform float wave_frequency : hint_range(0, 100) = 20;
uniform float wave_length : hint_range(50, 800) = 200.0;

void fragment() {
	vec2 real_uv = UV;
	
	vec2 vecToBottom = vec2(1, 1) - UV.y; 
	float distToBottom = length(vecToBottom);
	
	float final_speed = TIME * (speed / 4.0) + offset;
	
	float time_var = (cos(final_speed) * cos(final_speed * 4.0) * cos(final_speed * 2.0))/(200.0);
	float time_var2 = (cos(final_speed) * cos(final_speed * 6.0) * cos(final_speed * 2.0))/(200.0);
	
	float wave_from_x = (cos(real_uv.x * 100.0)/1000.0);
	float wave_large_from_x = cos(TIME + (real_uv.x * wave_frequency))/wave_length;
	
	float offset_x = time_var * (distToBottom * x_intensity) + wave_from_x + (wave_large_from_x);
	float offset_y = time_var2 * (distToBottom * y_intensity);
	
	vec2 distortion_offset = vec2(offset_x, offset_y);
	
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV + distortion_offset);
}