// ==============================================================================
// NIGHTSHIFT — NÚCLEO DO MÊMESIS
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/memesis_fog.gdshader)
// APLICAÇÃO:
//   material do FogVolume central criado em scripts/memesis.gd.
// AVISO DE COMPATIBILIDADE:
//   shader_type fog só existe no renderizador Forward+, que é o do projeto
//   desde a migração. O preset mobile continua em gl_compatibility, onde este
//   shader nem compila — o script avisa no console em vez de fingir que acendeu.
// OBJETIVO DO AGENTE:
//   O núcleo é só buraco: um cilindro de 1 m de diâmetro, denso e com ALBEDO
//   preto, que absorve a luz da sala em vez de espalhá-la. Nenhuma cor mora
//   aqui — a aberração toda vive nas nuvens que escapam (memesis_puff.gdshader).
//   Essa divisão é o efeito: a silhueta é ausência, e só o que se desprende
//   dela tem cor.
// NOTA DE SHADER:
//   o processador `fog` proíbe `return`; o recorte do cilindro é um fator 0/1.
// ==============================================================================
shader_type fog;

uniform float core_density : hint_range(0.0, 20.0) = 9.0;
// Raio do cilindro preto, em fração da caixa. 0.5 preenche a caixa inteira,
// que é 1 m de largura: o preto vai até o diâmetro cheio, sem halo.
uniform float core_radius : hint_range(0.0, 0.5) = 0.5;
// Espessura da casca onde o preto se desfaz. Fina de propósito: borda dura
// viraria um tubo de contorno visível, borda larga devolveria o halo cinza.
uniform float edge_softness : hint_range(0.001, 0.2) = 0.045;

void fog() {
	// UVW vem em 0..1; centralizar deixa o eixo do cilindro no meio da caixa.
	vec3 local_pos = UVW - vec3(0.5);

	// Só a distância horizontal importa: o cilindro é infinito na vertical.
	float distance_from_center = length(local_pos.xz);

	float solid = 1.0 - smoothstep(core_radius - edge_softness, core_radius, distance_from_center);

	// As pontas também somem, senão a coluna termina em disco cortado no ar.
	float ends = 1.0 - smoothstep(0.34, 0.5, abs(local_pos.y));

	DENSITY = core_density * solid * ends;
	// Preto chapado: é isto que faz o vulto ler como ausência, não como fumaça.
	ALBEDO = vec3(0.0);
	EMISSION = vec3(0.0);
}
