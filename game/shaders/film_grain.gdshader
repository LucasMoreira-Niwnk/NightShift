// ==============================================================================
// NIGHTSHIFT — GRÃO DE FILME (overlay da imagem de jogo)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/film_grain.gdshader)
// APLICAÇÃO:
//   ColorRect de tela cheia num CanvasLayer abaixo do HUD (main.gd).
// OBJETIVO DO AGENTE:
//   Emulsão, não chuvisco. Três coisas separam um do outro:
//   1. o grão é ruído de valor interpolado, não um sorteio por pixel, então
//      tem tamanho e borda macia em vez de pontilhado duro;
//   2. a amplitude sai da soma de duas amostras, o que puxa a distribuição
//      para o meio e rareia os extremos, como prata de verdade;
//   3. a resposta segue a luminância: preto absoluto fica limpo, o grão cresce
//      nos meios-tons e some de novo nas altas luzes.
//   O tubo CRT, com curva e varredura, mora nas telas de computador.
// ==============================================================================
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.055;
uniform float grain_size : hint_range(0.5, 5.0) = 1.9;
uniform float color_spread : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.22;
// Cadencia do grao: quantas vezes por segundo o padrao e re-sorteado. Precisa
// ficar bem abaixo da taxa de quadros, senao cada quadro cai num sorteio novo
// e o grao ferve em vez de granular. Medido a 17 fps nesta cena, 5 Hz segura
// cada padrao por uns tres quadros.
uniform float grain_fps : hint_range(1.0, 60.0) = 5.0;

float hash(vec2 seed) {
	return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Ruído de valor: sorteia nos cantos da célula e interpola. É o que dá tamanho
// e borda macia ao grão, em vez do pontilhado de um sorteio por pixel.
float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 inner = fract(point);
	inner = inner * inner * (3.0 - 2.0 * inner);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, inner.x), mix(c, d, inner.x), inner.y);
}

// Duas amostras somadas: a distribuição deixa de ser plana e os extremos ficam
// raros, que é como o grão de prata realmente se distribui.
float silver(vec2 point, float frame) {
	float coarse = value_noise(point + vec2(frame * 13.73, frame * 7.31));
	float fine = value_noise(point * 2.17 + vec2(frame * 5.11, frame * 9.47));
	return (coarse + fine) * 0.5 - 0.5;
}

void fragment() {
	float frame = floor(TIME * grain_fps);
	vec2 point = FRAGCOORD.xy / grain_size;

	// Resposta da emulsão: preto absoluto fica limpo, o grão cresce nos meios
	// tons e some nas altas luzes. Grão no vazio preto é chuvisco, não filme.
	float luma = dot(texture(screen_tex, SCREEN_UV).rgb, vec3(0.299, 0.587, 0.114));
	float response = smoothstep(0.0, 0.09, luma) * (1.0 - smoothstep(0.45, 1.0, luma));

	// As três camadas de cor do negativo não coincidem: um leve descolamento
	// tira o cinza morto do grão sem virar ruído colorido.
	float base = silver(point, frame);
	float shift = color_spread * 0.6;
	vec3 grain = vec3(
		mix(base, silver(point + vec2(1.7, 0.0), frame), shift),
		base,
		mix(base, silver(point - vec2(0.0, 1.7), frame), shift));
	grain *= grain_amount * response * 4.0;

	// Vinheta discreta, sem oscilar: na mão do jogador a lâmpada é a lanterna.
	vec2 edge = UV * (1.0 - UV.yx);
	float corner = clamp(1.0 - edge.x * edge.y * 15.0, 0.0, 1.0);

	// O grão multiplica a densidade, como na película: ele modula o que já está
	// na tela em vez de jogar pontos por cima. Preto continua preto.
	vec3 image = texture(screen_tex, SCREEN_UV).rgb;
	image *= vec3(1.0) + grain;
	image *= 1.0 - corner * vignette_strength;
	COLOR = vec4(image, 1.0);
}
