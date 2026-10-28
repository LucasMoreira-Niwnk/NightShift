// ==============================================================================
// NIGHTSHIFT — GRÃO DE FILME (overlay global do HUD)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/film_grain.gdshader)
// APLICAÇÃO:
//   ColorRect de tela cheia no CanvasLayer mais alto (main.gd).
// OBJETIVO DO AGENTE:
//   O olho de Daniel não é um monitor: aqui não há curvatura nem varredura, só
//   a emulsão suja de uma película. O grão sorteia por célula e por quadro, mais
//   pesado nas sombras, como filme forçado em ASA alto. A vinheta respira de
//   leve, imitando a lâmpada instável de um projetor.
//   O tubo CRT, com curva e scanline, mora nas telas de computador.
// ==============================================================================
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain_amount : hint_range(0.0, 0.5) = 0.075;
uniform float grain_size : hint_range(1.0, 4.0) = 1.5;
uniform float shadow_bias : hint_range(0.0, 1.0) = 0.65;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float gate_flicker : hint_range(0.0, 0.2) = 0.012;
// Cadencia do grao: quantas vezes por segundo o padrao e re-sorteado. Precisa
// ficar bem abaixo da taxa de quadros, senao cada quadro cai num sorteio novo
// e o grao ferve em vez de granular. Medido a 17 fps nesta cena, 5 Hz segura
// cada padrao por uns tres quadros.
uniform float grain_fps : hint_range(1.0, 60.0) = 5.0;

float hash(vec2 seed) {
	return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	// Uma amostra por célula de grão, re-sorteada a cada fotograma — não a cada
	// quadro renderizado, senão o grão ferve em vez de granular.
	vec2 cell = floor(FRAGCOORD.xy / grain_size);
	float frame = floor(TIME * grain_fps);
	float roll = hash(cell + vec2(frame * 13.73, frame * 7.31));
	float grain = roll - 0.5;

	// Emulsão suja: o grão pesa mais onde a imagem já está escura.
	float luma = dot(texture(screen_tex, SCREEN_UV).rgb, vec3(0.299, 0.587, 0.114));
	float weight = mix(1.0, 1.0 - luma, shadow_bias);

	vec3 tone = grain > 0.0 ? vec3(1.0) : vec3(0.0);
	float speck = abs(grain) * 2.0 * grain_amount * weight;

	// Vinheta do projetor, com a lâmpada oscilando de leve.
	vec2 edge = UV * (1.0 - UV.yx);
	float corner = clamp(1.0 - edge.x * edge.y * 15.0, 0.0, 1.0);
	float lamp = 1.0 + sin(TIME * 5.3) * sin(TIME * 2.1) * gate_flicker;
	float shade = corner * vignette_strength * lamp;

	// Duas contribuições com cores diferentes somadas em uma saída só.
	float total = clamp(speck + shade, 0.0, 0.92);
	vec3 blended = total > 0.0 ? (tone * speck) / total : vec3(0.0);
	COLOR = vec4(blended, total);
}
