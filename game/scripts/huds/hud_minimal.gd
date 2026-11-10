## ==============================================================================
## NIGHTSHIFT — HUD MINIMALISTA (Exploração em 1ª Pessoa)
## ==============================================================================
## FAMÍLIA: Telas & HUDs de Gameplay (res://scripts/huds/hud_minimal.gd)
## RELACIONADOS:
##   - scenes/huds/hud_minimal.tscn (Cena de interface)
##   - Player.gd (Controlador do jogador em 1ª pessoa que atualiza prompts via RayCast)
## ATOS NARRATIVOS: Ativo durante todos os atos enquanto Daniel caminha pelos corredores.
## OBJETIVO DO AGENTE:
##   Interface ultra-limpa e não-intrusiva. Altere o texto de interação com
##   set_prompt("[ E ] Abrir porta"), altere bateria com set_battery(0..3)
##   e mantenha a imersão de terror intacta.
## ==============================================================================
class_name HUDMinimal
extends Control

@onready var clock_label: Label = $TopLeft/ClockLabel
@onready var prompt_label: Label = $BottomPrompt/PromptLabel
@onready var prompt_container: Control = $BottomPrompt
@onready var battery_dot1: ColorRect = $TopRight/BatteryDots/Dot1
@onready var battery_dot2: ColorRect = $TopRight/BatteryDots/Dot2
@onready var battery_dot3: ColorRect = $TopRight/BatteryDots/Dot3

var current_battery: int = 3
var prompt_alpha: float = 1.0

func _ready() -> void:
	set_prompt("[ E ] Examinar documento")
	set_battery(2)

func set_clock(time_str: String) -> void:
	if clock_label:
		clock_label.text = time_str

func set_prompt(text: String, visible_prompt: bool = true) -> void:
	if prompt_label:
		prompt_label.text = text
	if prompt_container:
		prompt_container.visible = visible_prompt

func set_battery(level: int) -> void:
	current_battery = clamp(level, 0, 3)
	if battery_dot1: battery_dot1.modulate.a = 0.9 if current_battery >= 1 else 0.2
	if battery_dot2: battery_dot2.modulate.a = 0.9 if current_battery >= 2 else 0.2
	if battery_dot3: battery_dot3.modulate.a = 0.9 if current_battery >= 3 else 0.2
