// ==============================================================================
// NIGHTSHIFT — SHADER DE SCANLINES & VARREDURA VERTICAL (OVERLAY UNIVERSAL)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/scanlines.gdshader)
// APLICAÇÃO:
//   Gera as linhas analógicas horizontais de CRT, barra de varredura rolante
//   e vinheta nas bordas em qualquer ColorRect sobreposto.
// ==============================================================================
shader_type canvas_item;

uniform float line_count : hint_range(100.0, 800.0) = 360.0;
uniform float line_opacity : hint_range(0.0, 1.0) = 0.18;
uniform float scroll_speed : hint_range(0.0, 5.0) = 0.5;
uniform bool rolling_bar = true;
uniform float bar_speed : hint_range(0.0, 2.0) = 0.15;
uniform float bar_size : hint_range(0.01, 0.3) = 0.08;
uniform float bar_opacity : hint_range(0.0, 0.5) = 0.06;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	// Horizontal scanlines
	float line = sin((UV.y + TIME * scroll_speed * 0.01) * line_count * 3.14159) * 0.5 + 0.5;
	float dark = line * line_opacity;

	// Rolling phosphor refresh bar
	float bar = 0.0;
	if (rolling_bar) {
		float bar_pos = fract(TIME * bar_speed);
		float dist = abs(UV.y - bar_pos);
		if (dist > 0.5) dist = 1.0 - dist;
		bar = smoothstep(bar_size, 0.0, dist) * bar_opacity;
	}

	// CRT edge vignette
	vec2 vig_uv = UV * (1.0 - UV.yx);
	float vig = vig_uv.x * vig_uv.y * 15.0;
	float vignette = clamp(1.0 - vig, 0.0, 1.0) * vignette_strength;

	// Color output: scanline darkness + phosphor bar + vignette
	COLOR = vec4(0.0, bar * 0.25, 0.0, clamp(dark + vignette, 0.0, 0.9));
}
