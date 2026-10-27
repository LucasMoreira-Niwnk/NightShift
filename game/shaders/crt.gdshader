// ==============================================================================
// NIGHTSHIFT — SHADER DE MONITOR CRT (Curvatura, Aberração & Vinheta)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/crt.gdshader)
// APLICAÇÃO:
//   Aplique em um ColorRect de tela inteira (em um CanvasLayer de UI) ou no
//   material de superfície de um monitor 3D (StandardMaterial3D -> Next Pass).
// ==============================================================================
shader_type canvas_item;

// CRT Monitor Effect - curvature, chromatic aberration, vignette
uniform float curvature : hint_range(0.0, 10.0) = 3.0;
uniform float chromatic_aberration : hint_range(0.0, 5.0) = 0.5;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float brightness : hint_range(0.5, 1.5) = 1.0;
uniform float flicker_intensity : hint_range(0.0, 0.1) = 0.03;
uniform vec4 tint_color : source_color = vec4(0.0, 1.0, 0.5, 1.0);
uniform bool use_tint = false;

vec2 curve_uv(vec2 uv) {
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(curvature);
	uv = uv + uv * offset * offset;
	uv = uv * 0.5 + 0.5;
	return uv;
}

void fragment() {
	vec2 curved_uv = curve_uv(UV);

	// Out of bounds check
	if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	// Chromatic aberration
	float offset = chromatic_aberration * 0.001;
	float r = texture(TEXTURE, vec2(curved_uv.x + offset, curved_uv.y)).r;
	float g = texture(TEXTURE, curved_uv).g;
	float b = texture(TEXTURE, vec2(curved_uv.x - offset, curved_uv.y)).b;
	float a = texture(TEXTURE, curved_uv).a;

	vec4 col = vec4(r, g, b, a);

	// Tint
	if (use_tint) {
		float luminance = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		col.rgb = tint_color.rgb * luminance;
	}

	// Flicker
	float flicker = 1.0 - flicker_intensity * sin(TIME * 8.0) * sin(TIME * 13.0);
	col.rgb *= flicker;

	// Vignette
	vec2 vig_uv = curved_uv * (1.0 - curved_uv.yx);
	float vig = vig_uv.x * vig_uv.y * 15.0;
	vig = pow(vig, vignette_strength * 0.5);
	col.rgb *= vig;

	// Brightness
	col.rgb *= brightness;

	COLOR = col;
}
