extends CanvasLayer
# ==============================================================================
# NIGHTSHIFT — DESCONFORTO (base do nível de dificuldade)
# ==============================================================================
# Giro brusco de câmera (acima do limiar) dispara um rastro temporal curto e,
# opcionalmente, um pico de frametime. A dificuldade varia a intensidade, não a
# existência do efeito. Ajustável em tempo real no menu de pausa [Esc].
# ponytail: tudo em um nó só; separar quando houver um segundo gatilho.

const FPV_LAYER: int = preload("res://scripts/hand.gd").FPV_LAYER

const PRESETS := {
	"Leve": {"trail_alpha": 0.25, "trail_ms": 150.0, "threshold": 320.0, "chroma_only": false, "stutter": false, "stutter_ms": 10.0},
	"Médio": {"trail_alpha": 0.50, "trail_ms": 200.0, "threshold": 450.0, "chroma_only": false, "stutter": false, "stutter_ms": 12.0},
	"Intenso": {"trail_alpha": 0.70, "trail_ms": 250.0, "threshold": 450.0, "chroma_only": true, "stutter": true, "stutter_ms": 15.0},
}

var game: Node
# Chave de acessibilidade: desliga o sistema inteiro
var enabled := true
var trail_enabled := true
# Opacidade máxima do rastro (0.5 = metade da imagem anterior)
var trail_alpha := 0.5
# Janela de desconforto em milissegundos (150–250 ms é a faixa útil)
var trail_ms := 200.0
# Velocidade angular de disparo em graus/s (90° em 0,2 s = 450°/s)
var threshold := 450.0
var chroma_only := false
# Pico de frametime: experimental, atrasa a thread principal
var stutter_enabled := false
var stutter_ms := 12.0

var rect: ColorRect
# A mao e a lanterna (camada visual 2) sao redesenhadas por cima do rastro:
# presas a camera, elas nao deveriam arrastar junto com o cenario.
var hand_viewport: SubViewport
var hand_camera: Camera3D
var hand_rect: TextureRect
var hand_isolated := false
var last_yaw := 0.0
var last_pitch := 0.0
var trail_time := 0.0
var trail_offset := Vector2.ZERO
var last_speed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# abaixo de todo HUD (chapter_ui 10, minimal 15, tablet 18): o rastro borra
	# apenas o 3D. O CRT (25) ainda reamostra o conjunto depois.
	layer = 5
	rect = ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/discomfort_trail.gdshader")
	rect.material = material
	rect.hide()
	add_child(rect)
	build_hand_pass()
	apply_preset("Médio")

func build_hand_pass() -> void:
	hand_viewport = SubViewport.new()
	hand_viewport.transparent_bg = true
	hand_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	hand_viewport.handle_input_locally = false
	add_child(hand_viewport)
	hand_camera = Camera3D.new()
	# so a camada do braco: cenario, telas e CCTV ficam fora deste passe
	hand_camera.cull_mask = FPV_LAYER
	hand_camera.near = 0.03
	hand_viewport.add_child(hand_camera)
	hand_camera.current = true
	var over := CanvasLayer.new()
	# entre o rastro (5) e o HUD do capitulo (10)
	over.layer = 6
	add_child(over)
	hand_rect = TextureRect.new()
	hand_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hand_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_rect.texture = hand_viewport.get_texture()
	hand_rect.hide()
	over.add_child(hand_rect)

# ponytail: o passe extra custa um render de tela cheia, entao so existe
# durante a janela do rastro; fora dela a mao volta para a camera principal.
func set_hand_isolated(isolate: bool) -> void:
	if hand_isolated == isolate: return
	if game == null or game.player == null or game.player.camera == null: return
	var camera: Camera3D = game.player.camera
	hand_isolated = isolate
	if isolate:
		hand_viewport.world_3d = get_viewport().world_3d
		hand_viewport.size = Vector2i(get_viewport().get_visible_rect().size)
		hand_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		camera.cull_mask &= ~FPV_LAYER
		hand_rect.show()
		sync_hand_camera()
	else:
		hand_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		camera.cull_mask |= FPV_LAYER
		hand_rect.hide()

func sync_hand_camera() -> void:
	if game == null or game.player == null or game.player.camera == null: return
	var camera: Camera3D = game.player.camera
	hand_camera.fov = camera.fov
	hand_camera.global_transform = camera.global_transform

func apply_preset(name: String) -> void:
	var preset: Dictionary = PRESETS.get(name, PRESETS["Médio"])
	trail_alpha = preset.trail_alpha
	trail_ms = preset.trail_ms
	threshold = preset.threshold
	chroma_only = preset.chroma_only
	stutter_enabled = preset.stutter
	stutter_ms = preset.stutter_ms

func _process(delta: float) -> void:
	if delta <= 0.0: return
	if not enabled:
		trail_time = 0.0
		rect.hide()
		set_hand_isolated(false)
		return
	if not get_tree().paused:
		sample_camera(delta)
	advance_trail(delta)

func sample_camera(delta: float) -> void:
	if game == null or game.player == null: return
	var player: CharacterBody3D = game.player
	if player.camera == null: return
	var yaw: float = player.rotation.y
	var pitch: float = player.camera.rotation.x
	var d_yaw := wrapf(yaw - last_yaw, -PI, PI)
	var d_pitch := pitch - last_pitch
	last_yaw = yaw
	last_pitch = pitch
	last_speed = rad_to_deg(Vector2(d_yaw, d_pitch).length()) / delta
	if last_speed < threshold: return
	# Converte o giro do frame em deslocamento de tela: o rastro aponta de onde
	# a imagem veio, usando o FOV como largura angular da tela.
	var fov_rad: float = deg_to_rad(player.camera.fov)
	trail_offset = Vector2(d_yaw, -d_pitch) / maxf(fov_rad, 0.01)
	trail_offset = trail_offset.limit_length(0.25)
	trail_time = trail_ms / 1000.0
	if stutter_enabled:
		OS.delay_msec(int(stutter_ms))

func advance_trail(delta: float) -> void:
	if trail_time <= 0.0:
		rect.hide()
		set_hand_isolated(false)
		return
	trail_time = maxf(trail_time - delta, 0.0)
	var decay := trail_time / maxf(trail_ms / 1000.0, 0.001)
	if not trail_enabled:
		rect.hide()
		set_hand_isolated(false)
		return
	set_hand_isolated(true)
	sync_hand_camera()
	rect.material.set_shader_parameter("strength", trail_alpha * decay)
	rect.material.set_shader_parameter("offset", trail_offset)
	rect.material.set_shader_parameter("chroma_only", chroma_only)
	rect.show()

# Disparo manual para testar pelo menu, sem precisar girar a câmera.
func test_pulse() -> void:
	trail_offset = Vector2(0.08, 0.0)
	trail_time = trail_ms / 1000.0
	if stutter_enabled:
		OS.delay_msec(int(stutter_ms))
