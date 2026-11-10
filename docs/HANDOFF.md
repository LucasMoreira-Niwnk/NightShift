# Registro de passagem entre agentes

Entradas mais recentes no topo. Cada uma diz o que mudou, por quê, o que foi validado de fato e o que fica para o próximo agente (Codex, Claude ou Lucas).

---

## 2026-11-05 (4) — Codex — integração para PR e regressões de colaboração

**Estado:** integração preparada na branch `codex/integracao-codex-claude`, com destino `feat/primeiro-ato-completo`. Preservados os commits locais, as edições manuais do cenário e as alterações documentadas pelo Claude. Não foi feita a refatoração ampla dos capítulos.

**Integração remota:** incorporado o commit do colega `09b5014` (poste com OmniLight3D, cúpula e bulbo). Em `game/scripts/building_exterior.gd`, a resolução mantém o poste Poly Haven e sua colisão, adapta a altura da luz/cúpula ao modelo importado e abre a base inferior da cúpula (`cap_bottom = false`) para não bloquear a luz. Não há poste procedural duplicado. Essa resolução passou por check/test; não foi inspecionada visualmente nesta rodada.

**Escopo publicado:** cenário editável e preservação das posições dos objetos interativos; salas de apoio, chaves, armário da TI e inventário; modelos CC0 de bancos/livros e ambientação do Claude; acabamento e parapeitos da escadaria; correções do Claude de portas, materiais, configurações, pausa e checkpoints. As cenas, scripts, licenças e documentação necessários seguem juntos para evitar referências ausentes.

**Cobertura acrescentada:** `game/scripts/collaboration_tests.gd`, chamado por `chapter_tests.gd`, exercita gravação com reserva, recuperação após truncamento deliberado do JSON principal, restauração de índices/seqüência de disjuntores/porta de rede como inteiros e bloqueio de fechamento com jogador no vão. Usa arquivos de teste isolados e restaura o estado ao final.

**Validação efetivamente executada após integrar:** `tools/godot.ps1 -Mode check` e `-Mode test` concluíram com código 0 no Godot 4.0.stable. Dez marcadores passaram, incluindo `COLLABORATION_TEST_OK`, `STAIR_FINISH_TEST_OK`, `PROP_LAYOUT_TEST_OK`, `EXPLORATION_TEST_OK`, `CHAPTER1_TEST_OK` e `CHAPTER2_TEST_OK`. Logs locais ignorados: `.local/pr-final-check.log` e `.local/pr-final-test.log`. O erro de parse JSON no teste é provocado para verificar a recuperação pela reserva; persistem os avisos conhecidos de shader/RID do FogVolume ao encerrar.

**Sugestões avaliadas / próximo trabalho:** separar persistência de `chapter.gd` (por exemplo `checkpoint.gd`) e menus/configurações de `chapter_ui.gd` antes do capítulo 3; centralizar entrada em ações do InputMap. Fazer em PR próprio, preservando comportamento e checkpoints. Uma alteração da altura das mesas exige reposicionar seus objetos apoiados. Modelos decorativos adicionais são uma tarefa posterior. Permanecem pendentes o playtest manual de Alt+Tab/configurações, a inspeção visual completa da ambientação do Claude e do poste integrado e a exportação de release; os testes automatizados não comprovam esses pontos.

---
## 2026-11-05 (3) — Codex — piso e parapeito da escadaria principal

**Estado:** aplicado localmente, não commitado. Validado no Godot 4.0.stable com `check`, `test` e capturas da escadaria.

**Preservação:** lidos `AGENTS.md`, `CLAUDE.md` e as duas entradas anteriores do Claude. Antes de editar, os modos `check` e `test` passaram na versão que continha as alterações dele. Não foram alterados seus scripts de portas, configurações, salvamento ou ambientação. Comparação da cena antes/depois: 3.807 nós originais mantidos, sem alteração de seus transforms; referência a `ambientacao.tscn` preservada.

**Arquivos e motivo:**
- `game/scenes/cenario_editavel.tscn`: concreto fotográfico nos três patamares; laje/piso com colisão no térreo sob os lances, cobrindo o terreno externo que aparecia dentro da escadaria; parapeitos no bordo livre do patamar superior, com capeamento e corrimão, preservando a entrada do lance.
- `game/scripts/stair_finish_tests.gd`: verifica suporte do piso, texturas, colisão dos parapeitos, caminho livre na subida e tentativa real de caminhar para fora do patamar.
- `game/scripts/chapter_tests.gd`: inclui esse caso na regressão existente, mantendo referência ao objeto de teste durante os awaits.
- `README.md`: informa localização do acabamento editável.
- `docs/HANDOFF.md`: registro da integração.

**Validação depois da edição:** `check` e `test` passaram (código 0), incluindo `STAIR_FINISH_TEST_OK`, `PROP_LAYOUT_TEST_OK`, `TABLET_CONSOLE_TEST_OK`, `ARCHITECTURE_TEST_OK`, `SOUNDSCAPE_TEST_OK`, `EXPLORATION_TEST_OK`, `CHAPTER1_TEST_OK`, `CCTV_UI_TEST_OK` e `CHAPTER2_TEST_OK`. Capturas renderizadas e inspecionadas: `.local/main-stair-ground.png`, `main-stair-approach.png` e `main-stair-upper.png`. Piso e proteção conferidos por baixo, na chegada e no patamar. Persistem os avisos antigos de liberação do shader/RID do FogVolume no encerramento; nenhum erro de script ou caso de teste falhou na execução final.

**Para o próximo agente:** o acabamento está no grupo `Predio/Escadas_2075/AcabamentoEscadariaPrincipal`. Edite a cena salva; não regenere o cenário. Os testes desta tarefa não substituem os testes manuais de Alt+Tab/configurações/porta no vão nem um teste de corrupção deliberada do save com recuperação da reserva, apontados pelo Claude.

---

## 2026-11-05 (2) — Claude — geometria, texturas e ambientação das salas novas

**Estado:** aplicado na pasta de trabalho, **não commitado** e **não validado no Godot** (sem Godot nem shell nesta máquina). Soma-se à entrada anterior, também pendente de validação.

**Pendente para o próximo agente com Godot:**
1. Abrir o editor e aguardar a importação; abrir `res://scenes/ambientacao.tscn` e conferir se os modelos aparecem (o script `prop_slot.gd` é `@tool`).
2. `-Mode check` e `-Mode test` (`tools/godot.ps1`). Atenção a `EXPLORATION_TEST_OK`, `PROP_LAYOUT_TEST_OK` e `ARCHITECTURE_TEST_OK`.
3. Percorrer copa, almoxarifado, pessoal, segurança, escada de serviço e fim do corredor do 2º andar. Conferir: porta aberta sem folha duplicada, sem fresta acima das portas, sem piscar nas paredes, e orientação de cadeiras, estante e gaveteiro.
4. Se o banco (`painted_wooden_bench`) ou a luminária ficarem de costas, gire o nó em `ambientacao.tscn` (180°).

**Causas encontradas e correções:**

| Problema (capturas do Lucas) | Causa | Correção |
|---|---|---|
| Folha de porta fechada no vão com a porta aberta (copa) | `compact_models()` da migração reinstanciou o `interior_door.glb` inteiro ao lado do `pivot`, que já tem folha/dobradiças/maçaneta | `authored_door.gd` oculta, no modelo fixo, tudo que não for `Frame*` |
| Fresta preta acima das portas novas | Verga a 2,70 m, batente termina a 2,60 m (as do prédio começam a 2,50 m) | Vergas das 3 portas com 2,50–3,00 m em `novas_salas.tscn`; `tools/add_exploration_rooms.gd` corrigida |
| Texto espelhado "COPA / FUNCIONÁRIOS" visível de dentro | `Label3D` dupla face atrás da verga | `double_sided = false` nas 3 etiquetas |
| Paredes/teto/piso das salas novas destoando | Os 6 materiais de `novas_salas.tscn` foram gravados **sem texturas** e com parâmetros padrão (tint creme, pattern 0) | Corpos copiados dos materiais equivalentes de `cenario_editavel.tscn` (texturas + parâmetros) |
| Parede creme sem rodameio na copa; concreto no almoxarifado | `wall_cream`/`wall_concrete` e sem o rodameio que `chapter_world.wall()` cria | Paredes novas em `wall_green` + rodameio, rodapé e friso |
| Parede do almoxarifado piscando | Ocupava exatamente o volume da parede de concreto da escada de serviço (faces coplanares) | Virou revestimento fino só do lado da sala (`Fix_alm_*`) |
| Rodameio/rodapé aparecendo e piscando dentro da escada de serviço | Paredes da escada (`MeshInstance3D_2807/2810` e verga `2808`) no mesmo plano do rodameio da segurança/técnica | Recuadas 2 cm em X em `cenario_editavel.tscn` |
| Faixa piscando na segurança e técnica junto à torre da escada | Pontas das paredes `2800`/`2797` no plano da face interna da sala | Encurtadas 2 cm |
| Fim do corredor do 2º andar piscando verde/creme | `2915` (verde) e `3175` (creme) no mesmo volume | `2915` avançada 2 cm para dentro |
| Teto da escada piscando junto à fachada | Base de `2803` no plano da cornija `0117` | Teto 1 cm mais baixo |
| Cadeira, cabideiro, lixeira e caixas simplificados | Modelos Kenney | Copa/pessoal: removidos de `novas_salas.tscn`; segurança/recepção/técnica: `visible = false` em `cenario_editavel.tscn`; substituídos por Poly Haven em `ambientacao.tscn` |
| Gaveteiro da sala de pessoal de frente para a parede | Rotação +90° (a frente do modelo é +Z) | −90° |

**Novo:** `game/scripts/prop_slot.gd` e `game/scenes/ambientacao.tscn`, com 37 objetos e 4 quadros de avisos/calendário nos dois andares, usando só modelos CC0 que já estão no projeto. Os objetos ficam fora das posições usadas pelos testes (`reachable`/`cross_door`); na segurança não têm colisão nova. `exploration.gd` aplica a camada do 2º andar em `Ambientacao2Andar`. README: seção "Ambientação editável".

**Como foi verificado (fora do Godot):** leitor próprio de `.tscn` (transformações em coordenadas do mundo) + rasterização das caixas em várias alturas; procurou frestas batente/verga, paredes abaixo do teto, fendas entre segmentos e faces coplanares com materiais diferentes; e checou referências `ExtResource/SubResource`, nós órfãos e sobreposição dos objetos novos com paredes e móveis. Modelos importados (`.glb/.gltf`) e malhas não-caixa não entram nessa verificação.

**Sugestões para depois:** mesas `metal_office_desk` estão esticadas em altura (1,08 m contra 0,79 m do modelo), mas há itens de roteiro apoiados nelas, então não mexi. Cabe baixar mais modelos CC0 (armários de vestiário, geladeira, bebedouro) com `tools/download_polyhaven_models.ps1` e criar nós em `ambientacao.tscn`.

---

## 2026-11-05 — Claude — revisão geral e correções de robustez

**Estado:** aplicado na pasta de trabalho, **não commitado** e **não validado no Godot** (o Claude não tinha Godot nem shell nesta máquina). Branch atual da pasta: `feat/primeiro-ato-completo`.

**Pendente para o próximo agente com Godot:**
1. `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode check`
2. `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode test`
3. Teste manual rápido: Esc > Configurações > Controles e vídeo; Alt+Tab durante a exploração; tentar fechar uma porta parado no vão; salvar, fechar e carregar checkpoint.
4. Se tudo passar, commitar numa branch própria (ex.: `fix/saves-e-configuracoes`) e abrir PR.

**Mudanças:**

| Arquivo | O quê | Por quê |
|---|---|---|
| `game/scripts/chapter.gd` | `save_game` grava em `.tmp` e troca pelo checkpoint, mantendo `chapter1.bak.json`; `load_game` valida via `read_checkpoint()` e cai para a reserva se o principal falhar | Fechar o jogo no meio da escrita deixava um JSON truncado e o save perdido |
| `game/scripts/chapter.gd` | Ao carregar, `verified`, `flags.power_sequence` e `flags.patch_port` voltam a ser `int` | O JSON devolve float; no Godot 4 `[2.0] != [2]` e `[0.0].has(0)` é falso. Efeitos: sequência de disjuntores recusada após carregar no meio dela; câmeras verificadas sem ✓ no console e contagem duplicada em `verify_camera` |
| `game/scripts/main.gd` | F1/F3/F4/F5 só funcionam com `OS.is_debug_build()` | Em export de release o jogador conseguia destrancar todas as portas, voar e invocar o vulto |
| `game/scripts/main.gd` | Pausa automática em `NOTIFICATION_APPLICATION_FOCUS_OUT` (só em exploração livre; desligável) | Alt+Tab deixava o jogo correndo, com eventos de susto acontecendo sem o jogador |
| `game/scripts/game_settings.gd` (novo) | Preferências em `user://settings.cfg`: sensibilidade, inverter Y, tela cheia, pausa ao perder foco | Não havia como ajustar o mouse nem a janela |
| `game/scripts/player.gd` | `sensitivity`/`invert_y` como variáveis; flag `--smoke-test` lida uma vez | Suporte às configurações; evita alocar a lista de argumentos a cada movimento do mouse |
| `game/scripts/chapter_ui.gd` | Página "Controles e vídeo"; título da pausa mostra o capítulo atual | Antes dizia "O Primeiro Turno" também no capítulo 2 |
| `game/scripts/door.gd` | O jogador não fecha a porta estando no vão (aviso na legenda) | A colisão volta no início do fechamento e empurrava o jogador para dentro da parede/outro cômodo. Eventos do roteiro (`set_open`/`restore_open` diretos) não são afetados |
| `README.md`, `docs/CHAPTER_1.md`, `docs/HUD_ARCHITECTURE.md` | Documentam as configurações, as teclas de debug e o save com reserva | — |
| `AGENTS.md`, `CLAUDE.md`, `docs/HANDOFF.md` | Protocolo de colaboração Codex + Claude | Pedido do Lucas: trabalho conjunto dos dois agentes |

**Observações da revisão (não alteradas, para decidir depois):**
- `project.godot` ainda declara `config/features` com "GL Compatibility", embora o renderizador seja Forward+. O próprio editor reescreve esse campo ao salvar as configurações do projeto; não foi editado à mão para não conflitar com o editor aberto.
- `chapter.gd` e `chapter_ui.gd` concentram muita lógica (roteiro, saves, todos os menus). Vale separar saves (`checkpoint.gd`) e menus de pausa/configuração antes do capítulo 3.
- Mapeamento de teclas fixo em código (`configure_input` e `physical_keycode` espalhados). Um remapeamento futuro deve passar tudo para ações do InputMap.
- Os testes não cobrem: save com reserva, normalização de tipos e bloqueio da porta no vão. Sugestão: casos em `chapter_tests.gd` gravando um JSON truncado no principal e conferindo o carregamento da reserva.

## 2026-11-06 — Claude — protótipo WebGPU da criatura de névoa (fora do Godot)

Banco de testes em `tools/webgpu-fog/index.html` para fechar o visual do vulto
volumétrico ANTES de gastar tempo com `FogVolume` no Godot. Não toca no jogo.

Como rodar: servir a pasta (`python -m http.server`) e abrir
`index.html?img=arquivo.png`, ou arrastar um PNG na página. Precisa de WebGPU
(Chrome/Edge 113+).

| O quê | Por quê |
|---|---|
| Raymarch de volume com densidade vinda da silhueta | É o equivalente do `void fog()` do Godot; o que for calibrado aqui porta direto |
| Máscara reconstruída pelo brilho quando o PNG não tem alpha | As artes de referência do Lucas são RGB com o xadrez gravado nos pixels; sem isso o volume vira um bloco |
| Espessura em Z vinda de um borrão da própria silhueta | Tronco grosso, dedo fino: é o que tira o aspecto de recorte chapado |
| Espessura em XY por dilatação (anel de 6 amostras) | Engorda o corpo sem mexer na arte |
| Slider silhueta ↔ desenho | O tom da arte modula a densidade: define quanto do desenho aparece na névoa |
| Câmera orbital, cor, brilho próprio, congelar animação | Avaliar o efeito parado e de vários ângulos |

**Sub-setor de esqueleto** (`tools/webgpu-fog/skeleton.js`): esqueleto humanoide
base de 10 ossos que o Lucas arrasta para encaixar na arte. Cada osso tem um
alcance (a regiao da imagem que ele leva junto); girar o osso distorce aquela
regiao, dando andar/sentar sem redesenhar frame a frame. A deformacao e feita
invertida (para cada pixel de saida, de onde ele veio) e assada na CPU a no
maximo 512px de largura, so quando a pose muda — assim o shader nao paga nada
por amostra. Tem preset de caminhada e exporta `esqueleto.json`.

**Ordem de trabalho** (definida pelo Lucas): primeiro fecha o MODELO, depois
anima. "salvar modelo" grava o visual pronto de N angulos num sprite sheet
(impostor) e "usar modelo salvo" passa a mostrar o angulo mais proximo em vez
de marchar o volume — mesma imagem, custo de um sprite. O raymarch roda uma vez
por angulo na gravacao e nunca mais. A saida do shader passou a ter alpha (o
fundo virou CSS) para o png salvo poder ser composto em cima de qualquer cena.

**Malha 3D** (`tools/webgpu-fog/mesh.js`): "exportar .glb" extrai a superficie
do mesmo campo de densidade (surface nets, nao marching cubes: mesma superficie
para formas gordas, sem as tabelas de 1400 numeros) e grava um glTF binario com
UV planar frontal, a arte como textura e os ossos do editor como skin. No Godot
abre como MeshInstance3D + Skeleton3D, entao a animacao passa a ser nativa.

**Validado:** renderiza sem erro de console no Chrome, com a arte do ceifador;
girar um osso deforma a regiao certa; o modo solido bate com o volumetrico.
No modo solido o esqueleto deforma na GPU, nao na CPU: como ali nao ha volume
para remarchar, a pose vira algumas contas por pixel sobre o quadro gravado
(ossos vao num storage buffer). Resultado: posar e andar rodam ao vivo, sem
rebake. No modo volumetrico continua sendo a CPU, com rebake limitado.
**Não validado:** FPS real (medido só no pane do app, que vem throttled) e o
comportamento no Godot — nada foi portado ainda.

**Limite conhecido:** um PNG de frente não tem perfil lateral. Até ~±60° lê como
criatura; a 90° vira um borrão. Saídas: billboard (o volume sempre encara a
câmera), ou uma segunda silhueta de perfil para cruzar os dois volumes.

## 2026-11-06 — Claude — Mêmesis de malha andando entre as salas (F5 vira lista)

A criatura do protótipo WebGPU entrou no jogo como quarto vulto, para medir se
vale trocar névoa volumétrica por malha animada.

| Arquivo | O quê | Por quê |
|---|---|---|
| `game/scripts/memesis_malha.gd` (novo) | Carrega `assets/models/criatura.glb`, toca o ciclo "andar" e ronda o térreo: corredor, segurança, arquivo e sala técnica | Os três vultos de névoa são campo de densidade e não têm corpo: só deslizam. Este anda de verdade, com Skeleton3D |
| `game/scripts/chapter_world.gd` | Cria `figure_mesh` ao lado de `figure` e `figure_volume` | O capítulo não sabe que ele existe, igual ao `figure_volume` |
| `game/scripts/main.gd` | F5 deixou de invocar direto e passou a abrir uma lista dos Mêmesis disponíveis | Eram três vultos e um atalho só; agora quem testa escolhe sem decorar tecla por vulto |
| `game/assets/models/criatura.glb` | A malha exportada, com esqueleto de 10 ossos e a animação "andar" dentro | — |

O `.glb` sai de `tools/webgpu-fog` (botão "exportar .glb"). A textura é a frente
já renderizada com névoa, não a arte crua: com a arte crua a malha ficava preta
no Godot, porque o desenho é quase todo preto. O material é emissivo pelo mesmo
motivo — numa cena escura como a do jogo ela sumiria.

**Validado** com o Godot deste projeto: smoke test passa (`tools\godot.ps1 -Mode
test`); a lista do F5 abre com as cinco entradas e fecha; o vulto de malha anda
6,6 m em 15 s e passa por quatro pontos da ronda, com o ciclo tocando.
**Não validado:** como fica em tela, de perto e com a iluminação do corredor —
nada disso foi visto rodando o jogo de verdade.

**Limite conhecido:** a malha vem de um desenho de frente, então de lado ela
engorda. A ronda é um caminho fixo, sem navegação nem colisão: ela atravessa
porta fechada e móvel no caminho.

## 2026-11-06 — Claude — Medição de FPS: o custo não são os efeitos

Medido com bench temporário (vsync off, 1280x720, 90 quadros por amostra, GPU
RTX 4060 Laptop) em três pontos. O bench foi removido depois; nenhuma
otimização foi aplicada — isto é só o diagnóstico.

Inventário da cena: 36 luzes, **29 com sombra**, **4422 MeshInstance3D**, feed
do CCTV já em 640x360.

| Configuração | corredor | recepção | rua |
|---|---|---|---|
| base (tudo ligado) | 44 fps | 34 fps | 26 fps |
| sem desconforto / névoa / glow / grão | sem ganho (dentro do ruído, ±3 ms) | — | — |
| feed do CCTV pausado | 114 fps | 77 fps | 43 fps |
| feed a 6 Hz | 99 fps | 66 fps | 40 fps |
| props < 0,8 m sem sombra (2217 malhas) | 52 fps | 42 fps | 30 fps |
| feed 6 Hz + props sem sombra | 123 fps | 75 fps | 48 fps |
| sem sombra nenhuma | ~170 fps | ~175 fps | ~160 fps |

O custo é sombra, não efeito. O `SubViewport` do CCTV roda `UPDATE_ALWAYS` e
re-renderiza as 29 sombras todo quadro: com as sombras desligadas, o feed fica
de graça (5,9 ms com feed vs 5,8 ms sem). Atlas de sombra em 2048 e
`distance_fade` nas luzes não mudaram nada — não é resolução de atlas nem
alcance, é quantidade de caster × luz.

**Validado:** os números acima, medidos. **Não validado:** nada foi alterado no
jogo; o impacto visual de congelar/afinar o feed e de tirar sombra dos props
pequenos não foi visto em tela.

### Complemento — hitbox de luz: qual critério paga

Mesmo bench, agora ligando/desligando sombra por luz segundo quatro critérios
(28 luzes com sombra):

| Critério | luzes mantidas | corredor | recepção | rua |
|---|---|---|---|---|
| base | 28/28 | 44 fps | 34 fps | 26 fps |
| hitbox dentro do quadro da câmera | 27, 27, 28 | 42 fps | 34 fps | 25 fps |
| até 12 m do jogador | 24, 20, 6 | 44 fps | 34 fps | 30 fps |
| **com linha de visão (raycast)** | **4, 4, 1** | **78 fps** | **73 fps** | **46 fps** |

O teste de frustum não rejeita nada: num prédio, quase toda lâmpada está dentro
do quadro e atrás de uma parede. O que paga é justamente a oclusão.

`shadow_enabled = false` por linha de visão **vaza luz pela parede** — a
recepção ficou visivelmente mais clara que a base (comparar
`.local/luz-recepcao-A-base.png` com `-D-linha-de-visao.png`). Apagar a luz
inteira (`visible = false`) pelo mesmo critério dá o mesmo FPS (78/74/46) e a
imagem bate com a base.

Thread model: o projeto não cria nenhuma `Thread` nem usa `WorkerThreadPool`, e
`rendering/driver/threads/thread_model` está no padrão da engine (1). Subir para
2 (multi-thread) **derruba o jogo** no Godot 4.0 em menos de um segundo, sem
mensagem de erro. Não é a alavanca: o gargalo é volume de draw call
(27 mil no corredor, 46 mil na rua), que thread de jogo não reduz.

**Validado:** números e capturas acima. **Não validado:** o efeito do raycast em
movimento (pop ao cruzar porta) e o que acontece com o feed do CCTV quando a luz
é apagada por falta de linha de visão *do jogador* — a câmera do CCTV olha outro
lugar e precisaria do mesmo teste.

## 2026-11-06 — Claude — Qualidade de luz: oclusão de lâmpadas no menu

A hitbox de luz foi testada recortada nas paredes, como pedido: 6 raios por
lâmpada a partir do filamento, cortando a caixa de alcance na primeira parede
de cada eixo. O volume cai para 44% do original — e **não muda nada**
(49,66 ms → 49,90 ms, 20,1 → 20,0 fps). O frustum é um cone saindo do olho:
ele não sabe o que é parede. Recortar a caixa não tira a caixa do cone.

O que paga é o raio. Medido na mesma rodada, corredor / recepção / calçada:

| critério | lâmpadas acesas | fps |
|---|---|---|
| base | 28/28 | 20 / 38 / 25 |
| hitbox recortada, só frustum | 25–28/28 | 20 / 37 / 25 |
| raio ao centro da lâmpada | 1–4/28 | 34 / 72 / 46 |
| **hitbox recortada + raio ao volume** | 1–4/28 | **71 / 73 / 35** |
| **idem, sem mexer em `visible`** | — | **74 / 72 / 35** |

| Arquivo | O quê | Por quê |
|---|---|---|
| `game/scripts/light_culling.gd` (novo) | Mapeia o volume iluminado de cada lâmpada uma vez e reavalia 7 lâmpadas por quadro | A geometria é estática: o recorte nas paredes não precisa rodar de novo |
| `game/scripts/chapter_world.gd` | Cria o nó depois de montar os dois andares | Precisa das 28 lâmpadas já no lugar |
| `game/scripts/game_settings.gd` | Chave `light_culling`, ligada por padrão | Preferência de vídeo, junto de tela cheia e sensibilidade |
| `game/scripts/chapter_ui.gd` | Tela "Qualidade de luz" no menu de pausa | Pedido: poder desligar |

O nó **não escreve `visible`** — desliga `shadow_enabled` e zera o
`light_cull_mask`. Quem manda em acesa/apagada continua sendo o capítulo (ritmo
do corredor, blecaute, energia), que escreve `visible` em cinco lugares; as
duas coisas brigariam. Custa ~3 fps a mais que mexer em `visible` e não encosta
na lógica do jogo. A câmera do CCTV entra no teste junto com a do jogador,
senão a CAM-04 escureceria quando o jogador está longe do terminal.

**Validado:** números acima; `check` limpo; as dez suítes do smoke test passam.
**Não validado:** o jogo em movimento — se a luz pisca ao cruzar uma porta (há
2 quadros de tolerância contra isso, não testados em jogo) e se o facho que
escapa por porta aberta sobrevive. Nada disso foi visto rodando.

**Aviso de medição:** o valor absoluto varia muito entre execuções nesta
máquina — a mesma cena deu de 13,7 ms a 49,7 ms de base em rodadas diferentes.
Só comparações dentro da mesma rodada valem. Uma rodada foi descartada porque a
janela perdeu o foco e o jogo pausou sozinho no meio da medição.

## 2026-11-06 — Claude — Mapa de sombras fixas x dinâmicas (`-Mode shadows`)

Pergunta: dá para assar a sombra do cenário e calcular ao vivo só a dos
personagens e da lanterna? Medido primeiro, com a lanterna acesa e as 4202
malhas estáticas deixando de projetar:

| | hoje | só personagens projetam |
|---|---|---|
| recepção | 66 fps | 151 fps |
| sala de segurança | 86 fps | 159 fps |
| corredor | 76 fps | 192 fps |

Isso é em cima da oclusão de luz já entregue. O preço aparece ao comparar
`.local/casters-parede-A-base.png` com `-B-so-personagens.png`: a sala fica mais
clara e chapada, a cadeira perde o apoio no chão e o teto acende.

**Limite do motor:** `cast_shadow` é da malha, não da luz. Não existe, no Godot
4.0, "esta parede projeta para a lanterna mas não para a lâmpada do teto" — ou
projeta para todas, ou para nenhuma. Como a lanterna se move, a sombra dela
nunca é assável. Por isso a decisão tem de ser malha a malha, e não no atacado.

| Arquivo | O quê |
|---|---|
| `game/scripts/shadow_map.gd` (novo) | Classifica cada malha em sombra fixa ou dinâmica e escreve o resumo |
| `tools/godot.ps1` | Modo novo `-Mode shadows` |
| `game/scripts/main.gd` | Gancho `--map-shadows` |
| `docs/shadow-map.md` (novo, versionado) | O mapa: 3737 fixas, 685 dinâmicas |

Dinâmico é porta (gira), objeto interativo da história, os três vultos e a
névoa; o resto é fixo. A identidade no resumo é o id da porta/objeto ou o
script de quem construiu — o nome automático do Godot (`@@102`) mudaria a cada
execução e faria o diff piscar inteiro.

**O mapa já pagou na primeira rodada:** três portas (`break_room`, `personnel`,
`stores`) apareceram como fixas. São `authored_door.gd`, que herda de
`door.gd`, e a comparação de script direto não pegava a herança. Assadas,
teriam perdido a sombra ao abrir. Corrigido com a cadeia de herança; passaram
para dinâmicas e o total subiu de 550 para 685.

**Validado:** `check` limpo, as dez suítes passam, o mapa roda e o diff é
estável. **Não validado:** nada foi assado — o Godot 4.0 não desdobra UV2 em
tempo de execução, então o caminho continua sendo `Decal` à mão. As 685
dinâmicas são contagem conservadora: quadro de avisos e planta de parede são
`interactable.gd` e entraram como dinâmicos sem nunca se mexerem.

### Correção — a sombra fixa agora é desligável de verdade

O relato era de que a melhoria de 151 fps não tinha acontecido. Confirmado: ela
nunca foi aplicada — só medida. O que estava no jogo era a oclusão de luz, e
essa **funciona** (recepção, medido com o jogo rodando): 32,0 fps com a opção
desligada contra 71,3 com ela ligada, 21 das 25 lâmpadas apagadas.

Faltava o segundo passo, que agora existe como opção: **Sombra do cenário**,
em Configurações → Qualidade de luz. Desligada, só personagens, portas e
objetos da história projetam.

| modo | recepção |
|---|---|
| tudo como era antes | 32,0 fps |
| só oclusão de luz (já estava) | 71,3 fps |
| oclusão + sombra do cenário desligada | **143,0 fps** |

A classificação é a mesma de `docs/shadow-map.md` — `light_culling.gd` carrega
`shadow_map.gd` e usa o mesmo `reason()`, para o menu e o mapa nunca
discordarem. Confere: 3737 malhas, o número do mapa.

Dois erros meus no caminho, dos quais a medição serve de prova:
- a lista era montada no `_ready` do mundo e pegava 2796 das 3737 malhas — ali
  metade do cenário ainda não nasceu. Passou a ser montada na hora de desligar.
- malhas efêmeras (névoa, puffs) morrem no meio do turno e a lista guardava
  referência podre (`Invalid set index 'cast_shadow' on previously freed`).
  Agora passa por `is_instance_valid`.

**Padrão:** ligada, ou seja, o visual de hoje. Desligar dobra o FPS e achata a
cena (ver as capturas `casters-parede-*`), e isso é decisão de direção de arte,
não minha.

**Validado:** números acima com o jogo rodando; `check` limpo; as dez suítes
passam. **Não validado:** o jogo em movimento com a sombra do cenário
desligada.

### Padrão invertido — o jogo abre com a sombra do cenário desligada

As duas opções continuam no menu; o que mudou é o padrão. `static_shadows`
agora nasce `false` em `game_settings.gd` e no próprio nó.

Verificado com o `settings.cfg` apagado, medindo o jogo como ele abre:

| | recepção |
|---|---|
| como o jogo abre agora | **143,0 fps** |
| ligando "Sombra do cenário" no menu | 67,4 fps |
| desligando de novo | 143,2 fps |

**Terceiro erro meu na mesma feature, pego na medição:** com o padrão
desligado, o arranque pegava só **2796 das 3737 malhas** (1260 realmente sem
sombra) e entregava 94 fps em vez de 143 — as preferências são aplicadas no
`_ready` do `main`, e o cenário ainda está nascendo ali. Agora a lista é
remontada nos quadros 30, 120 e 300; depois de ~3 s ela bate com o mapa
(3737) e o FPS assenta em 143.

A coleta custa **27 ms**, medido — é varredura de 4422 malhas com
classificação por herança. Por isso ela roda três vezes no arranque (durante a
cartela de abertura) e depois só quando o menu mexe na opção, nunca em laço.

**Limite conhecido:** objeto de cenário que a história criar depois dos
primeiros 3 s continua projetando sombra até alguém mexer na opção. São
poucos, e os que aparecem no meio do turno (vultos, névoa) são dinâmicos de
propósito.

**Validado:** números acima com o jogo rodando e preferências zeradas; `check`
limpo; as dez suítes passam. **Não validado:** o jogo em movimento, e as três
pausas de 27 ms no arranque não foram observadas em tela.

## 2026-11-07 — Claude — Correção: assar sombra É possível no Godot 4.0

Eu afirmei duas vezes aqui que não dava para assar lightmap porque o Godot 4.0
não desdobra UV2 em tempo de execução. **Errado.** Sondado no motor deste
projeto:

| | |
|---|---|
| `BoxMesh.add_uv2` | existe (todo o prédio é `BoxMesh`) |
| `ArrayMesh.lightmap_unwrap()` em runtime | existe e **funciona** (erro=0, gera UV2) |
| `LightmapGI` / `LightmapGIData` | existem |
| `LightmapGI.bake()` exposto a script | **não** — assar é ação do editor |

Ou seja: o caminho do TrackMania está aberto, com uma condição. O que o TMNF
faz no "ultra" é calcular um lightmap por mapa e guardá-lo comprimido no
arquivo do mapa, com cache local em resolução cheia; a conta leva ~15–20 min
por mapa. É assar uma vez e salvar, não simular a cada abertura.

Para fazer igual aqui: salvar o prédio procedural como cena uma vez, assar no
editor, versionar o `LightmapGIData` e atribuí-lo em runtime. Não é pequeno —
briga com o fato de o mundo nascer em código — mas é possível, e a sonda acima
diz exatamente quais peças existem.

### Proposta de andares: quase tudo já está no jogo

| pedido | situação |
|---|---|
| cômodo com escada é permanente | já: `is_main`/`is_service` mantêm os dois níveis no vão |
| andar some quando se está em outro | já: `update_floor_culling` |
| escadas continuam ao esconder o andar | já: o nó `staircases` nunca é escondido |
| de fora, luzes de janela e corredor acesas | verificado: 25 de 25 lâmpadas acesas da rua (o vidro não barra o raio) — ver `.local/janela-rua.png` |
| renderizar o exterior só onde há janela | **novo, e é o que paga** |

Medido escondendo `architecture` (o exterior) com o jogador dentro:

| | exterior visível | exterior escondido |
|---|---|---|
| corredor | 90,0 fps | **174,3 fps** |
| recepção | 82,8 fps | **143,2 fps** |

### Multithread: medido, não há o que mover

A oclusão de luz custa **0,2–0,5 ms de um quadro de ~7 ms** (3 a 7%). Mesmo
movida para outra thread, o teto do ganho é meio milissegundo. O custo está em
draw call (27 mil no corredor, 46 mil na rua), que thread de GDScript não
submete, e `thread_model=2` derruba o jogo no Godot 4.0.

**Validado:** as sondas e medições acima. **Não validado:** nada foi
implementado nesta entrada.

## 2026-11-07 — Claude — O culling de andar não cullava nada (corrigido)

A observação do usuário — "isso também impede o vazamento de luz entre
andares" — levou à verificação que achou o furo: **o culling de andar entregue
no dia 28/10 nunca escondeu coisa alguma.**

`tag_upper_layer` fazia `child.layers |= UPPER_LAYER`, deixando a malha em
`1 | 8 = 9`. A câmera do jogador sempre carrega o bit 1, então tirar o bit 8 da
máscara não mudava nada. Todas as vezes em que medi "upper=OFF" eu estava
lendo um bit sem efeito.

Correção em três partes, cada uma descoberta pela anterior:

1. `layers = UPPER_LAYER | CCTV_LAYER` (12) em vez de `|= UPPER_LAYER`. A
   camada 1 tem de sair para a máscara mandar; a do CCTV entra para a CAM-04
   continuar enxergando o andar.
2. O valor errado **foi parar salvo em `game/scenes/cenario_editavel.tscn`** —
   178 malhas com `layers = 9` gravadas no disco, de quando alguém salvou a
   cena no editor com o código antigo rodando. A etiquetagem passou a aceitar
   também esse valor.
3. A cenografia autorada entra no `upper` depois do `_ready`, então uma
   etiquetagem só não alcançava nada disso. Agora reetiqueta nos quadros 30,
   120 e 300.

Depois: 211 malhas em `layers = 12`, e com o bit desligado restam **1 visível
em vez de 178**.

| corredor térreo | malhas do andar visíveis | fps |
|---|---|---|
| 2º andar renderizado | 178 | 93,7 |
| 2º andar cullado | 1 | 97,6 |

**O ganho de FPS é pequeno (4%)** — o andar de cima são 211 das 4422 malhas, e
as 8 lâmpadas dele já eram apagadas pela oclusão por linha de visão. O valor do
culling de andar é o que o usuário apontou: **vazamento**. Comparando
`.local/bit-andar-on.png` com `bit-andar-off.png`, com o andar renderizado a
parede direita e o relógio ficam lavados; cullado, ficam limpos. Sutil, mas é
luz que atravessa laje — e com a sombra do cenário desligada por padrão, é a
única coisa que segura isso.

**Padrão de bug que já apareceu três vezes neste projeto:** o mundo não está
pronto quando o `_ready` termina. Lista de sombra estática, etiquetagem de
camada e preferências — os três erraram por isso. Quem for mexer em coleta de
nós aqui: colete depois, em quadro posterior, não no `_ready`.

**Validado:** números e capturas acima; `check` limpo; as dez suítes passam.
**Não validado:** o jogo em movimento subindo e descendo a escada.

### Complemento — os objetos do andar também não eram cullados

Pergunta do usuário, e estava certa de novo. Com o andar cullado, **786 malhas
acima de 3,2 m continuavam sendo desenhadas**, porque a etiquetagem ia pelo pai
e porta, placa, luminária e objeto interativo do segundo andar são criados pelo
**mundo**, não dentro do nó `upper`.

A regra passou a ser altura, não parentesco: o térreo termina em y = 4,20, os
objetos interativos do segundo andar vivem entre 5,20 e 7,20, então
`UPPER_SLAB = 4.35` separa limpo. Escadaria e exterior ficam de fora da regra
por decisão: escada é cômodo permanente, fachada é o que se vê da rua e pela
janela.

| acima da laje, ainda desenhado | antes | depois |
|---|---|---|
| objetos interativos (`interactable.gd`) | 70 | **1** |
| portas (`door.gd`) | 101 | 11 (todas do térreo, y ≤ 4,21) |
| placas (`aged_sign.gd`) | 130 | 40 (todas do térreo, y ≤ 4,29) |
| escadaria | 327 | 327 (de propósito) |
| exterior + fachada | 271 | 271 (de propósito) |

Suportes de câmera ficam na camada 2 (só-do-jogador) de propósito; acima da
laje agora vão para `UPPER_LAYER` sozinha — somem com o andar e continuam fora
do próprio feed do CCTV. As malhas do andar ficam em `UPPER_LAYER | CCTV_LAYER`
(12), e a câmera do CCTV tem máscara 5: `12 & 5 = 4`, então a CAM-04 continua
enxergando o segundo andar.

**Validado:** contagens acima; `check` limpo; as dez suítes passam.
**Não validado:** a CAM-04 em imagem depois desta mudança — a captura que
tenho é anterior; o raciocínio de máscara acima é dedução, não foto.

## 2026-11-07 — Claude — Feed do CCTV sob demanda, 3D parado no terminal, alcance nos objetos

Três pedidos do usuário, todos medidos antes de implementar (recepção):

| | fps |
|---|---|
| A hoje: feed todo quadro, 640x360 | 74,3 |
| B feed a 6 Hz | 158,4 |
| C 6 Hz + 320x180 | 179,7 |
| D feed parado | 204,4 |
| E terminal fechado (referência) | 79,0 |
| F 3D do jogador parado com o terminal aberto | 109,5 |

| Arquivo | O quê |
|---|---|
| `computer.gd` | `atualizar_feed()`: terminal aberto = ao vivo em 640x360; fechado = 6 Hz em 320x180; sem energia = parado. Não encosta no feed durante fita, que é do `recording_player` |
| `chapter_world.gd` | `update_floor_culling` zera o `cull_mask` do jogador enquanto o terminal está aberto — o overlay é opaco e cobre a tela |
| `light_culling.gd` | `apply_prop_range()`: malha com AABB < 0,8 m ganha `visibility_range_end = 14 m` com 2 m de fade |

O alcance de 14 m atende de uma vez o "objetos só quando está próximo" da
escadaria e o LOD: parede, piso, escada e luminária não entram no critério, só
o que é miúdo. São **1829 objetos**, e o corte é do motor, sem custo por quadro.

Estado do jogo como ele abre, medido com as preferências zeradas:

| | fps |
|---|---|
| recepção | **244,2** |
| corredor | **235,0** |
| escadaria | **239,1** |
| calçada | **180,0** |

Para comparar: a recepção estava em 34 fps quando esta investigação começou.

**Validado:** números acima; `check` limpo; as dez suítes passam; a recepção em
imagem continua com planta, balcão, relógio e corredor no lugar
(`.local/final-recepcao.png`). **Não validado:** o pop-in dos objetos a 14 m em
movimento, e a CAM-04 em imagem depois das mudanças de camada e resolução.

### Correção — tela preta ao sair das câmeras, e o alcance que não valia com sombra

Dois defeitos relatados pelo usuário, dos dois eu fui o autor na entrada acima.

**1. Tela preta ao sair do terminal.** `update_floor_culling` calculava a
máscara nova a partir da máscara atual (`mask | bit` / `mask & ~bit`). Zerada
para o terminal, ela nunca mais voltava: `0 & ~8` continua 0. Agora a máscara
é guardada em `saved_cull_mask` antes de zerar e devolvida inteira na saída —
inteira de propósito, porque o desconforto mexe no bit da mão por conta
própria e não pode ser atropelado. Verificado: 19 → 0 no terminal → 19 ao
sair, e a sala volta em imagem (`.local/saiu-do-terminal.png`).

**2. O alcance dos objetos não era aplicado com a sombra do cenário ligada.**
Verdade: `apply_prop_range` morava dentro da varredura que só rodava quando a
sombra estava desligada. Com a opção ligada, zero objetos recebiam alcance.
A varredura passou a rodar nos dois casos; o que depende da opção é só o
`cast_shadow`. Verificado: com a sombra LIGADA, 1829 objetos com alcance — o
mesmo número de antes.

Na mesma passada, um cuidado que faltava ficar explícito: só malha de cenário
recebe alcance. Porta e objeto da história são classificados como dinâmicos e
nunca somem por distância — uma porta desaparecendo a 14 m esconderia caminho.

**Validado:** os dois casos acima com o jogo rodando; `check` limpo; as dez
suítes passam. **Não validado:** o pop-in a 14 m em movimento.

### Correção — a oclusão apagava luz com a área dela à vista

Dois defeitos no critério, ambos relatados pelo usuário e ambos confirmados.

**1. Os pontos de amostra nasciam dentro da parede.** A caixa do volume
iluminado é recortada por raio, então cada canto dela fica *exatamente* sobre
a superfície de uma parede. Mirar nos cantos fazia o raio bater nessa parede
um triz antes de chegar, e a lâmpada apagava mesmo com o jogador embaixo dela.
Agora a caixa encolhe 0,5 m antes de virar amostra, a posição da própria
lâmpada entra na lista e os centros das seis faces também — é no chão e na
parede que o facho aparece.

**2. O vidro barrava o raio.** As vidraças são criadas com colisão
(`world.box(..., "glass", true)`), então a oclusão tratava janela como parede:
olhando a entrada de dentro da recepção, a rua apagava. Os corpos de vidro
passaram a ser marcados com `set_meta("transparente")` e o raio atravessa até
três vidraças antes de desistir. O vidro continua barrando o jogador.

Com o jogador na entrada, olhando para a rua:

| lâmpada | antes | depois |
|---|---|---|
| marquise (0, 3, 8) | apagada | **acesa** |
| marquise (0, 3, 14) | apagada | **acesa** |
| estacionamento (±11, 5, 28) | apagadas | **acesas** |
| total aceso na vista | 1 de 25 | **4 de 25** |

Custo do teste: 0,013 ms por lâmpada, igual ao de antes — os saltos de vidro
são raros.

### O outro sintoma não é luz: é geometria

"No corredor do 2º andar, olhando na direção da entrada, o FPS cai muito."
Confirmado, e a causa não é a oclusão de luz:

| mesmo ponto do 2º andar | lâmpadas acesas | draw calls | fps |
|---|---|---|---|
| olhando para a entrada | 1 | 9299 | 70,6 |
| olhando para o fundo | 0 | 4911 | 200,0 |

Mesma quantidade de luz, **o dobro de draw calls**. Olhando no eixo longo do
prédio, o frustum pega o andar inteiro mais a recepção, e nada disso é
ocluído: o Godot não sabe que há parede no caminho.

Entrou um gatilho para o exterior (`update_exterior`): sem nenhuma vidraça no
campo de visão, a fachada e o estacionamento somem. Ele **não** dispara nessa
vista, e com razão — há 30 vidraças no prédio e **16 delas estão dentro do
frustum** ali. A área não é "sem janela" do ponto de vista do renderizador.

O que resolveria é oclusão de verdade, a ideia da primeira mensagem desta
conversa. Sondado agora: `OccluderInstance3D` e `BoxOccluder3D` existem neste
Godot 4.0 e **montam em runtime sem bake** — eu havia descartado isso por
achar que exigia assar. A configuração
`rendering/occlusion_culling/use_occlusion_culling` está `false`. Seria pôr um
`BoxOccluder3D` dentro de cada parede estrutural e laje, o que o `box()` já
poderia fazer sozinho quando o `kind` é parede.

**Validado:** números acima; `check` limpo; as dez suítes passam.
**Não validado:** o ganho da oclusão por occluder — nada foi medido ainda.

## 2026-11-07 — Claude — Occlusion culling: parede volta a esconder o que está atrás

Era a ideia da primeira mensagem desta conversa, e eu a tinha descartado por
achar que exigia bake. Exigia não: `BoxOccluder3D` monta em runtime.

| Arquivo | O quê |
|---|---|
| `game/project.godot` | `occlusion_culling/use_occlusion_culling=true` |
| `chapter_world.gd` | `box()` cria um `OccluderInstance3D` quando o `kind` é estrutural (parede, laje, teto, piso, fachada) e as duas maiores medidas passam de 1,6 m |

São **103 occluders** para 4422 malhas. A caixa do occluder encolhe 12 cm em
relação à parede: maior que a parede, ele esconderia o que aparece na quina.

| vista | sem oclusão | com oclusão |
|---|---|---|
| **2º andar olhando para a entrada** (o sintoma relatado) | 70,4 fps / 9299 draws | **107,3 fps / 7727 draws** |
| recepção | 133,2 | 147,9 |
| corredor | 153,5 | 158,0 |
| 2º andar olhando para o fundo | 200,0 | 205,2 |
| calçada | 61,7 | 64,1 |

Limiar de 1,0 m foi testado e descartado: 137 occluders em vez de 103 e
exatamente os mesmos 7727 draw calls. Os 34 occluders pequenos a mais não
escondiam nada e só custavam CPU.

**Validado:** números acima; o corredor do 2º andar continua inteiro em imagem
(`.local/occ-2andar-entrada.png`); `check` limpo; as dez suítes passam.
**Não validado:** o jogo em movimento — occluder mal dimensionado aparece como
geometria piscando na quina da parede, e isso só se vê andando.

### Sombra que cai com a distância

Pedido: resolução de sombra e de luz caindo com a distância. O Godot 4.0 não
expõe resolução por lâmpada — o atlas de sombra distribui as lâmpadas pelos
quadrantes sozinho, e trocar o tamanho do atlas (4096 → 2048) já havia sido
medido aqui como zero. O que resta é o corte binário, e foi o que entrou.

Medido antes de implementar:

| vista | hoje | sem sombra além de 10 m | luz apagada além de 10 m |
|---|---|---|---|
| 2º andar p/ entrada (1 lâmpada acesa) | 110,1 | 111,6 | 110,8 |
| entrada vista de dentro (4 acesas) | 67,7 | **80,0** | 66,9 |
| recepção, sombra do cenário ligada | 159,4 | 158,1 | 158,0 |

Só paga onde há lâmpada distante no campo de visão, e o que paga é tirar a
**sombra**, não a luz: apagar a luz distante não rendeu nada e escureceria a
rua que o jogador está olhando — exatamente o defeito que acabei de corrigir.

Implementado em `light_culling.gd`: `SHADOW_RANGE = 14 m`, medido contra a
câmera do jogador e a do CCTV. A lâmpada além disso continua acesa e para de
projetar. Depois: entrada de dentro com 4 acesas e só 2 projetando, **80,6
fps**.

Desligar a oclusão no menu devolve tudo, sombra das distantes inclusive — quem
desliga quer o estado original, não um meio-termo.

**Validado:** números acima; `check` limpo; as dez suítes passam.
**Não validado:** se a sombra sumindo a 14 m se nota andando em direção a uma
lâmpada.

### Porta fechada agora oclui (e por que a primeira tentativa não funcionou)

Relato: "a porta fechada não está sendo considerada na oclusão". Metade estava
certa. O **raio da oclusão de luz** já respeitava a porta — o colisor sai da
camada 1 só quando ela abre (`set_collision_layer_value(1, not is_open)`). O
que faltava era o **occluder**: a folha não tapava nada, e a sala inteira atrás
dela era desenhada.

Primeira tentativa: occluder pendurado no `pivot`, para girar junto com a folha
e parar de tapar sozinho ao abrir. **Não funcionou** — 5994 draws com a porta
fechada contra 6000 com ela aberta, ou seja, nenhuma diferença. Occluder sob um
nó que gira não é levado em conta.

Segunda: occluder parado no corpo da porta, com `visible` seguindo o estado:

| corredor de frente para a porta da escada | com oclusão | sem oclusão |
|---|---|---|
| porta fechada | **5987 draws** / 160,0 fps | 6606 draws / 155,1 fps |
| porta aberta | 6475 draws / 157,2 fps | 6137 draws |

Fechada, a oclusão passou a poupar 619 draw calls (eram 141 antes do occluder
de porta). E aberta ela desenha mais que fechada, que é o comportamento certo:
com a porta aberta se vê a escadaria.

Porta envidraçada não recebe occluder — através dela se vê.

**Validado:** números acima; `check` limpo; as dez suítes passam.
**Não validado:** se a folha some um quadro antes da hora ao abrir, já que o
`visible` do occluder troca no início da animação e não no fim.

### O vazamento na porta de pessoal: a oclusão estava desligada no perfil

Relato: luz vazando na porta de PESSOAL / PLANTÕES, "então a oclusão não
funciona". Checadas **as 14 portas: todas fechadas**, e o colisor de porta
fechada já barra o raio. O problema era outro.

`.local/AppData/Godot/app_userdata/NIGHTSHIFT/settings.cfg` tinha
`light_culling=false` e `static_shadows=true` — alguém desligou a oclusão pelo
menu de pausa. Com ela desligada, as 25 lâmpadas ficam acesas o tempo todo.

Medido no corredor do 2º andar, de frente para aquela porta:

| | lâmpadas iluminando o jogador |
|---|---|
| como estava no perfil (oclusão off) | **25 de 25** |
| mesma config, oclusão ligada | **0 de 25** |

Não há defeito na oclusão nesse ponto: com ela ligada nenhuma lâmpada alcança
o corredor. O arquivo de preferências não foi tocado — é escolha do jogador.

### Lâmpada que só o CCTV vê sai da vista do jogador

Encontrado no caminho: `cameras()` juntava jogador e câmera de segurança num
teste só, então uma lâmpada visível **apenas para o CCTV** continuava acesa
para os dois. Com a sombra do cenário desligada, ela atravessa parede na vista
do jogador.

Agora o teste é separado: visível para o jogador → camada original; visível só
para o CCTV → camada 4 (a do CCTV). A CAM-04 continua alimentada e o jogador
não recebe a luz. A camada original de cada lâmpada é guardada no `build()`,
porque as do segundo andar já vivem em `UPPER_LAYER | CCTV_LAYER`.

**Validado:** contagens acima; `check` limpo; as dez suítes passam.
**Não validado:** o caso em que a separação dispara (lâmpada visível só pela
CAM) não apareceu nas medições — a troca de camada está escrita e compila, mas
não foi vista em imagem.

## 2026-11-07 — Claude — Cone de luz mais largo e exportador para assar

### Ângulo da verificação de luz

O teste usava só o frustum, que é estreito demais para luz: lâmpada logo fora
do canto da tela ainda ilumina o que está na tela, e apagava. Agora aceita um
cone de `fov/2 + 40°` (`extra_angulo`, ajustável).

| vista | frustum puro | cone +40° |
|---|---|---|
| recepção | 1 lâmpada / 68,8 fps | **4 lâmpadas / 69,4 fps** |
| calçada | 4 lâmpadas / 34,2 fps | 6 lâmpadas / 29,5 fps |

Na recepção o ganho de luz é de graça. Na calçada custa, porque as duas
lâmpadas a mais projetam sombra — e essa medição foi feita com a **sombra do
cenário ligada**, que é a configuração salva no perfil.

### Exportador: `tools/godot.ps1 -Mode export`

`game/scripts/scene_export.gd` roda o mundo, espera 400 quadros (o cenário não
está pronto no `_ready`) e grava a parte **estática** como cena, com UV2 e
`gi_mode = STATIC`, mais as 35 luzes e um nó `LightmapGI` já no lugar. É só
abrir e apertar Bake.

Resultado: **3558 malhas, 35 luzes, 0 malhas sem UV2.** `BoxMesh.add_uv2`
resolveu o prédio inteiro; o resto passou pelo `lightmap_unwrap`.

Dois erros meus no caminho, os dois de tamanho:
- gravar em `.tscn` (texto) produziu um arquivo de **2,35 GB**, porque cada
  malha vira array escrito por extenso. Passou para `.scn` binário.
- cada cópia carregava a sua própria malha preparada; agora são reaproveitadas
  por recurso de origem.

Mesmo assim são **425 MB**, então `game/scenes/bake/` entrou no `.gitignore`:
é artefato intermediário. O que deve ser versionado é o `LightmapGIData`
assado a partir dele.

**Validado:** a cena é gerada e o exportador relata 0 malhas sem UV2; `check`
limpo; as dez suítes passam. **Não validado:** o bake em si — não abri o editor
nem apertei Bake, então não sei quanto tempo leva nem como fica.

### O bake precisa do prédio aceso — e a luz precisa ser marcada

Duas coisas que faltavam no exportador, as duas descobertas pelo pedido de
"assar com as luzes completas":

1. **No Godot 4 a luz nasce `BAKE_DYNAMIC`**, ou seja, o lightmap a ignora. Sem
   `light_bake_mode = BAKE_STATIC` o bake sairia só com a luz ambiente — nada
   de facho nem de sombra projetada. Agora toda luz exportada é marcada.
2. **O estado exportado era o do capítulo 1:** corredor sem energia, ritmo
   piscando as lâmpadas e a oclusão apagando o que a câmera não vê. O que
   fosse assado seria o prédio meio apagado. Antes de coletar, o exportador
   agora liga a energia, desliga a oclusão, religa a sombra do cenário, para o
   `_process` do mundo (o ritmo reescreve `visible` todo quadro) e acende tudo.

Conferência impressa pelo próprio exportador: **35 luzes acesas, 35 marcadas
para assar**, 3558 malhas, 0 sem UV2.

**Porta fica de fora do bake de propósito.** Ela é classificada como dinâmica,
e assar a sombra de uma porta fechada deixaria a marca dela no chão mesmo com
a porta aberta.

**Validado:** a conferência acima; `check` limpo; as dez suítes passam.
**Não validado:** o bake. Falta abrir `game/scenes/bake/predio.scn` no editor,
selecionar o nó `LightmapGI` e apertar Bake Lightmaps.

## 2026-11-07 — Claude — O bake rodou

Feito pilotando o editor: abri `res://scenes/bake/predio.scn`, filtrei a
árvore por "Lightmap" (achar o nó entre 3558 malhas de outro jeito não é
viável), selecionei o `LightmapGI` e disparei "Gerar Mapas de Iluminação",
salvando em `scenes/bake/predio.lmbake`.

Durante o bake o editor foi a **7,9 GB de RAM** e ficou sem responder, o que é
o comportamento normal da operação. Levou menos de 10 minutos em qualidade
baixa.

Resultado, lido do arquivo e não da interface:

| | |
|---|---|
| recurso | `LightmapGIData` |
| malhas com fatia no lightmap | **3558 de 3558** |
| atlas | 2048x1024, 7 camadas |
| arquivos | `predio.lmbake` (317 KB) + `predio.exr` (226 KB) |

Nenhuma malha ficou de fora. O `.gitignore` passou a excluir só o
`predio.scn` (425 MB, regerável pelo exportador); o resultado do bake, que são
540 KB somados, é versionado.

**Validado:** a leitura do `.lmbake` acima. **Não validado, e é o que falta
para isto virar jogo:** o lightmap está preso à cena exportada, e o jogo
constrói o prédio em código. Usá-lo de verdade exige o jogo carregar essa cena
em vez de montar as malhas, ou casar as fatias do atlas com as malhas criadas
em runtime — é um passo grande, de outra conversa. Também não olhei o
resultado em imagem: o editor ficou num estado confuso depois de eu fechar um
gerenciador de projetos que abri por engano, e preferi ler o arquivo a chutar
pela interface.

## 2026-11-07 — Claude — Tela de qualidade de luz e sombra, e painel que não vaza

### Um controle para cada ajuste

Tudo o que era constante no código virou preferência salva, com controle em
Configurações → Qualidade de luz e sombra:

| controle | o que mexe | padrão |
|---|---|---|
| Oclusão de lâmpadas | `light_culling.enabled` | ligada |
| Oclusão por parede (occluder) | `use_occlusion_culling` do viewport | ligada |
| Sombra do cenário | `cast_shadow` das 3737 malhas de cenário | desligada |
| Lâmpada projeta sombra até | `shadow_range`, 4–40 m | 14 m |
| Objetos pequenos somem além de | `prop_range`, 6–40 m | 14 m |
| Folga do campo de visão da luz | `extra_angulo`, 0–80° | 40° |
| Atualização do feed do CCTV | `feed_hz`, 1–30 Hz | 6 Hz |

Mais um botão "Restaurar padrões". Verificado que cada um chega ao nó pelo
caminho real (`update_setting`): mudar o alcance dos props para 30 m
reetiquetou as 1829 malhas em cena.

### O bake é estado, não botão — e o motivo é técnico

`LightmapGIData` expõe `get_user_path`, `add_user` e `clear_users`, mas **não
devolve a escala de UV nem a fatia do atlas de cada usuário**. Sem esses dois
números não há como reapontar o mapa assado para as malhas que o jogo cria em
código. Então a tela mostra o estado ("Bake em disco: 3558 malhas no mapa.
Ainda não é usado em jogo") em vez de um botão que não faria nada.

Para o bake virar jogo de verdade, o caminho é o jogo carregar a cena
exportada no lugar de montar as malhas estáticas — mudança de arquitetura.

### Interface que não ultrapassa a tela

Relato: "todos objetos sempre se adapta a tela (algum ultrapassa dependendo da
resolução)". Era real e era geral, não só da tela nova: `panel` é um
`PanelContainer`, que **cresce até caber o conteúdo** — uma tela com muitos
controles passava da borda e saía do monitor.

Duas correções no painel, valendo para todas as telas do menu:
- um `ScrollContainer` entre a margem e a coluna: o painel para no tamanho das
  âncoras e o conteúdo rola;
- `autowrap` nos rótulos dentro da coluna: frase longa quebra linha em vez de
  empurrar a largura.

Conferido nas quatro telas do menu em três resoluções:

| | 1280x720 | 1024x600 | 800x600 |
|---|---|---|---|
| qualidade de luz | cabe | cabe | cabe |
| desconforto | cabe | cabe | cabe |
| controles e vídeo | cabe | cabe | cabe |
| configurações | cabe | cabe | cabe |

**Validado:** a tabela acima, medida comparando posição e tamanho do painel
com o viewport; a captura `.local/tela-luz.png` mostra a barra de rolagem;
`check` limpo; as dez suítes passam. **Não validado:** rolar a tela com o
mouse em jogo.

**Aviso:** apaguei o `settings.cfg` do perfil de teste ao final — ele tinha
valores que os meus próprios testes escreveram. O jogo volta a abrir com os
padrões da tabela acima, com a oclusão ligada.

### Câmera dentro do volume da lâmpada: acesa, sem perguntar

Pedido: "se a hitbox das lâmpadas for vista de dentro dela para fora dela
mantenha ela ligada". Entrou como primeira condição do teste, antes de
qualquer raio: `volumes[index].has_point(camera.global_position)`.

O motivo é que o teste anterior podia falhar justamente onde a luz mais
importa. Com o jogador parado sob o facho, os pontos de amostra caem atrás da
câmera ou contra o teto, e a lâmpada apagava com ele dentro da própria poça de
luz. Estar dentro do volume já é a resposta: a luz chega ali por definição,
mesmo com o bulbo escondido atrás de luminária ou viga.

| ponto | lâmpadas acesas | com a câmera dentro do volume |
|---|---|---|
| sob a marquise, olhando para a rua | 6 | 3 |
| recepção, de costas para a lâmpada | 6 | 4 |

Custo: 0,029 ms por lâmpada, 0,2 ms por quadro com a fatia de 7 — é um teste
de ponto em caixa, mais barato que o raio que ele evita.

**Validado:** números acima com o jogo rodando; `check` limpo; as dez suítes
passam. **Não validado:** em movimento, atravessando a borda do volume.

## 2026-11-09 — Claude — Auditoria das luzes repetidas e abajur sem lâmpada

### Nenhuma das 8 repetições é acidente

Auditadas as 35 luzes pontuais, agrupando por posição (0,3 m de tolerância).
Há 8 pares no mesmo ponto, e **todos são de propósito**:

| onde | par | veredito |
|---|---|---|
| (0, 1, -13) | `memesis.gd` + `memesis_corpo.gd` | dois sistemas do mesmo vulto, cada um com seu brilho |
| escadaria, 3 pontos | `SpotLight3D` + `OmniLight3D` do `folded_stairs.gd` | facho mais preenchimento; padrão de iluminação, não duplicata |
| 2º andar, 4 salas | teto (`e=0,9`) + emergência vermelha (`e=0,4`, `visible = false`) | duas luzes diferentes no mesmo lugar |

Nenhuma delas projeta sombra, então nenhuma estava custando passada. Não mexi
em nada.

**Achado de brinde:** as 4 luzes de emergência do segundo andar **nunca
acendem** — `apply_state()` as põe em `visible = false` e nenhum outro trecho
as liga. São cenário para um recurso que não existe ainda. Invisível não
custa render, então ficam; quem for escrever o blecaute já tem elas prontas.

### Abajur de mesa deixou de ser luz

A luminária articulada da sala de segurança tinha uma `OmniLight3D` real
(alcance 2 m, energia 0,55). Virou `desk_glow()`: uma esfera de 4 cm,
emissiva, sem sombra, com energia 1,8 — acima do limiar de glow do ambiente
(1,1), então o bloom pega. Não ilumina o cômodo.

O ponto foi posicionado pela caixa real do modelo (`x -7,45..-7,05,
y 1,08..1,73, z -1,53..-1,17`): na primeira tentativa eu chutei e ele ficou
flutuando 12 cm à frente do abajur, solto no ar.

O material entra no registro de energia junto com as outras superfícies
emissivas, então apaga no blecaute como o resto. Luzes pontuais: 35 → 34.

**Validado:** a auditoria, a contagem e a captura `.local/abajur.png`, onde o
ponto está na cabeça do abajur; `check` limpo; as dez suítes passam.
**Não validado:** se o halo do bloom está do tamanho que você quer — o
ambiente tem `glow_intensity` baixo de propósito, e o que dá para subir sem
mexer no global é a energia da emissão.

### Correção da entrada acima: as luzes repetidas projetam sombra, sim

Na auditoria eu escrevi que "nenhuma delas projeta sombra, então nenhuma
estava custando passada". **Está errado.** Eu li o estado em tempo de
execução, já depois da oclusão ter desligado a sombra daquelas lâmpadas
naquele instante — não o que está escrito no código.

O que está autorado:

| | sombra no código |
|---|---|
| vulto, as duas (`memesis.gd`, `memesis_corpo.gd`) | não, documentado |
| escada de serviço: facho (`folded_stairs.gd:130`) | **sim** |
| escada de serviço: rebatida (`:143`) | **sim** |
| 2º andar: teto (`second_floor.gd:130`) | **sim** |
| 2º andar: emergência | não, e nunca acende |

Os três pares da escada de serviço são **seis luzes com sombra**, e custam
quando estão à vista. Lição para quem auditar daqui em diante: ler o valor em
jogo mede o efeito da oclusão, não a intenção do cenário. Para saber o que foi
autorado, leia o código.

O motivo de cada par, lido no código e não deduzido:

- **Vulto:** são duas criaturas alternativas, não uma com duas luzes. Cada uma
  traz seu brilho porque névoa não acende parede. As três nascem escondidas
  (`figure.hide()` e companhia) e o F5 escolhe uma, então os brilhos nunca
  estão acesos juntos.
- **Escada:** facho da arandela mais uma rebatida curta que acende a parede da
  própria luminária. Substituiu um omni de alcance largo que vazava pelos dois
  lances. Pulsam juntas no ritmo do reator, senão o fill sustenta o ambiente
  justo na batida em que o facho cai.
- **Segundo andar:** teto e emergência vermelha no mesmo ponto de cada sala.

**Candidato a otimização que sobrou:** a rebatida da escada tem 3,8 m e
energia 0,35 e mesmo assim projeta sombra. Fill quase nunca precisa. Tirar das
três corta metade das passadas da escada de serviço — mas aquela iluminação
foi afinada à mão, então é decisão de arte, e não foi medida nem mexida.
