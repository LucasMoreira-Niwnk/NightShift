// ==============================================================================
// NIGHTSHIFT — OLHOS DO MÊMESIS
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/memesis_olhos.gdshader)
// APLICAÇÃO:
//   material dos dois quads montados por scripts/memesis_olhos.gd.
// OBJETIVO DO AGENTE:
//   Dois pontos vermelhos acesos dentro da névoa preta. São a única coisa no
//   vulto que tem direção: tudo mais lê igual de qualquer ângulo, e é o olhar
//   que diz que a coisa sabe onde você está.
//   O brilho é emissivo e passa de 1.0 para o glow do Environment morder só
//   ele — o ponto sangra no ar sem precisar de luz na cena.
//   Não escreve profundidade: os olhos moram dentro da coluna de névoa, e com
//   depth_draw a própria névoa os apagaria.
// ==============================================================================
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

uniform vec3 cor : source_color = vec3(1.0, 0.09, 0.05);
// Baixa de propósito: com blend_add e o glow do Environment por cima, valores
// altos estouram num borrão que toma a tela e os dois pontos viram um só.
uniform float intensidade : hint_range(0.0, 10.0) = 1.5;
// Fração central chapada, antes do brilho começar a cair.
// Miolo apertado: quanto maior, mais larga a brasa e mais ela sangra.
uniform float miolo : hint_range(0.0, 0.9) = 0.10;
uniform float piscar : hint_range(0.0, 1.0) = 0.22;
uniform float seed = 0.0;

void vertex() {
	// Billboard: o ponto nunca mostra o próprio quad de perfil. O nó pai é que
	// mantém o par lado a lado; aqui só se garante que cada ponto fique redondo.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX[0] *= length(MODEL_MATRIX[0]);
	MODELVIEW_MATRIX[1] *= length(MODEL_MATRIX[1]);
	MODELVIEW_MATRIX[2] *= length(MODEL_MATRIX[2]);
}

void fragment() {
	float raio = length(UV - vec2(0.5)) * 2.0;

	// Miolo chapado e queda suave até sumir: sem a queda o olho vira um disco
	// de contorno visível em vez de uma brasa.
	float brasa = 1.0 - smoothstep(miolo, 1.0, raio);
	// Ao quadrado duas vezes: a queda fica muito mais abrupta, e o ponto para
	// de virar um halo largo quando o glow entra por cima.
	brasa *= brasa;
	brasa *= brasa;

	// Tremor leve e fora de compasso entre os dois olhos: parados, os pontos
	// leem como LED; tremendo, leem como algo vivo olhando.
	float tremor = 1.0 - piscar * (0.5 + 0.5 * sin(TIME * 2.3 + seed * 6.283));

	// A cor vai no ALBEDO, que em `unshaded` é o que de fato sai na tela.
	// Deixá-la só no EMISSION dependia de o modo unshaded somar emissão, e era
	// aposta — com blend_add o ALBEDO acende sozinho.
	vec3 brasa_acesa = cor * brasa * intensidade * tremor;
	ALBEDO = brasa_acesa;
	// Repetida no EMISSION para passar do limiar do glow e sangrar no ar.
	EMISSION = brasa_acesa;
	ALPHA = brasa;
}
