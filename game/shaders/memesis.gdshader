// ==============================================================================
// NIGHTSHIFT — SOPRO DO MÊMESIS (fumaça com aberração cromática extrema)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/memesis.gdshader)
// APLICAÇÃO:
//   material das partículas do vulto (scripts/memesis.gd). Cada partícula é um
//   quad virado para a câmera.
// OBJETIVO DO AGENTE:
//   A aberração é do próprio sopro, não da imagem atrás dele: o mesmo borrão é
//   amostrado três vezes, uma por canal, em posições diferentes. Onde os três
//   coincidem sobra o miolo preto; onde discordam, nasce a franja vermelha e
//   ciano. Assim o vulto aparece mesmo no escuro total, onde não há fundo para
//   distorcer. Empilhados, os sopros formam um corpo que nunca fecha o contorno.
// ==============================================================================
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform float aberration : hint_range(0.0, 0.5) = 0.07;
uniform float fringe_gain : hint_range(0.0, 6.0) = 1.6;
// Cada sopro sozinho e quase invisivel; o preto opaco nasce do empilhamento
// de dezenas deles. E o que faz a massa ler como fumaca e nao como disco.
uniform float density : hint_range(0.0, 1.0) = 0.97;
// Fracao chapada do miolo: quanto maior, mais corpo preto e menos franja.
uniform float core_radius : hint_range(0.0, 0.95) = 0.82;
uniform float boil : hint_range(0.0, 0.3) = 0.035;

// Cada sopro ferve fora de compasso: a semente vem da posicao da particula.
varying flat float seed;

float reach(vec2 uv, vec2 offset) {
	return clamp(length(uv - vec2(0.5) + offset) * 2.0, 0.0, 1.0);
}

// Forma do sopro, usada so na opacidade: cai suave ate zero, sem degrau, senao
// cada particula vira um disco de contorno visivel em vez de fumaca.
float body(vec2 uv) {
	float fade = 1.0 - reach(uv, vec2(0.0));
	return fade * fade * (3.0 - 2.0 * fade);
}

// Forma usada so na separacao de canais: tem um miolo chapado, onde os tres
// canais coincidem e a cor se cancela. E dai que vem o preto do corpo.
float plate(vec2 uv, vec2 offset) {
	return 1.0 - smoothstep(core_radius, 1.0, reach(uv, offset));
}

void vertex() {
	// Quad sempre de frente para a câmera, sem herdar a rotação do emissor.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX[0] *= length(MODEL_MATRIX[0]);
	MODELVIEW_MATRIX[1] *= length(MODEL_MATRIX[1]);
	MODELVIEW_MATRIX[2] *= length(MODEL_MATRIX[2]);
	seed = fract(sin(dot(MODEL_MATRIX[3].xyz, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void fragment() {
	// A separação dos canais ferve, então a franja nunca assenta.
	float wobble = sin(TIME * 2.6 + seed * 6.283) * boil;
	vec2 split = vec2(aberration + wobble, (aberration + wobble) * 0.35);

	float red = plate(UV, split);
	float green = plate(UV, vec2(0.0));
	float blue = plate(UV, -split);

	// Onde os três se sobrepõem está o miolo: ali a cor se cancela e fica preto.
	float core = min(red, min(green, blue));
	vec3 torn = (vec3(red, green, blue) - vec3(core)) * fringe_gain;

	// O corpo nao devolve luz nenhuma: unshaded, e o miolo e preto chapado.
	// A transparencia mora so na casca, onde o sopro se desfaz no ar.
	ALBEDO = torn;
	// O miolo precisa ser opaco de verdade: e ele que tapa a franja dos sopros
	// de tras, deixando so a da silhueta de fora. Sem isso, cada particula
	// mostra o proprio anel e a massa vira um cacho de argolas.
	ALPHA = clamp(body(UV) * 2.2, 0.0, 1.0) * density * COLOR.a;
}
