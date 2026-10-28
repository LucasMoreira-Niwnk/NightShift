// ==============================================================================
// NIGHTSHIFT — TUBO CRT DE MONITOR (curvatura na própria tela)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/crt_screen.gdshader)
// APLICAÇÃO:
//   material_override das telas 3D (monitor da segurança e os três displays).
// OBJETIVO DO AGENTE:
//   Diferente de crt.gdshader, este não amostra a tela do jogo: ele curva a
//   própria textura do monitor, então funciona num quad visto de qualquer
//   ângulo. Fora da curvatura o vidro fica preto, como tubo apagado.
// ==============================================================================
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D feed : source_color, filter_linear_mipmap;
uniform float curvature : hint_range(1.0, 12.0) = 4.0;
uniform float chromatic_aberration : hint_range(0.0, 5.0) = 0.8;
uniform float line_count : hint_range(50.0, 800.0) = 260.0;
uniform float line_opacity : hint_range(0.0, 1.0) = 0.22;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	// Curvatura do vidro: estica a UV a partir do centro da tela.
	vec2 uv = UV * 2.0 - 1.0;
	vec2 bulge = abs(uv.yx) / vec2(curvature);
	uv = uv + uv * bulge * bulge;
	uv = uv * 0.5 + 0.5;

	bool outside = uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0;
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	float split = chromatic_aberration * 0.001;
	vec3 col = vec3(
		texture(feed, vec2(uv.x + split, uv.y)).r,
		texture(feed, uv).g,
		texture(feed, vec2(uv.x - split, uv.y)).b);

	// Varredura e vinheta seguem a UV curvada, então acompanham o vidro.
	float line = sin(uv.y * line_count * 3.14159) * 0.5 + 0.5;
	col *= 1.0 - line * line_opacity;

	vec2 edge = uv * (1.0 - uv.yx);
	float vig = pow(clamp(edge.x * edge.y * 15.0, 0.0, 1.0), vignette_strength);
	col *= vig * brightness;

	if (outside) { col = vec3(0.0); }
	ALBEDO = col;
}
