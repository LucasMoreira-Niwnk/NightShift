# 🎮 NIGHTSHIFT — Arquitetura de HUDs & Guia de Integração para a Equipe

> **Branch:** `feature/huds-nightshift`  
> **Compatibilidade:** Godot 4.0.stable / Renderizador GL Compatibility (`gl_compatibility`)

---

## 🏛️ Visão Geral & Famílias de Arquivos

Para manter o projeto modular, sem sobrecarregar o `chapter_ui.gd` nem alterar o código existente do jogo antes da aprovação da equipe, todos os recursos foram adicionados em três namespaces isolados:

1. **`game/shaders/`** — Efeitos analógicos e de corrupção visual.
2. **`game/scenes/huds/`** — Cenas visuais completas e independentes.
3. **`game/scripts/huds/`** — Lógica, sinais e controles das interfaces.

```
game/
├── scenes/
│   ├── main.tscn                     # [Existente] Cena principal do jogo
│   └── huds/                         # [Novo] Cenas de HUD modulares
│       ├── camera_feed.tscn          # Monitor reutilizável de câmera
│       ├── hud_cctv.tscn             # HUD CCTV Retrô (Mesa de segurança)
│       ├── hud_dos.tscn              # Terminal DOS de texto interativo
│       ├── hud_minimal.tscn          # HUD de exploração limpo (1ª pessoa)
│       ├── hud_tablet.tscn           # Tablet com planta baixa 2D e checklist
│       ├── hud_contaminated.tscn     # MÊMESIS Corrompido (Ato IV e V)
│       └── main_hud_demo.tscn        # Cena de teste e validação de HUDs
├── scripts/
│   ├── chapter_ui.gd                 # [Existente] UI atual do Capítulo 1
│   └── huds/                         # [Novo] Scripts GDScript dos HUDs
│       ├── camera_feed.gd
│       ├── hud_cctv.gd
│       ├── hud_dos.gd
│       ├── hud_minimal.gd
│       ├── hud_tablet.gd
│       ├── hud_contaminated.gd
│       └── main_hud_demo.gd
└── shaders/                          # [Novo] Shaders de pós-processamento
    ├── crt.gdshader                  # Curvatura CRT, aberração e vinheta
    ├── scanlines.gdshader            # Linhas horizontais e barra de varredura
    ├── glitch.gdshader               # Distorção de blocos e interferência
    └── static_noise.gdshader         # Estática analógica de câmera
```

---

## 🧪 Como Testar Imediatamente

No Godot Editor, abra a cena de teste:
`res://scenes/huds/main_hud_demo.tscn` e pressione **F6**.

Nesta cena é possível:
1. Alternar entre os 5 estilos de interface com 1 clique nos botões inferiores.
2. Ligar/desligar a curvatura CRT e as scanlines analógicas.
3. Arrastar o slider de **Glitch Intensity** (0.00 a 1.00) para ver o sistema entrar em colapso digital.

---

## 🔌 Roteiro de Integração com o Jogo Existente

### 1. Integrar com o Computador da Sala de Segurança (`computer.gd`):
O monitor de segurança existente no jogo pode exibir `res://scenes/huds/hud_cctv.tscn` dentro do seu `SubViewport` de 640x360:
```gdscript
# No computer.gd:
@onready var cctv_ui = preload("res://scenes/huds/hud_cctv.tscn").instantiate()

func _ready() -> void:
    $SubViewport.add_child(cctv_ui)
    cctv_ui.ramal_called.connect(_on_ramal_called)
    cctv_ui.incident_reported.connect(_on_incident_reported)
```

### 2. Disparar Corrupção de MÊMESIS no Ato IV / V:
Quando Daniel descobrir que é uma cópia ou que MÊMESIS está assumindo o edifício:
```gdscript
func transicionar_para_mimesis() -> void:
    # 1. Glitch severo
    glitch_material.set_shader_parameter("intensity", 0.8)
    
    # 2. Troca para a interface corrompida
    cctv_ui.queue_free()
    var contam_ui = preload("res://scenes/huds/hud_contaminated.tscn").instantiate()
    $SubViewport.add_child(contam_ui)
```

---

## 🛡️ Instruções de Git para a Equipe

Esta implementação foi criada na branch isolada:
`feature/huds-nightshift`

### Para voltar à `main` (desfazer visualização):
```bash
git checkout main
```

### Para descartar completamente a branch (se não quiser usar):
```bash
git checkout main
git branch -D feature/huds-nightshift
```

### Para mesclar na `main` quando aprovado:
```bash
git checkout main
git merge feature/huds-nightshift
```

### Para enviar ao repositório remoto do GitHub:
```bash
git push -u origin feature/huds-nightshift
```


## Integração de gameplay — 28/10/2026

`hud_tablet.gd` usa o estado real do capítulo: dicas, notas lidas do checkpoint,
conteúdo original salvo em `flags.document_records`, mensagens e ocorrências.
`live_floor_map.gd` projeta X/Z no mapa dos dois pisos e exterior, com direção,
portas e lentes. O norte aponta para a esquerda para aproveitar a tela horizontal.
O seletor permite acompanhar o piso automaticamente ou consultar outro piso;
zoom centra na posição de Daniel. Tab/M e Esc devolvem o controle ao jogador.

O monitor usa `security_console.gd`, conectado ao backend existente de
`computer.gd`. Os três painéis usam imagens reais; a câmera selecionada reutiliza
o feed original e os outros dois usam viewports de 384×216, desligados fora do
terminal. CAM-04/05 respeitam o desbloqueio da rede. Reprodução, zoom, inspeções,
reflexo, interferência, relatórios e ações do capítulo 2 continuam ligados às regras
existentes. REPORTAR INCIDENTE abre os três tipos e fixa a câmera do reporte ao
abrir; cancelar não envia ocorrência. Os controles antigos ficam ocultos como
bindings de compatibilidade, sem uma segunda interface interativa na tela.

`computer.console.set_contaminated(active, message)` permite aos eventos
narrativos ativar a interface contaminada. O estágio 6 já a aciona, sem timers de
spoilers. O modo muda a cor, as mensagens e os rótulos sobre os feeds reais.
As cenas demo originais permanecem acessíveis por F1.

O grão global fica abaixo das interfaces de texto (camada 8), o monitor na 9,
documentos na 10 e tablet na 18. O monitor conserva suas próprias scanlines.
As placas usam `aged_sign.gd`/`aged_enamel.gdshader`: esmalte gasto, oxidação,
filete vermelho e parafusos, além da sinalização circular do estacionamento.

`tablet_console_tests.gd`, chamado pela suíte dos capítulos, verifica os dois
pisos, projeção de posição, notas reais, posse do input, seleção/cancelamento de
incidentes e ativação da interface contaminada. Capturas ficam em `.local/`.
