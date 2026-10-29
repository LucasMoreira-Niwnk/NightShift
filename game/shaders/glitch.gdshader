// ==============================================================================
// NIGHTSHIFT — SHADER DE GLITCH PROCEDURAL & QUEBRA DIGITAL
// ==============================================================================
// FAMÍLIA: Pós-Processamento & Shaders (res://shaders/glitch.gdshader)
// APLICAÇÃO:
//   Controlado via parâmetro 'intensity' (0.0 = desligado, 1.0 = colapso total).
//   Ideal para animar com Tween durante aparições da entidade ou falhas no sistema.
// ==============================================================================
shader_type canvas_item;

// Digital glitch / corruption effect
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float block_size : hint_range(1.0, 64.0) = 16.0;
uniform float color_drift : hint_range(0.0, 0.1) = 0.01;
uniform float line_shift : hint_range(0.0, 0.1) = 0.02;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.1;
uniform float aberration_amount : hint_range(0.0, 0.05) = 0.01;
uniform bool enable_block_glitch = true;
uniform bool enable_line_shift = true;
uniform bool enable_color_noise = true;

// Pseudo-random hash
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash_time(vec2 p, float t) {
	return hash(p + vec2(floor(t * 10.0)));
}

void fragment() {
	vec2 uv = UV;
	float time_val = TIME;

	// Block displacement
	if (enable_block_glitch && intensity > 0.1) {
		vec2 block = floor(uv * block_size) / block_size;
		float block_noise = hash_time(block, time_val);
		if (block_noise < intensity * 0.3) {
			float shift = (hash_time(block + 0.5, time_val) - 0.5) * line_shift * intensity * 10.0;
			uv.x += shift;
		}
	}

	// Horizontal line shift
	if (enable_line_shift) {
		float line_y = floor(uv.y * 200.0);
		float line_noise = hash_time(vec2(line_y, 0.0), time_val);
		if (line_noise < intensity * 0.15) {
			uv.x += (hash_time(vec2(line_y, 1.0), time_val) - 0.5) * line_shift * intensity * 5.0;
		}
	}

	// Chromatic aberration glitch
	float r_offset = aberration_amount * intensity * sin(time_val * 30.0);
	float b_offset = -aberration_amount * intensity * cos(time_val * 25.0);

	vec4 col;
	col.r = texture(TEXTURE, vec2(uv.x + r_offset, uv.y)).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, vec2(uv.x + b_offset, uv.y)).b;
	col.a = texture(TEXTURE, uv).a;

	// Color noise
	if (enable_color_noise) {
		float noise = hash(uv * 1000.0 + time_val) * noise_amount * intensity;
		col.rgb += vec3(noise) - vec3(noise_amount * intensity * 0.5);
	}

	// Color channel drift (red/cyan split)
	if (intensity > 0.5) {
		float drift = color_drift * (intensity - 0.5) * 2.0;
		float drift_noise = hash_time(vec2(floor(uv.y * 50.0), 0.0), time_val);
		if (drift_noise < 0.3) {
			col.r = texture(TEXTURE, vec2(uv.x + drift, uv.y)).r;
			col.b = texture(TEXTURE, vec2(uv.x - drift, uv.y)).b;
		}
	}

	// Occasional total corruption blocks
	if (intensity > 0.7) {
		vec2 big_block = floor(uv * 8.0) / 8.0;
		float corrupt = hash_time(big_block, time_val * 0.5);
		if (corrupt < (intensity - 0.7) * 0.5) {
			col.rgb = vec3(hash(big_block + time_val));
		}
	}

	COLOR = col;
}
