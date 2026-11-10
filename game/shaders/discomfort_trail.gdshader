// ==============================================================================
// NIGHTSHIFT — RASTRO DE DESCONFORTO (Ghosting direcional)
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/discomfort_trail.gdshader)
// APLICAÇÃO:
//   ColorRect de tela cheia abaixo do CRT. O script discomfort.gd dirige
//   `strength` e `offset` a partir da velocidade angular da câmera.
// ponytail: aproxima o acúmulo do frame anterior amostrando o frame atual ao
// longo do giro — durante uma virada rápida as duas imagens coincidem. Acúmulo
// real exigiria ping-pong de SubViewport; trocar se o rastro parecer curto.
// ==============================================================================
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
// 0 = imagem limpa, 1 = rastro na opacidade máxima
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// Deslocamento em UV por amostra (direção do giro)
uniform vec2 offset = vec2(0.0);
// Rastro só em vermelho/azul: vira aberração cromática dinâmica
uniform bool chroma_only = false;

const int SAMPLES = 6;

void fragment() {
	vec4 base = texture(screen_tex, UV);
	vec3 trail = vec3(0.0);
	float weight_total = 0.0;
	for (int i = 1; i <= SAMPLES; i++) {
		float step_ratio = float(i) / float(SAMPLES);
		float weight = 1.0 - step_ratio;
		trail += texture(screen_tex, clamp(UV + offset * step_ratio, vec2(0.0), vec2(1.0))).rgb * weight;
		weight_total += weight;
	}
	trail /= max(weight_total, 0.0001);
	vec3 mixed = mix(base.rgb, trail, strength);
	if (chroma_only) {
		// o verde segue nítido: os fantasmas se descolam em vermelho e azul
		mixed.g = base.g;
	}
	COLOR = vec4(mixed, 1.0);
}
