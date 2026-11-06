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

**Validado:** renderiza sem erro de console no Chrome, com a arte do ceifador;
girar um osso deforma a regiao certa; o modo solido bate com o volumetrico.
**Pendente:** o esqueleto ainda deforma a arte de origem, nao os quadros do
modelo salvo. Com "usar modelo salvo" ligado, posar nao muda o que aparece.
**Não validado:** FPS real (medido só no pane do app, que vem throttled) e o
comportamento no Godot — nada foi portado ainda.

**Limite conhecido:** um PNG de frente não tem perfil lateral. Até ~±60° lê como
criatura; a 90° vira um borrão. Saídas: billboard (o volume sempre encara a
câmera), ou uma segunda silhueta de perfil para cruzar os dois volumes.
