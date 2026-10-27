# Registros Incompletos — integração dos dois capítulos

Referência: [roteiro do capítulo 2](ROTEIRO_CAPITULO_2.md). A expansão preserva Godot 4.0/Compatibility, os materiais e modelos já incluídos. Não exige downloads em execução.

## O reparo do capítulo 1 mudou

O aviso ao lado do quadro não contém mais a resposta, nem na geometria, nem no diário. A primeira inspeção identifica F1 queimado, desarma os circuitos e autoriza acesso de manutenção ao segundo andar. Isso antecipa a exploração de administração/TI; no capítulo 2, a autorização passa a ser uma inspeção do sistema de vigilância.

Percurso (spoilers):

1. Inspecione o painel na técnica. Isole todos os circuitos e examine o suporte F1 para retirar o fusível queimado.
2. Suba a escadaria ao fundo do corredor usando o crachá. Administração fica à esquerda, perto do palier; TI fica à esquerda, mais ao fundo.
3. Encontre a ordem de manutenção sobre a mesa da administração. Ela identifica o calibre e explica a sequência por nomes dos circuitos.
4. Busque a reposição na bancada da TI. Há fusíveis de 10 A e 20 A; o de 10 A não serve para F1 e não consome a reposição correta.
5. Retorne pela escada, instale o fusível de 20 A com o painel isolado e execute a partida: arquivo (C), recepção (A), corredor (B). D permanece desligado.
6. A ordem errada não conclui o reparo, mesmo com A/B/C ligados. Use Isolar todos para recomeçar. D dispara a proteção, sem destruir a reposição nem impedir outra tentativa.

Nota, fusível, cartucho retirado, instalação e sequência são persistidos. Um save antigo com energia já restaurada continua válido; para experimentar o novo reparo inteiro, comece uma nova partida.

## Nove cenas do capítulo 2

| Estado interno | Cena e condição de avanço |
| --- | --- |
| 9 | Reexaminar o relatório, tentar a ligação na recepção e confirmar o alerta CAM-04 no terminal. |
| 10 | Usar o crachá e alcançar o corredor do segundo andar pela escada física. |
| 11 | Inspecionar a câmera alimentada e seu cabo; obter a etiqueta do rack. A porta fechada responde às batidas, e a segunda resposta vem da porta atrás do jogador. |
| 12 | Na TI, cruzar a etiqueta com o patch panel 2B e selecionar a porta 07. Erros permitem nova tentativa. |
| 13 | Reproduzir o buffer 01:03 enquanto o relógio ainda marca 01:02. Ao sair da TI, E na porta permite segurá-la; afastar-se permite a batida prevista. A escolha é salva. |
| 14 | Cruzar ata, controle de acesso e arquivo CAM-05. Henrique consta na ata, mas não entrou. A sexta cadeira se move somente no feed; a cadeira física permanece parada. |
| 15 | Iluminação de emergência e escadaria principal bloqueada. A planta indica a saída oeste da administração. Voz de Daniel e sombra na janela; mensagem da escada desaparece ao olhar de novo após atravessar. |
| 16 | Descer pela escada de serviço, entrar na segurança pela passagem lateral, assistir ao arquivo de 15/11 e tentar apagá-lo. O arquivo protegido revela MÍMESIS. |
| 17 | Ler a ocorrência 002, cujo texto distingue a decisão da porta, e ouvir a resposta de Augusto. |
| 18 | 02:00; perfil comportamental 68%, referência Henrique, imagem impossível na CAM-04 e encerramento. O capítulo 3 permanece fora do escopo. |

Após o final do capítulo 1, o botão Continuar inicia o segundo capítulo sem recarregar o mapa ou apagar inventário, documentos e progresso. As escadas têm degraus visuais e uma rampa de colisão contínua; não há teleporte entre pisos. A passagem de serviço se conecta a uma nova porta na parede oeste da segurança.

## CCTV e gravações

CAM-04 cobre o corredor administrativo e CAM-05 a reunião. Antes do reparo de rede, os feeds do segundo andar ficam sem sinal. Teclas 1–5, setas e botões selecionam canais. A estação da TI e o projetor da reunião abrem a mesma interface de investigação.

As cinco câmeras têm modelos montados no cenário. A origem da lente, a direção do feed e o enquadramento inicial dos arquivos vêm de `security_camera_layout.gd`; a CAM-05 fica no canto alto da sala de reuniões. O projetor é uma estação de consulta separada. Ao abrir a investigação a partir do CCTV, o diálogo aparece imediatamente e mantém o cursor livre; fechar o diálogo retorna ao monitor, e sair do monitor só devolve controle ao personagem quando nenhum diálogo permanece aberto.

Os arquivos são reconstruções animadas em uma World3D separada, a partir de uma cópia sem scripts do cenário. Possuem data, duração, pausa, avanço/retorno e zoom; são identificados como ARQUIVO/RECONSTRUÇÃO. O mundo da partida não é rebobinado. Os três arquivos mostram saída da TI/porta, cinco entradas da reunião e chegada de outro operador na recepção. Somente um viewport de transmissão é atualizado por vez; os três monitores auxiliares retêm quadros dos canais inspecionados.

## Persistência e verificação

O mesmo save versão 1 agora aceita estados 0–18, preservando saves anteriores. As flags incluem reparo, calibre, nota, conectividade, arquivos assistidos, `future_event_resisted`, Henrique, rota e descoberta de MÍMESIS. Eventos interrompidos de porta/final retomam a partir do objetivo correspondente; um arquivo interrompido pode ser reproduzido novamente.

`tools/godot.ps1 -Mode check` e `-Mode test` verificam os scripts e o percurso integrado. A cobertura inclui subida/descida real com o controlador, reposição incompatível, sequência errada, estados persistentes, rede, isolamento das gravações, ambas as escolhas da porta, investigação, bloqueio da escada e retorno pela passagem de serviço. Os testes usam posições controladas entre pontos; não equivalem a uma partida manual contínua.

Ainda precisam de avaliação com jogadores: orientação na nova planta, legibilidade sob CRT, conforto da escada, mixagem e ritmo. As durações do roteiro não foram aferidas. Humanos e gravações usam representação estilizada; dublagem e animação humana detalhada continuam pendentes. As falas são legendadas/transcritas; ambiência, passos, batidas e equipamento possuem som.
