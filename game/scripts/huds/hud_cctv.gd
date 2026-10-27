## ==============================================================================
## NIGHTSHIFT — HUD CCTV RETRÔ (Mesa de Segurança do Turno)
## ==============================================================================
## FAMÍLIA: Telas & HUDs de Gameplay (res://scripts/huds/hud_cctv.gd)
## RELACIONADOS:
##   - scenes/huds/hud_cctv.tscn (Cena visual)
##   - scenes/huds/camera_feed.tscn / scripts/huds/camera_feed.gd (Filhos Cam1, Cam2, Cam3)
##   - shaders/crt.gdshader & scanlines.gdshader (Filtros visuais recomendados)
## ATOS NARRATIVOS: Ato I (O Primeiro Turno), Ato II e Ato III.
## OBJETIVO DO AGENTE:
##   Interface de monitoramento clássica. Controla o relógio mestre da ronda,
##   atualiza incidentes relatados (ex: cadeira deslocada na CAM-03) e emite
##   o sinal ramal_called quando Daniel atende o Ramal 000 do supervisor Augusto.
## ==============================================================================
class_name HUDCCTV
extends Control

signal incident_reported(incident_text: String)
signal camera_switched(cam_index: int)
signal ramal_called()

@onready var clock_label: Label = $MainLayout/VBox/Header/ClockLabel
@onready var cam1: CameraFeed = $MainLayout/VBox/FeedGrid/Cam1
@onready var cam2: CameraFeed = $MainLayout/VBox/FeedGrid/Cam2
@onready var cam3: CameraFeed = $MainLayout/VBox/FeedGrid/Cam3
@onready var incident_label: Label = $MainLayout/VBox/StatusBar/IncidentPanel/VBox/IncidentText
@onready var btn_ramal: Button = $MainLayout/VBox/ActionBar/BtnRamal

var elapsed_seconds: int = 1062 # 00:17:42
var clock_timer: float = 0.0
var pulse_timer: float = 0.0
var selected_cam: int = 1

func _ready() -> void:
	_setup_feeds()
	_update_clock()
	if btn_ramal:
		btn_ramal.pressed.connect(_on_ramal_pressed)

func _setup_feeds() -> void:
	if cam1:
		cam1.cam_name = "CAM-01"
		cam1.cam_location = "RECEPÇÃO"
		cam1.cam_status = "AO VIVO"
		cam1.feed_clicked.connect(func(_name): _select_cam(1))
	if cam2:
		cam2.cam_name = "CAM-02"
		cam2.cam_location = "CORREDOR"
		cam2.cam_status = "AO VIVO"
		cam2.feed_clicked.connect(func(_name): _select_cam(2))
	if cam3:
		cam3.cam_name = "CAM-03"
		cam3.cam_location = "ARQUIVO"
		cam3.cam_status = "INSTÁVEL"
		cam3.center_text = "⚠ FALHA DE SINCRONIZAÇÃO"
		cam3.feed_clicked.connect(func(_name): _select_cam(3))

func _process(delta: float) -> void:
	clock_timer += delta
	if clock_timer >= 1.0:
		clock_timer -= 1.0
		elapsed_seconds += 1
		_update_clock()

	# Pulse Ramal button
	pulse_timer += delta * 2.5
	if btn_ramal:
		var alpha = lerp(0.4, 1.0, (sin(pulse_timer) + 1.0) * 0.5)
		btn_ramal.modulate = Color(1.0, 1.0, 1.0, alpha)

func _update_clock() -> void:
	var h := int(elapsed_seconds / 3600.0)
	var m := int((elapsed_seconds % 3600) / 60.0)
	var s := elapsed_seconds % 60
	var time_str := "%02d:%02d:%02d" % [h, m, s]
	if clock_label:
		clock_label.text = time_str
	if cam1: cam1.set_timestamp(time_str)
	if cam2: cam2.set_timestamp(time_str)
	if cam3: cam3.set_timestamp(time_str)

func _select_cam(index: int) -> void:
	selected_cam = index
	camera_switched.emit(selected_cam)

func report_incident(text: String) -> void:
	if incident_label:
		incident_label.text = text
	incident_reported.emit(text)

func _on_ramal_pressed() -> void:
	ramal_called.emit()
