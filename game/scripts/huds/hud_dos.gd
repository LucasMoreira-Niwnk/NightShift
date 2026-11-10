## ==============================================================================
## NIGHTSHIFT — TERMINAL DOS / LINHA DE COMANDO RETRÔ
## ==============================================================================
## FAMÍLIA: Telas & HUDs de Gameplay (res://scripts/huds/hud_dos.gd)
## RELACIONADOS:
##   - scenes/huds/hud_dos.tscn (Cena de interface)
##   - shaders/crt.gdshader (Filtro essencial para tela monocromática verde)
## ATOS NARRATIVOS: Ato I, Ato II (Restauração do painel técnico e rede).
## OBJETIVO DO AGENTE:
##   Terminal de texto operado pelo jogador. Útil para puzzles onde o jogador
##   precisa consultar 'historico', digitar códigos ou enviar ocorrências formais.
##   Conecte o sinal 'command_executed(cmd, response)' para avançar objetivos de puzzle.
## ==============================================================================
class_name HUDDOS
extends Control

signal command_executed(cmd: String, response: String)

@onready var output_label: RichTextLabel = $Margin/VBox/OutputBox
@onready var input_line: LineEdit = $Margin/VBox/InputContainer/CommandLine
@onready var cursor_rect: ColorRect = $Margin/VBox/InputContainer/Cursor

var blink_timer: float = 0.0

const BANNER := """[color=#00aa44]╔══════════════════════════════════════════════════════════╗
║  VESPER SECURITY SYSTEM v2.7.1          BUILD 1997.03  ║
║  Licensed to: VESPER ADMINISTRATIVE GROUP              ║
╚══════════════════════════════════════════════════════════╝[/color]

[color=#00ff88]SISTEMA INICIALIZADO.............. [OK]
REDE DE CÂMERAS.................. [OK]
ALIMENTAÇÃO PRINCIPAL............ [OK]
[color=#ffff44]SUBSOLO.......................... [OFFLINE][/color]
AUTENTICAÇÃO..................... [OK][/color]

[color=#00cc66]OPERADOR: REIS, Daniel
TURNO: 00:00 - 06:00   |   STATUS: EM RONDA
INCIDENTES REGISTRADOS: 1   |   PENDENTES: 1[/color]

[color=#005522]───────── LOG DE EVENTOS ─────────[/color]
[color=#00aa55][00:00:03] Operador autenticado via crachá #4417
[00:01:15] CAM-01 verificada — sem anomalias
[00:01:22] CAM-02 verificada — sem anomalias
[color=#ffff44][00:01:30] CAM-03 — falha de sincronização detectada[/color]
[00:08:44] Ronda iniciada — Recepção
[00:12:11] Porta de emergência verificada — trancada
[color=#ffff44][00:14:22] Incidente #0047 — Objeto deslocado (CAM-03)[/color]
[color=#ff4444][00:14:22] ⚠ Incidente #0044 apresenta dados idênticos[/color][/color]
"""

func _ready() -> void:
	if output_label:
		output_label.bbcode_enabled = true
		output_label.text = BANNER
	if input_line:
		input_line.text_submitted.connect(_on_command_submitted)
		input_line.grab_focus()

func _process(delta: float) -> void:
	blink_timer += delta
	if blink_timer >= 0.5:
		blink_timer = 0.0
		if cursor_rect:
			cursor_rect.visible = !cursor_rect.visible

func _on_command_submitted(text: String) -> void:
	var cmd = text.strip_edges()
	input_line.clear()
	if cmd.is_empty():
		return

	_print_line("[color=#00ff88]> " + cmd + "[/color]")
	_handle_command(cmd.to_lower())

func _handle_command(cmd: String) -> void:
	var response := ""
	match cmd:
		"ajuda", "help", "?":
			response = "[color=#00aa55]Comandos disponíveis: cameras, reportar, ronda, historico, protocolo, mimesis, limpar[/color]"
		"cameras", "cam":
			response = """[color=#00ff88]STATUS DAS CÂMERAS:
- CAM-01 [RECEPÇÃO]: SINAL OK - [AO VIVO]
- CAM-02 [CORREDOR]: SINAL OK - [AO VIVO]
- CAM-03 [ARQUIVO]: FALHA DE SINCRONIZAÇÃO - [INSTÁVEL][/color]"""
		"reportar":
			response = "[color=#ffff44]Uso: reportar <cam> <tipo_anomalia>\nEx: reportar cam03 objeto_deslocado[/color]"
		"ronda":
			response = """[color=#00ff88]CHECKLIST DE RONDA:
[X] Recepção - Concluída
[X] Porta de Emergência - Verificada
[!] Setor de Arquivos - Pendente inspeção manual[/color]"""
		"historico":
			response = """[color=#00aa55]REGISTROS ANTERIORES:
- 3 DIAS ATRÁS: Operador REIS, D. - Turno encerrado irregularmente.
- 7 DIAS ATRÁS: Operador HENRIQUE - [REGISTRO EXPURGADO][/color]"""
		"protocolo":
			response = "[color=#00ff88]PROTOCOLO PADRÃO: Se avistar anomalia nas câmeras, NÃO investigue sozinho. Desligue o monitor e contate o supervisor.[/color]"
		"mimesis":
			response = "[color=#ff3333]MÍMESIS: \"DANIEL. VOCÊ PERGUNTOU POR MIM DA ÚLTIMA VEZ TAMBÉM.\"[/color]"
		"limpar", "cls", "clear":
			output_label.text = ""
			return
		_:
			response = "[color=#ff5555]Comando não reconhecido: '%s'. Digite 'ajuda' para comandos.[/color]" % cmd

	_print_line(response)
	command_executed.emit(cmd, response)

func _print_line(line: String) -> void:
	if output_label:
		output_label.append_text(line + "\n")
