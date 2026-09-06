shader_type canvas_item;

// スクリプト側から動かす値。0で透明、1でノイズ最大。
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float wave_amplitude = 0.02;
uniform float wave_frequency = 10.0;
uniform float wave_speed = 5.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
// 帯の本数と、縦に流れる速さ。インスペクタで調整可。
uniform float band_count = 8.0;
uniform float band_speed = 3.0;
// 帯の太さ（0=細い〜0.5=太い）。
uniform float band_width : hint_range(0.0, 0.5) = 0.05;

// 簡易的な疑似乱数（同じ入力なら同じ値）
float rand(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// 縦に流れる横帯
	float phase = fract(UV.y * band_count - TIME * band_speed);
	float band = 1.0 - smoothstep(0.0, band_width, phase);
	float mask = band * intensity;

	// 画面をマス目に区切ってザラザラのノイズを作る
	vec2 cell = floor(UV * vec2(160.0, 120.0));
	float noise = rand(cell + floor(TIME * 30.0));

	// 画面をうねらせる
	vec2 distorted_uv = SCREEN_UV;
	float wave = sin(distorted_uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude;
	distorted_uv.x += wave;
	vec4 screen_color = texture(screen_texture, distorted_uv);

	// 帯の中だけ、歪んだ画面にノイズを乗せる
	vec3 col = mix(screen_color.rgb, vec3(noise), mask);
	COLOR = vec4(col, 1.0);
}
