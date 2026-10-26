# Capítulo 1 — O Primeiro Turno

Referência narrativa: https://chatgpt.com/share/6adf891d-6b38-83e8-8498-2c3ca91ea5b1

## Versão básica implementada

O capítulo utiliza oito estados narrativos e uma planta contínua com recepção, segurança, corredor, arquivo e sala técnica. As superfícies usam texturas PBR do ambientCG. Móveis, cadeira, estantes, livros decorativos, rádio, teclado, mouse e acessórios utilizam modelos GLB CC0 do Kenney Furniture Kit. Portas, livros narrativos, documentos, detalhes do telefone e quadro elétrico são modelados no projeto. Personagens e mão continuam simples. Não há combate, morte ou perseguição. Os sons e as falas são representados por textos entre colchetes e legendas persistentes. Animação realista e áudio ficam para outra etapa.

Os 30–35 minutos do roteiro são uma meta para a versão final. Este protótipo pode ser concluído mais rapidamente: não impõe esperas artificiais para atingir essa duração.

## Percurso de validação (contém spoilers)

1. Na recepção, leia o envelope sobre o balcão. Ele concede crachá e chave. Feche o documento com E, Esc ou o botão.
2. Entre pela primeira porta à esquerda no corredor. Pegue a lanterna amarela e leia a gravação 001, na mesa. Use E no monitor. Confira CAM-01 (relógio), CAM-02 (porta técnica fechada), CAM-03 (cadeira diante da mesa) e clique **Confirmar inspeção** em cada uma.
3. Saia do computador. Abra o arquivo, à direita, e leia o livro sobre a mesa. Inspecione a saída de emergência, no fundo do corredor. Retorne ao terminal. O registro de manutenção é opcional.
4. Veja a cadeira deslocada na CAM-03. Selecione **Objeto deslocado** e clique **Reportar**. Vá ao arquivo, mire na cadeira perto da porta e pressione E. Ela se move. Volte ao terminal; a cadeira retorna ao lugar original.
5. A porta técnica abre e a iluminação do corredor apaga. Vá à técnica, à esquerda no fundo. Leia o diagrama e use o quadro elétrico. Deixe A/B/C ligados e D desligado; confirme. D sempre se desarma se for ligado por engano. A porta se fecha durante o evento das batidas; basta abri-la. Retorne ao terminal.
6. Veja a figura na CAM-02 e reporte **Presença não autorizada**. Alterne da CAM-02 para outra câmera e volte, três vezes. A figura avança somente quando você muda de câmera. A transmissão cai, a porta da segurança fecha e a maçaneta se move. Aguarde alguns segundos, sem combate.
7. A CAM-01 mostra outro Daniel na recepção. Após o breve reflexo composto, o feed passa a mostrar a segurança vazia. Clique **Desligar monitor**, como indicado no protocolo. O desligamento também pode ser feito antes do reflexo terminar.
8. Leia o relatório impresso à direita do monitor e clique **Encerrar capítulo**. O telefone da recepção é opcional. A tela final conclui o capítulo e permite recomeçar ou sair.

## Sistemas

| Arquivo | Responsabilidade |
| --- | --- |
| `main.gd` | Montagem do projeto, prioridade do input, bloqueio de movimento |
| `chapter.gd` | Oito estados, objetivos, validação dos puzzles, eventos e checkpoints |
| `chapter_data.gd` | Documentos e conteúdo narrativo |
| `chapter_world.gd` | Planta, portas, evidências, cadeira, iluminação e figuras |
| `chapter_ui.gd` | Documentos, legendas, objetivos, disjuntores, pausa e conclusão |
| `computer.gd` | Três feeds ao vivo, zoom, reporte, histórico e desligamento |
| `player.gd` / `hand.gd` | FPS, raycast, mão em primeira pessoa e lanterna |
| `art.gd` / `materials.gd` | Modelos GLB, detalhes de objetos e materiais PBR |
| `ui_style.gd` / `reticle.gd` | Tema da interface, cartões, botões e mira contextual |
| `rounded_mesh.gd` | Superfícies com cantos arredondados para objetos próximos |
| `chapter_tests.gd` | Teste de progressão, alcance dos itens e persistência |

O monitor usa um SubViewport de 640×360. Sua câmera renderiza as camadas 1 e 3; a mão e a superfície do monitor usam a camada 2 e ficam fora do feed, evitando recursão. O reflexo é uma composição de interface, sem reflexo físico.

## Checkpoints

O progresso é salvo ao concluir objetivos/interagir. Esc oferece salvar e carregar manualmente. Nova partida reinicia a cena; o checkpoint anterior só é substituído quando a nova partida registra progresso. Uma partida recém-aberta começa do início; use Esc > Carregar checkpoint para continuar.

O arquivo `user://chapter1.json` preserva estágio, objetivos, documentos coletados, inspeções, histórico, disjuntores, avanço da figura, posição, orientação e portas. Ao usar os atalhos ele fica em `.local/AppData/Godot/app_userdata/NIGHTSHIFT/`. A abertura direta do editor pode usar o perfil padrão do Windows. Os testes usam exclusivamente `chapter1-test.json`.

## Verificação

Execute `tools/godot.ps1 -Mode check` e `-Mode test`. O teste percorre os oito estados com interações de gameplay, confirma os três puzzles, rejeição de reporte incorreto, idempotência de reportes, restauração de checkpoint, coleta da lanterna, alcance por raycast e renderização das câmeras. Também usa o controle real do personagem para verificar bloqueio da porta fechada e passagem pelas portas da segurança, arquivo e técnica. O restante usa posições controladas para alcançar os pontos; não substitui uma partida manual caminhando pela planta. As prévias são gravadas em `.local/chapter1-*.png`.

Validação manual restante: percorrer toda a planta sem reposicionar o personagem, avaliar orientação dos objetivos com jogadores novos, mouse nos menus, ritmo das aparições e conforto da mão/lanterna. Ainda não houve teste externo nem medição formal de desempenho.
