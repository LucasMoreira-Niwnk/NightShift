## ==============================================================================
## NIGHTSHIFT — COMPONENTE DE CÂMERA DE SEGURANÇA (CameraFeed)
## ==============================================================================
## FAMÍLIA: Componentes Reutilizáveis (res://scripts/huds/camera_feed.gd)
## RELACIONADOS:
##   - scenes/huds/camera_feed.tscn (Cena de instância)
##   - scenes/huds/hud_cctv.tscn (Pai que consome e orquestra múltiplas câmeras)
##   - shaders/static_noise.gdshader (Efeito de perda de sinal analógico)
##   - shaders/glitch.gdshader (Efeito de corrupção de imagem na lente)
## OBJETIVO DO AGENTE:
##   Representa um feed único de câmera do Edifício Vesper. Use para mudar status
##   (AO VIVO, INSTÁVEL, SEM SINAL), disparar distorções em câmeras específicas,
##   e capturar cliques do jogador ao inspecionar uma sala.
## ==============================================================================
class_name SecurityCameraFeed
extends PanelContainer

signal feed_clicked(feed_name: String)

@export var cam_name: String = "CAM-01"
@export var cam_location: String = "RECEPÇÃO"
@export_enum("AO VIVO", "INSTÁVEL", "SEM SINAL", "GRAVAÇÃO?") var cam_status: String = "AO VIVO"
@export var center_text: String = ""
@export var is_glitching: bool = false

var label_title: Label
var label_status: Label
var label_timestamp: Label
var label_center: Label
var noise_rect: ColorRect
var glitch_material: ShaderMaterial
var static_material: ShaderMaterial

var blink_timer: float = 0.0
var internal_seconds: int = 1062 # 00:17:42

func _ready() -> void:
	custom_minimum_size = Vector2(280, 200)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_build_ui()
	_setup_materials()
	set_process(true)

func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.95)
	style.border_color = Color(0.12, 0.28, 0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var control_root := Control.new()
	control_root.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(control_root)

	noise_rect = ColorRect.new()
	noise_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noise_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	noise_rect.visible = false
	control_root.add_child(noise_rect)

	label_center = Label.new()
	label_center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_center.text = center_text
	label_center.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2, 0.8))
	control_root.add_child(label_center)

	label_title = Label.new()
	label_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	label_title.text = "● %s — %s" % [cam_name, cam_location]
	label_title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.53, 0.9))
	control_root.add_child(label_title)

	label_status = Label.new()
	label_status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_update_status_display()
	control_root.add_child(label_status)

	label_timestamp = Label.new()
	label_timestamp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	label_timestamp.text = _format_time(internal_seconds)
	label_timestamp.add_theme_color_override("font_color", Color(0.15, 0.6, 0.35, 0.8))
	control_root.add_child(label_timestamp)

	gui_input.connect(_on_gui_input)

func _setup_materials() -> void:
	var noise_shader = load("res://shaders/static_noise.gdshader")
	if noise_shader:
		static_material = ShaderMaterial.new()
		static_material.shader = noise_shader
		noise_rect.material = static_material

	var glitch_shader = load("res://shaders/glitch.gdshader")
	if glitch_shader:
		glitch_material = ShaderMaterial.new()
		glitch_material.shader = glitch_shader
		if is_glitching:
			material = glitch_material

func _process(delta: float) -> void:
	blink_timer += delta
	if blink_timer >= 0.5:
		blink_timer = 0.0
		if cam_status == "AO VIVO":
			label_status.visible = !label_status.visible
		elif cam_status == "INSTÁVEL":
			label_status.visible = !label_status.visible
			label_center.visible = !label_center.visible

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		feed_clicked.emit(cam_name)

func set_timestamp(time_str: String) -> void:
	if label_timestamp:
		label_timestamp.text = time_str

func set_status(new_status: String) -> void:
	cam_status = new_status
	_update_status_display()

func set_glitch(active: bool, intensity: float = 0.4) -> void:
	is_glitching = active
	if active and glitch_material:
		material = glitch_material
		glitch_material.set_shader_parameter("intensity", intensity)
	else:
		material = null

func show_static(active: bool) -> void:
	if noise_rect:
		noise_rect.visible = active

func _update_status_display() -> void:
	if not label_status:
		return
	label_status.visible = true
	match cam_status:
		"AO VIVO":
			label_status.text = "● AO VIVO"
			label_status.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		"INSTÁVEL":
			label_status.text = "⚠ INSTÁVEL"
			label_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
		"SEM SINAL":
			label_status.text = "✖ SEM SINAL"
			label_status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		"GRAVAÇÃO?":
			label_status.text = "◈ GRAVAÇÃO?"
			label_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.9))

func _format_time(sec: int) -> String:
	var h := int(sec / 3600.0)
	var m := int((sec % 3600) / 60.0)
	var s := sec % 60
	return "%02d:%02d:%02d" % [h, m, s]
