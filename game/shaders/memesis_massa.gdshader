// ==============================================================================
// NIGHTSHIFT — CORPO DO MÊMESIS LIDO DA FOTO
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/memesis_massa.gdshader)
// APLICAÇÃO:
//   material do FogVolume único do corpo, montado em scripts/memesis_corpo.gd.
// AVISO DE COMPATIBILIDADE:
//   shader_type fog só existe no renderizador Forward+, que é o do projeto
//   desde a migração. O preset mobile continua em gl_compatibility.
// OBJETIVO DO AGENTE:
//   A silhueta não é modelada, é LIDA: a foto de referência entra como campo de
//   densidade. Onde a imagem tem figura, há névoa; onde tem fundo, não há nada.
//   Por isso o contorno bate com a foto — tentar reproduzir aquela pose com
//   elipsoides à mão nunca ia bater, e foi o que não funcionou antes.
//   A cor vem junto: a parte escura da foto vira névoa preta que absorve, a
//   clara vira fumaça branca que espalha, e a franja iridescente da imagem
//   acende como emissão. Os três papéis saem do mesmo pixel.
//   A profundidade é extrudada: a foto é plana, então o volume é uma laje densa
//   no meio e rarefeita nas faces. De lado ele afina — é a limitação honesta de
//   partir de uma imagem, não um bug.
// NOTA DE SHADER:
//   o processador `fog` proíbe `return`; os recortes são fatores 0/1.
// ==============================================================================
shader_type fog;

uniform sampler2D foto : source_color, filter_linear, repeat_disable;
uniform float densidade : hint_range(0.0, 30.0) = 14.0;
// Espessura útil da laje, em fração da caixa: 0.5 usa a caixa inteira.
uniform float espessura : hint_range(0.05, 0.5) = 0.34;
// Abaixo disto a foto é fundo e não gera névoa nenhuma.
uniform float corte : hint_range(0.0, 0.5) = 0.06;
// Separação dos canais da franja, em UV.
uniform float aberration : hint_range(0.0, 0.05) = 0.006;
uniform float fringe_gain : hint_range(0.0, 10.0) = 3.5;
uniform float glow_gain : hint_range(1.0, 8.0) = 2.2;
uniform vec3 ambient_tint : source_color = vec3(0.6, 0.85, 1.0);
uniform float ambient_level : hint_range(0.0, 1.0) = 0.04;
// Deriva da amostragem: a fumaça da foto escorrega devagar, senão o vulto
// parece um recorte de papelão parado no ar.
uniform float boil : hint_range(0.0, 0.05) = 0.006;

void fog() {
	vec3 local_pos = UVW - vec3(0.5);

	// A foto é projetada na face da caixa. V invertido porque a textura cresce
	// para baixo e o volume cresce para cima.
	vec2 uv = vec2(UVW.x, 1.0 - UVW.y);

	// Ondula a amostragem: a fumaça respira em vez de ficar chapada.
	uv += vec2(
		sin(UVW.y * 11.0 + TIME * 0.5) * boil,
		cos(UVW.x * 9.0 - TIME * 0.4) * boil
	);

	vec4 figura = texture(foto, uv);
	float massa = figura.a;

	// Fora da faixa útil em profundidade não há névoa: é o que dá espessura à
	// laje sem deixar a caixa aparecer.
	float fatia = 1.0 - smoothstep(espessura * 0.55, espessura, abs(local_pos.z));
	float presente = 1.0 - step(massa, corte);

	// A franja sai da própria imagem: três amostras deslocadas em UV, como a
	// aberração de uma lente. Onde as três concordam a cor se cancela.
	float red = texture(foto, uv + vec2(aberration, 0.0)).a;
	float green = massa;
	float blue = texture(foto, uv - vec2(aberration, 0.0)).a;
	float nucleo = min(red, min(green, blue));
	vec3 rasgo = (vec3(red, green, blue) - vec3(nucleo)) * fringe_gain;

	// Luz fraca da sala não acenderia franja nenhuma, então o ambiente entra
	// como matiz com piso de brilho, e não como intensidade crua.
	vec3 aceso = rasgo * ambient_tint * (0.30 + ambient_level * 4.0);

	DENSITY = densidade * massa * fatia * presente;
	// A foto já traz onde é preto e onde é branco: o escuro absorve a luz da
	// sala, o claro espalha. Não há cor inventada aqui.
	ALBEDO = figura.rgb;
	EMISSION = aceso * glow_gain * fatia * presente;
}
