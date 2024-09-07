shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap; 

void fragment() {
	vec3 x = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	x = vec3(1.0) - x;
	COLOR.rgb = x;
}
