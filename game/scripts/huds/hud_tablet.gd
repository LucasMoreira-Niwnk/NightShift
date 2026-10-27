## ==============================================================================
## NIGHTSHIFT — TABLET DE SEGURANÇA (Planta Baixa & Checklist Móvel)
## ==============================================================================
## FAMÍLIA: Telas & HUDs de Gameplay (res://scripts/huds/hud_tablet.gd)
## RELACIONADOS:
##   - scenes/huds/hud_tablet.tscn (Cena de interface)
##   - Player.gd / InventorySystem (Item portátil inspecionado ao pressionar tecla Tab/M)
## ATOS NARRATIVOS: Ato II, Ato III e Ato IV.
## OBJETIVO DO AGENTE:
##   Equipamento portátil de ronda. Mostra a planta 2D do piso térreo com a posição
##   de Daniel em tempo real, gerencia o checklist de tarefas e dispara alertas
##   vermelhos com set_alert(true, "CAM-03: Objeto Deslocado").
## ==============================================================================
class_name HUDTablet
extends Control

signal task_toggled(task_name: String, completed: bool)

@onready var alert_panel: PanelContainer = $ContentMargin/HBox/RightCol/AlertPanel
@onready var player_marker: ColorRect = $ContentMargin/HBox/LeftCol/MapContainer/PlayerMarker

var pulse_timer: float = 0.0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pulse_timer += delta * 3.0
	if alert_panel:
		var alpha = lerp(0.6, 1.0, (sin(pulse_timer) + 1.0) * 0.5)
		alert_panel.modulate = Color(1.0, 1.0, 1.0, alpha)

	if player_marker:
		var glow = lerp(0.5, 1.0, (sin(pulse_timer * 1.5) + 1.0) * 0.5)
		player_marker.modulate = Color(1.0, 1.0, 1.0, glow)

func set_alert(active: bool, text: String = "") -> void:
	if alert_panel:
		alert_panel.visible = active
		if active and not text.is_empty():
			var label: Label = alert_panel.get_node_or_null("VBox/AlertText")
			if label: label.text = text
