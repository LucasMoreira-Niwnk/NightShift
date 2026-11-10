extends RefCounted
# Preferências do jogador (controles e vídeo), separadas do checkpoint.
# O volume continua em user://audio.cfg, gravado por soundscape.gd.

const PATH := "user://settings.cfg"
const BASE_SENSITIVITY := 0.0025
const DEFAULTS := {
	"mouse_sensitivity": 1.0,
	"invert_y": false,
	"fullscreen": false,
	"pause_on_focus_loss": true,
	"light_culling": true,
	"static_shadows": false,
	"occlusion_culling": false,
	"shadow_range": 14.0,
	"light_cone_extra": 40.0,
	"prop_range": 14.0,
	"cctv_hz": 6.0,
}

static func load_all() -> Dictionary:
	var values: Dictionary = DEFAULTS.duplicate()
	var file := ConfigFile.new()
	if file.load(PATH) != OK: return values
	for key in DEFAULTS:
		var value = file.get_value("game", key, DEFAULTS[key])
		# Um valor de tipo inesperado (arquivo editado à mão) volta ao padrão.
		if typeof(value) == typeof(DEFAULTS[key]): values[key] = value
	values.mouse_sensitivity = clampf(values.mouse_sensitivity, 0.25, 2.5)
	return values

static func save_all(values: Dictionary) -> void:
	var file := ConfigFile.new()
	for key in DEFAULTS:
		file.set_value("game", key, values.get(key, DEFAULTS[key]))
	file.save(PATH)

static func apply(game: Node, values: Dictionary) -> void:
	if game.world != null and game.world.light_culling != null:
		game.world.light_culling.enabled = bool(values.light_culling)
		game.world.light_culling.static_shadows = bool(values.static_shadows)
		game.world.light_culling.shadow_range = float(values.shadow_range)
		game.world.light_culling.extra_angulo = float(values.light_cone_extra)
		game.world.light_culling.prop_range = float(values.prop_range)
		if game.world.is_inside_tree():
			game.world.get_viewport().use_occlusion_culling = bool(values.occlusion_culling)
	if game.computer != null:
		game.computer.feed_hz = float(values.cctv_hz)
	if game.player != null:
		game.player.sensitivity = BASE_SENSITIVITY * float(values.mouse_sensitivity)
		game.player.invert_y = bool(values.invert_y)
	# Testes automatizados nunca trocam o modo da janela de quem está rodando.
	if OS.get_cmdline_user_args().has("--smoke-test"): return
	var mode := DisplayServer.window_get_mode()
	var fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if bool(values.fullscreen) != fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
