## ==============================================================================
## NIGHTSHIFT — ORQUESTRADOR CENTRAL & DEMO DE TESTES DE HUDS
## ==============================================================================
## FAMÍLIA: Gerenciador Central / Playground de Testes (res://scripts/huds/main_hud_demo.gd)
## RELACIONADOS:
##   - scenes/huds/main_hud_demo.tscn (Cena de teste do sistema)
##   - Todas as cenas de HUD em res://scenes/huds/
##   - Todos os shaders em res://shaders/
## OBJETIVO DO AGENTE:
##   Permite testar e validar todos os HUDs e pós-processamento antes de plugar
##   no Player 3D ou no Computer da sala de segurança.
## ==============================================================================
extends Control

@onready var hud_container: Control = $HUDLayer/HUDContainer
@onready var post_processing: ColorRect = $ShaderLayer/PostProcessRect
@onready var scanline_layer: ColorRect = $ShaderLayer/ScanlinesRect

@onready var btn_cctv: Button = $UIControls/VBox/Tabs/BtnCCTV
@onready var btn_dos: Button = $UIControls/VBox/Tabs/BtnDOS
@onready var btn_min: Button = $UIControls/VBox/Tabs/BtnMinimal
@onready var btn_tab: Button = $UIControls/VBox/Tabs/BtnTablet
@onready var btn_contam: Button = $UIControls/VBox/Tabs/BtnContaminated

@onready var check_crt: CheckBox = $UIControls/VBox/Shaders/CheckCRT
@onready var check_scan: CheckBox = $UIControls/VBox/Shaders/CheckScanlines
@onready var slider_glitch: HSlider = $UIControls/VBox/Shaders/SliderGlitch
@onready var glitch_val_label: Label = $UIControls/VBox/Shaders/GlitchValLabel

var hud_cctv_scene = preload("res://scenes/huds/hud_cctv.tscn")
var hud_dos_scene = preload("res://scenes/huds/hud_dos.tscn")
var hud_minimal_scene = preload("res://scenes/huds/hud_minimal.tscn")
var hud_tablet_scene = preload("res://scenes/huds/hud_tablet.tscn")
var hud_contam_scene = preload("res://scenes/huds/hud_contaminated.tscn")

var current_hud_node: Node = null
var crt_mat: ShaderMaterial
var scan_mat: ShaderMaterial
var glitch_mat: ShaderMaterial

func _ready() -> void:
	_init_shaders()
	_connect_ui()
	_switch_hud(0)

func _init_shaders() -> void:
	var crt_shader = load("res://shaders/crt.gdshader")
	if crt_shader and post_processing:
		crt_mat = ShaderMaterial.new()
		crt_mat.shader = crt_shader
		post_processing.material = crt_mat

	var scan_shader = load("res://shaders/scanlines.gdshader")
	if scan_shader and scanline_layer:
		scan_mat = ShaderMaterial.new()
		scan_mat.shader = scan_shader
		scanline_layer.material = scan_mat

	var g_shader = load("res://shaders/glitch.gdshader")
	if g_shader:
		glitch_mat = ShaderMaterial.new()
		glitch_mat.shader = g_shader

func _connect_ui() -> void:
	btn_cctv.pressed.connect(func(): _switch_hud(0))
	btn_dos.pressed.connect(func(): _switch_hud(1))
	btn_min.pressed.connect(func(): _switch_hud(2))
	btn_tab.pressed.connect(func(): _switch_hud(3))
	btn_contam.pressed.connect(func(): _switch_hud(4))

	check_crt.toggled.connect(func(val): post_processing.visible = val)
	check_scan.toggled.connect(func(val): scanline_layer.visible = val)

	slider_glitch.value_changed.connect(_on_glitch_slider_changed)

func _switch_hud(index: int) -> void:
	if current_hud_node:
		current_hud_node.queue_free()

	match index:
		0: current_hud_node = hud_cctv_scene.instantiate()
		1: current_hud_node = hud_dos_scene.instantiate()
		2: current_hud_node = hud_minimal_scene.instantiate()
		3: current_hud_node = hud_tablet_scene.instantiate()
		4: current_hud_node = hud_contam_scene.instantiate()

	if current_hud_node:
		hud_container.add_child(current_hud_node)

func _on_glitch_slider_changed(val: float) -> void:
	glitch_val_label.text = "%.2f" % val
	if crt_mat:
		crt_mat.set_shader_parameter("chromatic_aberration", val * 5.0)
		crt_mat.set_shader_parameter("flicker_intensity", val * 0.1)

func trigger_scare_glitch() -> void:
	var tween = create_tween()
	tween.tween_method(func(v): slider_glitch.value = v, 0.0, 1.0, 0.15)
	tween.tween_interval(0.4)
	tween.tween_method(func(v): slider_glitch.value = v, 1.0, 0.0, 0.5)
