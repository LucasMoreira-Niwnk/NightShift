# NIGHTSHIFT

Capítulo jogável de terror psicológico 3D em primeira pessoa para Windows, feito em Godot 4.0 com GDScript. Sem plugins externos ou APIs durante o jogo.

## Abrir e jogar

- Clique em `Abrir Editor.cmd` para abrir o projeto diretamente no Godot.
- No editor, pressione F6 para executar a cena aberta ou F5 para o projeto.
- Clique em `Jogar.cmd` para executar o protótipo diretamente.
- WASD move, mouse olha, E interage com portas e computador. F liga/desliga a lanterna. Esc pausa e libera o mouse.

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

Aproxime-se do monitor na sala de segurança e pressione E. O terminal apresenta três câmeras ao vivo: recepção, corredor e arquivo. Troque com 1/2/3, setas ou pelos botões. Z alterna o zoom. Os botões confirmam a inspeção inicial, reportam a categoria escolhida e desligam o monitor. E, Esc ou Sair devolvem o controle do personagem. O primeiro Esc sai do computador; fora dele, Esc abre a pausa.

O monitor físico e a interface usam o mesmo SubViewport de 640×360: somente a câmera selecionada é renderizada. O mundo continua ativo durante o monitoramento, mas movimento e lanterna ficam bloqueados até sair do terminal. As texturas de piso, parede e madeira estão incluídas em `game/assets/textures/`; modelos em `game/assets/models/`. Todos funcionam offline, sem plugins. Créditos e licenças estão em `game/assets/ART_CREDITS.md`.

Após atualizar os arquivos, aguarde a importação de texturas/modelos no editor antes de pressionar F5. Materiais usam cor, normal OpenGL e rugosidade com mapeamento em escala de mundo. O renderizador é Forward+ (Vulkan), exigido pelo FogVolume do Mêmesis.

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

Capítulo 1: chegada, segurança, ronda, cadeira, técnica, figura, duplo e relatório final. Inclui ambiência/efeitos sonoros, diário e checkpoints. Dublagem, animações humanas detalhadas, mixagem e testes de ritmo com jogadores ainda estão pendentes; os capítulos seguintes não estão implementados.

## Trabalho em equipe

Repositório: https://github.com/LucasMoreira-Niwnk/NightShift

Consulte [CONTRIBUTING.md](CONTRIBUTING.md) para configurar outra máquina, criar branches, validar e enviar commits por pull request.
