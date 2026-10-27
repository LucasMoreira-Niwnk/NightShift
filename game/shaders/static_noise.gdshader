// ==============================================================================
// NIGHTSHIFT — SHADER DE ESTÁTICA / SEM SINAL (White Noise Analógico)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/static_noise.gdshader)
// APLICAÇÃO:
//   Usado pelo nó interno de 'camera_feed.gd' quando uma câmera perde sinal
//   ou entra em modo instável. Pode ser ativado via show_static(true).
// ==============================================================================
shader_type canvas_item;

// Static noise / no-signal effect for camera feeds
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.8;
uniform float scan_speed : hint_range(0.0, 5.0) = 2.0;
uniform vec4 noise_color : source_color = vec4(0.1, 0.3, 0.1, 1.0);
uniform bool show_bars = false;
uniform float bar_count : hint_range(2.0, 20.0) = 8.0;

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	float time_val = TIME;

	// Base noise
	float noise = random(uv * 500.0 + vec2(time_val * 100.0, time_val * 73.0));
	float noise2 = random(uv * 200.0 + vec2(time_val * 50.0, time_val * 37.0));

	vec3 col = mix(vec3(0.0), noise_color.rgb, noise * noise_intensity);

	// Horizontal scan lines in noise
	float scan = sin(uv.y * 800.0 + time_val * scan_speed * 50.0) * 0.5 + 0.5;
	col *= 0.8 + scan * 0.2;

	// Rolling distortion
	float roll = sin(uv.y * 4.0 + time_val * 2.0) * 0.5 + 0.5;
	col *= 0.9 + roll * 0.1;

	// Optional color bars (no signal pattern)
	if (show_bars) {
		float bar = floor(uv.x * bar_count) / bar_count;
		vec3 bar_col = vec3(
			random(vec2(bar, 0.1)),
			random(vec2(bar, 0.2)),
			random(vec2(bar, 0.3))
		);
		col = mix(col, bar_col * 0.3, 0.3);
	}

	// Occasional bright horizontal lines
	float bright_line = step(0.98, random(vec2(floor(uv.y * 100.0), floor(time_val * 10.0))));
	col += vec3(bright_line * 0.3);

	COLOR = vec4(col, 1.0);
}
