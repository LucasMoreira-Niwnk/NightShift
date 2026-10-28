# NIGHTSHIFT

Capítulo jogável de terror psicológico 3D em primeira pessoa para Windows, feito em Godot 4.0 com GDScript. Sem plugins externos ou APIs durante o jogo.

## Abrir e jogar

- Clique em `Abrir Editor.cmd` para abrir o projeto diretamente no Godot.
- No editor, pressione F6 para executar a cena aberta ou F5 para o projeto.
- Clique em `Jogar.cmd` para atualizar a branch atual, preparar o cache e iniciar o jogo.
- WASD move, mouse olha, E interage com portas e computador. F liga/desliga a lanterna. Esc pausa e libera o mouse.

### Editar a mão e a lanterna visualmente

Abra `game/scenes/mao_lanterna.tscn` (no Godot: `res://scenes/mao_lanterna.tscn`). A cena contém o braço, a manga, a lanterna, o esqueleto e a pose `Pegada`. F6 mostra o enquadramento em primeira pessoa com câmera e iluminação de prévia. O jogador instancia essa mesma cena ao equipar a lanterna.

- Selecione `MaoLanterna` e altere seu Transform para mudar a posição do conjunto na tela. `ArmRig` controla o alinhamento do braço; `Lanterna` pode ser movida/girada independentemente para encaixar na abertura da pegada.
- Para os dedos, selecione `PoseAnimation`, escolha a animação **Pegada** e coloque o cursor no tempo **0**. Selecione `ArmRig/arms/Skeleton3D`, escolha o osso do dedo e ajuste a rotação no editor 3D/Inspetor. Insira ou atualize a chave de rotação desse osso no tempo 0 e salve a cena. As trilhas `finger_thumb1.r`, `finger_thumb2.r` e `finger_thumb3.r` controlam o polegar.
- A pose estática também aparece ao abrir a cena. Para mudar o resultado no jogo, atualize as chaves de **Pegada**: uma alteração temporária no osso sem atualizar a animação será substituída pela pose salva ao executar.
- `Preview` serve apenas à edição/F6: sua câmera, ambiente e luz são removidos ao equipar no jogo. Mantenha as malhas na camada visual 2 para não aparecerem no CCTV nem gerarem sombras no cenário. A origem do feixe é recalculada pela lente da lanterna ao iniciar.

As malhas nativas em `game/assets/models/viewmodel/` derivam dos modelos CC0 já incluídos (WRAD Arms e Innerscene), com os materiais locais e a manga do projeto. Não é necessário atualizar o Godot 4.0 nem instalar um plugin para editar essa cena.

### Expansão — segundo andar e Registros Incompletos

O reparo da energia agora exige exploração: a ordem de manutenção está na administração do segundo andar e o fusível compatível na sala de TI. Retire o cartucho queimado com os circuitos isolados, instale a reposição e siga a sequência encontrada na nota. O aviso junto ao painel não contém a solução.

Após concluir a primeira hora, escolha **Continuar — Registros Incompletos**. O capítulo 2 inclui nove cenas, CAM-04/CAM-05, diagnóstico de rede, gravações com pausa/avanço/zoom, decisão sobre a porta prevista, investigação de Henrique e uma saída alternativa pela administração/escada de serviço. As escadas são contínuas e transitáveis; o diário e os saves acompanham ambos os capítulos. Use Tab ou M no segundo andar para consultar a nova planta.

Percurso, critérios, compatibilidade de saves e limites: [docs/CHAPTER_2.md](docs/CHAPTER_2.md). Para experimentar o reparo novo desde o início, use Nova partida; checkpoints antigos que já restauraram a energia continuam após essa tarefa.

### Prédio empilhado e exterior

O segundo andar ocupa a projeção do térreo, a 4,2 m de altura. A escada principal e a de serviço têm dois lances com retorno de 180°, patamar, corrimãos, fechamento lateral e colisão contínua. A rota de manutenção e os eventos dos dois capítulos acompanham essa implantação; CAM-04/CAM-05 e seus arquivos usam as posições das lentes no novo piso.

A chegada começa no estacionamento externo. Há marquise aberta, fachada dos dois pavimentos, porta de vidro, janelas com vãos reais e colisão, peitoris, caixilhos, cobertura, calhas, equipamentos no telhado, carros, bancos, canteiros, árvores, grades, postes, drenagem e chuva. As janelas mostram o cenário do próprio jogo. O exterior usa geometria e materiais locais; não exige downloads.

Checkpoints anteriores recebem migração de posição para o novo piso ou um patamar seguro da escada, mantendo objetivos e inventário. Para ver a nova chegada, use **Nova partida**. A planta de emergência também foi atualizada. Detalhes técnicos e cobertura: [docs/BUILDING_LAYOUT.md](docs/BUILDING_LAYOUT.md).

### Arte e apagão do edifício

O arquivo tem estantes metálicas com travessas, ferrugem, livros individuais de volumes/cores variados e etiquetas. O terminal mantém os feeds e ganhou gabinete CRT profundo, grelhas, parafusos, suporte dos três monitores, cabos, torre e nobreak. A vegetação usa folhas curvas, caules e partes secas; os sedãs têm vidros inclinados, pilares, portas, retrovisores, rodas, frisos e ferrugem. Tábuas em alguns vãos, trepadeiras, folhas caídas e fissuras no asfalto reforçam o abandono externo.

Pisos e paredes variam por ambiente: lajota clara na recepção/corredores, vinílico gasto na segurança/TI, piso terroso no arquivo, concreto na técnica/escadas e tábuas na administração/reuniões. Os materiais agora combinam seis conjuntos fotográficos CC0 do Poly Haven — reboco rachado, alvenaria exposta, fachada com musgo, concreto gasto, asfalto com detritos e terra com folhas — com poeira acumulada nos cantos, manchas e escorridos de umidade. As imagens estão em `game/assets/textures/decay/`, com fontes e licenças registradas; não há downloads durante o jogo.

Na falha do disjuntor do capítulo 1 e no apagão do capítulo 2, as luminárias dos dois pisos, escadas e terreno, incluindo as lâmpadas emissivas, se apagam. A lanterna continua a bateria. O terminal preserva CCTV/documentos pelo nobreak, mas seu halo de luz também apaga. A iluminação natural e o fenômeno Mêmesis seguem independentes da rede elétrica. O reparo completo do fusível/disjuntores restaura a alimentação; checkpoints preservam a condição de apagão.

### Capítulo 1 — O Primeiro Turno

A partida começa diante da entrada do Vesper. Abra a porta, leia o envelope no balcão, entre na segurança e siga os objetivos no alto da tela. Pegue a lanterna na mesa para ver a mão e o item em primeira pessoa. A sequência contém oito cenas, três puzzles, anomalias, documentos e conclusão. Esc permite salvar/carregar checkpoint e ajustar o áudio. J abre o diário com documentos e mensagens coletados.

O primeiro ato agora inclui eventos de olhar e de retorno da ronda, entrada e escadaria, terminal inicialmente desligado, identificação dos elementos nas imagens, sons posicionais, interferências, impressora e escolha de investigar ou ignorar o telefone no encerramento. Veja a matriz de implementação e as limitações em [docs/ACT_1_ACCEPTANCE.md](docs/ACT_1_ACCEPTANCE.md).

O cenário utiliza texturas PBR 1K do ambientCG, modelos glTF texturizados do Poly Haven e modelos GLB do Kenney Furniture Kit. Cadeira, mesas, rádio, cadernos, luminária de mesa e armário utilizam os modelos do Poly Haven. O braço em primeira pessoa utiliza o modelo rigado e texturizado WRAD Arms (CC0), com pose de pegada; a lanterna é um modelo cilíndrico da Innerscene (CC0). Monitor, telefone e silhuetas possuem geometria mais arredondada. A iluminação é mais escura, com sombras e pontos de luz localizados. Chuva, zumbido, passos, telefone, arrasto, batidas, rádio e impressora possuem efeitos sonoros; as falas permanecem legendadas, aguardando dublagem. O roteiro de 30–35 minutos ainda não representa a duração medida desta versão.

Os objetos da mesa foram separados para evitar sobreposição entre teclado, mouse, rádio, lanterna e relatório. Papéis e livros apoiam-se no tampo; livros decorativos usam as alturas reais das prateleiras; o diagrama elétrico é montado verticalmente. O feixe da lanterna parte da lente e aponta para a mira, com balanço reduzido ao caminhar.

### HUD

A HUD mostra o objetivo e o progresso das oito cenas no canto superior esquerdo; cômodo, horário narrativo e estado real da lanterna no direito. Os equipamentos coletados aparecem embaixo. A mira reage quando há algo interativo e exibe o comando E. Mensagens possuem fundo de contraste e desaparecem após alguns segundos; o objetivo permanece disponível. Documentos e pausa ocultam a HUD para facilitar a leitura. Não há indicadores fictícios de vida ou bateria.

Veja `docs/CHAPTER_1.md` para o percurso completo de validação, arquitetura, checkpoints e limitações.

### Planta e relógios

Há plantas do térreo emolduradas nas paredes da recepção e da segurança. Mire na planta e pressione E para ampliá-la; E ou Esc fecha a consulta. Cada exemplar marca seu próprio ponto de instalação com “Você está aqui”. Os relógios da recepção, segurança e corredor têm ponteiros e leitura digital, sincronizados com os horários narrativos 23:57, 00:00 e 01:00. O relógio da recepção continua visível pela CAM-01 para a inspeção inicial.

### Computador e câmeras

Aproxime-se do monitor na sala de segurança e pressione E. Troque canais com 1–5, setas ou pelos botões. As três câmeras do térreo estão disponíveis inicialmente; CAM-04/CAM-05 são liberadas pelo reparo de rede no capítulo 2. Z alterna o zoom, inclusive nos arquivos. A interface oferece inspeção, reporte e, na segunda hora, reprodução, pausa, navegação temporal e investigação. E, Esc ou Sair devolvem o controle do personagem. O primeiro Esc sai do computador; fora dele, Esc abre a pausa.

O monitor físico e a interface usam o mesmo SubViewport de 640×360: somente a câmera selecionada é renderizada. O mundo continua ativo durante o monitoramento, mas movimento e lanterna ficam bloqueados até sair do terminal. As texturas de piso, parede e madeira estão incluídas em `game/assets/textures/`; modelos em `game/assets/models/`. Todos funcionam offline, sem plugins. Créditos e licenças estão em `game/assets/ART_CREDITS.md`.

Após atualizar os arquivos, aguarde a importação de texturas/modelos no editor antes de pressionar F5. Materiais usam cor, normal OpenGL e rugosidade com mapeamento em escala de mundo. O renderizador é Forward+ (Vulkan), exigido pelo FogVolume do Mêmesis.

Arquivos `.import` guardam as configurações compartilhadas; o cache dentro de `game/.godot/` é gerado em cada computador e não é versionado. Atualizações das configurações de compressão também exigem reimportar texturas já existentes. O atalho prepara esse cache automaticamente. Como alternativa, abra `Abrir Editor.cmd` e aguarde a importação terminar antes de pressionar F5.

O atalho `Jogar.cmd` executa `git pull --ff-only` na branch atual e depois abre o importador do Godot em segundo plano. O jogo só inicia quando a varredura termina e os arquivos importados são validados. O cache é incremental: não é apagado a cada início. Os modos `check` e `test` também preparam as importações, sem atualizar o Git.

Se houver alterações locais, o atalho preserva o trabalho, avisa que pulou a atualização do Git e joga a versão local. Ele não troca de branch, não faz stash/reset e não cria commits. Sem upstream ou sem Git, também utiliza a versão local com aviso. Falha de rede, autenticação ou histórico divergente interrompe a atualização; use `-Offline` para optar explicitamente pela versão local. Para preparar sem abrir o jogo, use `-Mode prepare`.

```powershell
# Jogar a versão local, atualizando apenas o cache:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode run -Offline
```

Falhas na preparação permanecem visíveis na janela do atalho. Os logs estão em `.local/launch-import.log` e `.local/launch-import-errors.log`. O helper em `game/addons/launch_import/` só executa a preparação quando iniciado pelo launcher; no editor normal fica inativo. Ele usa o [EditorFileSystem do Godot 4.0](https://docs.godotengine.org/en/4.0/classes/class_editorfilesystem.html).

### Abrir pelo PowerShell

Os arquivos `.cmd` devem ser executados com duplo clique no Explorador de Arquivos; não cole seu conteúdo no PowerShell. Para abrir o editor pelo PowerShell, na pasta do repositório, execute:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode editor
```

Para jogar diretamente, use o mesmo comando trocando `-Mode editor` por `-Mode run`.

Cada desenvolvedor configura seu próprio executável, sem alterar o script compartilhado. O atalho procura, nesta ordem: variável `NIGHTSHIFT_GODOT`, arquivo local `.local/godot-path.txt`, comando `godot` no PATH e a instalação portátil Godot 4.0 na pasta Downloads do usuário. Veja o passo a passo em `CONTRIBUTING.md`.

O renderizador era Compatibility, escolhido para reduzir exigências de GPU, e migrou para Forward+ porque o corpo do Mêmesis é um FogVolume, que só existe nesse backend. A troca passa a exigir GPU com Vulkan. O preset mobile segue em `gl_compatibility`, onde o vulto não aparece. Godot 4.0 é a versão local confirmada; uma atualização da engine deve ser validada em uma tarefa separada.

Os atalhos mantêm configurações e dados do editor na pasta local `.local/`, ignorada pelo Git. As variáveis APPDATA/LOCALAPPDATA são ajustadas somente no processo iniciado pelo atalho. A importação direta de `.blend` está desativada; modelos podem ser importados como `.glb` sem instalar Blender.

## Validação

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode check
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode test
```

O modo check analisa todos os scripts. O modo test abre uma janela temporária e verifica a progressão das oito cenas, os três puzzles, alcance de itens por raycast, renderização CCTV, checkpoints e conclusão. Ele usa posições controladas, sem simular uma partida inteira caminhando. Pré-visualizações são salvas em `.local/`. O percurso manual completo está em `docs/CHAPTER_1.md`.

## Exportação

Para gerar um executável, instale os export templates da mesma versão 4.0.stable pelo menu Editor > Manage Export Templates. Depois use Project > Export > Add > Windows Desktop. O editor não exige esses templates para rodar o projeto. Não há integração Steam nesta etapa.

## Escopo atual

Capítulos 1 e 2 conectados pelo segundo andar: reparo com nota/fusível, três puzzles de investigação do segundo capítulo, cinco câmeras, arquivos reconstruídos e decisões persistentes. Dublagem, animações humanas detalhadas, mixagem e testes de ritmo com jogadores ainda estão pendentes; o capítulo 3 não está implementado.

## Trabalho em equipe

Repositório: https://github.com/LucasMoreira-Niwnk/NightShift

Consulte [CONTRIBUTING.md](CONTRIBUTING.md) para configurar outra máquina, criar branches, validar e enviar commits por pull request.
