// ==============================================================================
// NIGHTSHIFT — NUVEM QUE ESCAPA DO MÊMESIS
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/memesis_puff.gdshader)
// APLICAÇÃO:
//   material de cada FogVolume pequeno criado em scripts/memesis.gd, que move,
//   alimenta `life` e apaga cada nuvem no ciclo dela.
// AVISO DE COMPATIBILIDADE:
//   shader_type fog só existe no renderizador Forward+, que é o do projeto
//   desde a migração. O preset mobile continua em gl_compatibility, onde este
//   shader nem compila.
// OBJETIVO DO AGENTE:
//   A nuvem é fumaça BRANCA, não um anel de cor: o corpo tem ALBEDO claro e
//   espalha a luz da sala, como na referência. A iridescência vive só na borda
//   — os três canais amostram a esfera em raios ligeiramente diferentes, então
//   no miolo eles coincidem e a cor se cancela, e na casca discordam e nasce a
//   franja. Inverter isso (cor no meio) devolveria uma bola colorida, que é
//   justamente o que a referência não é.
// NOTA DE SHADER:
//   o processador `fog` proíbe `return`; os recortes são fatores 0/1.
// ==============================================================================
shader_type fog;

uniform float puff_density : hint_range(0.0, 10.0) = 2.6;
// Miolo claro da nuvem, onde a fumaça é sólida.
uniform float body_radius : hint_range(0.0, 0.5) = 0.17;
// Até onde ela se desfaz no ar.
uniform float edge_radius : hint_range(0.0, 0.5) = 0.46;
// Separação dos canais. Zero devolve uma nuvem branca sem iridescência.
uniform float aberration : hint_range(0.0, 0.3) = 0.085;
uniform float fringe_gain : hint_range(0.0, 10.0) = 4.5;
// Empurra a franja acima de 1.0 para disparar o glow do Environment.
uniform float glow_gain : hint_range(1.0, 8.0) = 2.4;
// Cor da fumaça em si: quase branca, levemente fria como na referência.
uniform vec3 smoke_color : source_color = vec3(0.82, 0.85, 0.90);
// Cor e intensidade da luz ambiente, enviadas por memesis.gd.
uniform vec3 ambient_tint : source_color = vec3(0.6, 0.85, 1.0);
uniform float ambient_level : hint_range(0.0, 1.0) = 0.04;
// 0 no nascimento, 1 na dissolução. O script avança isto.
uniform float life : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;

float plate(float distance_from_center, float offset) {
	return 1.0 - smoothstep(body_radius + offset, edge_radius + offset, distance_from_center);
}

void fog() {
	vec3 local_pos = UVW - vec3(0.5);
	float distance_from_center = length(local_pos);

	// Fora da esfera não sobra nada: é o que impede a caixa de aparecer.
	float inside = 1.0 - step(0.5, distance_from_center);

	// Entra cheia, vive, e some. A nuvem nunca aparece ou corta de uma vez.
	float born = smoothstep(0.0, 0.18, life);
	float gone = 1.0 - smoothstep(0.45, 1.0, life);
	float fade = born * gone;

	// A separação ferve, e cada nuvem ferve no seu tempo: sem a semente, todas
	// pulsariam juntas e o conjunto viraria um estrobo.
	float wobble = sin(TIME * 2.1 + seed * 6.283) * 0.012;
	float split = aberration + wobble;

	float red = plate(distance_from_center, split);
	float green = plate(distance_from_center, 0.0);
	float blue = plate(distance_from_center, -split);

	// Onde os três coincidem está o miolo: ali a cor se cancela e sobra branco.
	float core = min(red, min(green, blue));
	vec3 torn = (vec3(red, green, blue) - vec3(core)) * fringe_gain;

	// A luz fraca da sala não acenderia franja nenhuma, então o ambiente entra
	// como matiz com piso de brilho, e não como intensidade crua.
	vec3 lit = torn * ambient_tint * (0.30 + ambient_level * 4.0);

	DENSITY = puff_density * green * fade * inside;
	// Corpo branco: a nuvem espalha a luz da sala, ao contrário do núcleo.
	ALBEDO = smoke_color;
	// A iridescência só na casca, e some junto com a nuvem.
	EMISSION = lit * glow_gain * fade * inside;
}
