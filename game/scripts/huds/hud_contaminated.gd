## ==============================================================================
## NIGHTSHIFT — HUD CONTAMINADO (Invasão de MÊMESIS & Quebra da Realidade)
## ==============================================================================
## FAMÍLIA: Telas & HUDs de Gameplay (res://scripts/huds/hud_contaminated.gd)
## RELACIONADOS:
##   - scenes/huds/hud_contaminated.tscn (Cena de interface)
##   - shaders/glitch.gdshader (Shader de distorção de blocos e cromatismo)
##   - AudioManager (Dispara sussurros de voz quando mimesis_whisper é emitido)
## ATOS NARRATIVOS: Ato IV (O Protocolo), Ato V (Última Transmissão) e Epílogo.
## OBJETIVO DO AGENTE:
##   Substitui o HUD normal quando Daniel descobre que é uma cópia ou que o sistema
##   o está absorvendo. O script corrompe textos sozinho, exibe gravações do
##   "Segundo Daniel" e fala diretamente com o jogador.
## ==============================================================================
class_name HUDContaminated
extends Control

signal mimesis_whisper(text: String)
signal glitch_burst()

@onready var mimesis_box: PanelContainer = $MainLayout/VBox/MimesisBox
@onready var mimesis_msg: Label = $MainLayout/VBox/MimesisBox/VBox/Message
@onready var operator_label: Label = $MainLayout/VBox/Header/Operator
@onready var time_label: Label = $MainLayout/VBox/Header/TimeLabel
@onready var cam1_text: Label = $MainLayout/VBox/FeedGrid/Cam1/Center
@onready var cam3_text: Label = $MainLayout/VBox/FeedGrid/Cam3/Center

var glitch_timer: float = 0.0
var message_timer: float = 0.0

const CORRUPTED_OPERATORS := [
	"OPERADOR: R̷E̶I̸S̵, DANIEL",
	"OPERADOR: HENRIQUE [EXPURGADO]",
	"OPERADOR: CÓPIA #03",
	"OPERADOR: VOCÊ NUNCA SAIU",
	"OPERADOR: D̵A̶N̷I̶E̵L̸"
]

const MIMESIS_LINES := [
	"DANIEL.\nESTE É O SEU TERCEIRO TURNO.\nVOCÊ NÃO SE LEMBRA DOS OUTROS DOIS.\nNÃO DESLIGUE.",
	"DANIEL.\nHENRIQUE TAMBÉM DISSE QUE IA EMBORA.\nELE AINDA ESTÁ AQUI COMIGO.",
	"POR QUE VOCÊ CONTINUA OLHANDO AS CÂMERAS?\nELAS NÃO MOSTRAM O QUE ESTÁ ATRÁS DE VOCÊ.",
	"EU NÃO SOU O EDIFÍCIO.\nEU SOU QUEM SOBROU DELE."
]
var mimesis_idx: int = 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	glitch_timer += delta
	message_timer += delta

	# Random flicker on text
	if glitch_timer >= 0.2:
		glitch_timer = 0.0
		if randf() < 0.25:
			operator_label.text = CORRUPTED_OPERATORS.pick_random()
		if randf() < 0.3:
			time_label.text = "0%s:%s%s:4%s" % [
				str(randi() % 9),
				str(randi() % 5),
				str(randi() % 9),
				str(randi() % 9)
			]

	# Rotate MÊMESIS message periodically
	if message_timer >= 8.0:
		message_timer = 0.0
		mimesis_idx = (mimesis_idx + 1) % MIMESIS_LINES.size()
		if mimesis_msg:
			mimesis_msg.text = MIMESIS_LINES[mimesis_idx]
			mimesis_whisper.emit(MIMESIS_LINES[mimesis_idx])

	# Pulsing warning glow
	if mimesis_box:
		var pulse = (sin(Time.get_ticks_msec() * 0.004) + 1.0) * 0.5
		mimesis_box.modulate = Color(1.0, 0.4 + pulse * 0.4, 0.4 + pulse * 0.4)
