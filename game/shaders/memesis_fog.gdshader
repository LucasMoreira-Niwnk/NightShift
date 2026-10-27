// ==============================================================================
// NIGHTSHIFT — COLUNA DE FUMAÇA DO MÊMESIS
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/memesis_fog.gdshader)
// APLICAÇÃO:
//   material do FogVolume criado em scripts/memesis.gd, que alimenta
//   ambient_tint e ambient_level a cada quadro a partir do Environment.
// AVISO DE COMPATIBILIDADE:
//   shader_type fog só existe no renderizador Forward+, que é o do projeto
//   desde a migração. O preset mobile continua em gl_compatibility, onde este
//   shader nem compila — o script avisa no console em vez de fingir que acendeu.
// OBJETIVO DO AGENTE:
//   O miolo é um buraco: densidade alta e ALBEDO preto, então ele absorve a luz
//   da sala em vez de espalhá-la. Não é fumaça clara — é a ausência de algo.
//   O que escapa fica em volta, num halo fino, e é só ali que mora a cor: os
//   três canais amostram o cilindro em raios ligeiramente diferentes, então
//   onde os três coincidem a cor se cancela (miolo preto) e onde discordam
//   nasce a franja. A franja é tingida pela luz ambiente da cena, não por uma
//   cor fixa — o vulto reflete o lugar onde está, mesmo sem refletir nada.
// ==============================================================================
shader_type fog;

// Densidade no núcleo do cilindro.
uniform float core_density : hint_range(0.0, 10.0) = 6.0;
// Raio do cilindro interno denso, em fração da caixa.
uniform float core_radius : hint_range(0.0, 0.5) = 0.16;
// Limite onde a fumaça se dissipa por completo.
uniform float edge_radius : hint_range(0.0, 0.5) = 0.46;
// Separação dos canais, em fração do raio. Zero devolve um halo sem cor.
uniform float aberration : hint_range(0.0, 0.3) = 0.07;
uniform float fringe_gain : hint_range(0.0, 8.0) = 3.0;
// Cor e intensidade da luz ambiente, enviadas por memesis.gd.
uniform vec3 ambient_tint : source_color = vec3(0.6, 0.85, 1.0);
uniform float ambient_level : hint_range(0.0, 1.0) = 0.04;
// Fervura da franja: sem isso a separação assenta e vira um anel parado.
uniform float boil : hint_range(0.0, 0.2) = 0.02;
// Empurra a franja acima de 1.0 para disparar o glow do Environment.
uniform float glow_gain : hint_range(1.0, 8.0) = 3.2;

// Perfil do cilindro num raio deslocado. É amostrar isto três vezes, uma por
// canal, que gera a aberração — a mesma ideia do memesis.gdshader das fagulhas.
float plate(float distance_from_center, float offset) {
	return 1.0 - smoothstep(core_radius + offset, edge_radius + offset, distance_from_center);
}

void fog() {
	// UVW vem em 0..1; centralizar deixa o eixo do cilindro no meio da caixa.
	vec3 local_pos = UVW - vec3(0.5);

	// Só a distância horizontal importa: o cilindro é infinito na vertical.
	float distance_from_center = length(local_pos.xz);

	// Fora do raio máximo não sobra nada: é o que recorta o cilindro na caixa.
	// Sem `if` com return: o processador `fog` proíbe return, e o compilador
	// recusa o shader inteiro. Um fator 0/1 faz o mesmo recorte.
	float inside = 1.0 - step(edge_radius, distance_from_center);

	// A separação ferve devagar e fora de fase ao longo da coluna, então a
	// franja nunca assenta num anel desenhado.
	float wobble = sin(TIME * 1.7 + local_pos.y * 9.0) * boil;
	float split = aberration + wobble;

	float red = plate(distance_from_center, split);
	float green = plate(distance_from_center, 0.0);
	float blue = plate(distance_from_center, -split);

	// Onde os três se sobrepõem está o miolo: ali a cor se cancela.
	float core = min(red, min(green, blue));
	vec3 torn = (vec3(red, green, blue) - vec3(core)) * fringe_gain;

	// A luz fraca da sala (energia 0.04) não acenderia franja nenhuma, então o
	// ambiente entra como matiz com um piso de brilho, e não como intensidade
	// crua: o vulto puxa a cor do lugar sem sumir num corredor escuro.
	vec3 lit = torn * ambient_tint * (0.30 + ambient_level * 4.0);

	DENSITY = core_density * (core + (1.0 - core) * green * 0.35) * inside;
	// O corpo não devolve luz: o miolo é um buraco preto na névoa da sala.
	ALBEDO = vec3(0.0);
	// Só o que escapa do miolo tem cor, e ela fica em volta dele. O ganho joga
	// a franja acima de 1.0 para o glow do Environment morder só ela, e não a
	// sala inteira — é daí que vem o bloom ao redor do vulto.
	EMISSION = lit * (1.0 - core) * inside * glow_gain;
}
