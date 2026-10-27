// ==============================================================================
// NIGHTSHIFT — SHADER DE SCANLINES & VARREDURA VERTICAL
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/scanlines.gdshader)
// APLICAÇÃO:
//   Gera as linhas pretas horizontais analógicas e a barra luminosa que rola pela
//   tela. Deve ficar em uma camada acima do conteúdo da interface com blend normal.
// ==============================================================================
shader_type canvas_item;

// Scanline overlay effect
uniform float line_count : hint_range(100.0, 800.0) = 400.0;
uniform float line_opacity : hint_range(0.0, 1.0) = 0.15;
uniform float scroll_speed : hint_range(0.0, 5.0) = 0.5;
uniform float line_brightness : hint_range(0.0, 0.5) = 0.05;
uniform bool rolling_bar = true;
uniform float bar_speed : hint_range(0.0, 2.0) = 0.3;
uniform float bar_size : hint_range(0.01, 0.3) = 0.08;
uniform float bar_opacity : hint_range(0.0, 0.5) = 0.1;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// Horizontal scanlines
	float line = sin((UV.y + TIME * scroll_speed * 0.01) * line_count * PI) * 0.5 + 0.5;
	line = smoothstep(0.4, 0.6, line);
	col.rgb -= vec3(line * line_opacity);

	// Bright line between scanlines
	col.rgb += vec3(line * line_brightness);

	// Rolling bar (the bright bar that scrolls down CRT monitors)
	if (rolling_bar) {
		float bar_pos = fract(TIME * bar_speed);
		float dist = abs(UV.y - bar_pos);
		if (dist > 0.5) dist = 1.0 - dist;
		float bar = smoothstep(bar_size, 0.0, dist) * bar_opacity;
		col.rgb += vec3(bar);
	}

	COLOR = col;
}
