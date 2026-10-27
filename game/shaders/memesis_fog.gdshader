// ==============================================================================
// NIGHTSHIFT — COLUNA DE FUMAÇA DO MÊMESIS
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/memesis_fog.gdshader)
// APLICAÇÃO:
//   material do FogVolume criado em scripts/memesis.gd.
// AVISO DE COMPATIBILIDADE:
//   shader_type fog só existe no renderizador Forward+, que é o do projeto
//   desde a migração. O preset mobile continua em gl_compatibility, onde este
//   shader nem compila — o script avisa no console em vez de fingir que acendeu.
// OBJETIVO DO AGENTE:
//   A névoa é um cilindro vertical: densa no miolo, vazando fraco para fora
//   até sumir de vez. Não é uma caixa de fumaça — o corte circular é o que
//   faz o vulto ler como coluna e não como bloco.
// ==============================================================================
shader_type fog;

// Densidade no núcleo do cilindro.
uniform float core_density : hint_range(0.0, 10.0) = 2.0;
// Raio do cilindro interno denso, em fração da caixa.
uniform float core_radius : hint_range(0.0, 0.5) = 0.35;
// Limite onde a fumaça se dissipa por completo.
uniform float edge_radius : hint_range(0.0, 0.5) = 0.5;

void fog() {
	// UVW vem em 0..1; centralizar deixa o eixo do cilindro no meio da caixa.
	vec3 local_pos = UVW - vec3(0.5);

	// Só a distância horizontal importa: o cilindro é infinito na vertical.
	float distance_from_center = length(local_pos.xz);

	// 1.0 no miolo, caindo suave até 0.0 na borda externa.
	float edge_fade = 1.0 - smoothstep(core_radius, edge_radius, distance_from_center);

	// Fora do raio máximo não sobra nada: é o que recorta o cilindro na caixa.
	if (distance_from_center > edge_radius) {
		DENSITY = 0.0;
	} else {
		DENSITY = core_density * edge_fade;
	}
}
