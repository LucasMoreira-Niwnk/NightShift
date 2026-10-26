# Primeiro ato — critérios e implementação

Escopo: as oito cenas de **O Primeiro Turno**, conforme o roteiro fornecido pelo autor e preservado em [ROTEIRO_CAPITULO_1.md](ROTEIRO_CAPITULO_1.md). Os tempos indicados são metas de direção, não duração aferida nem temporizadores obrigatórios.

| Cena | Implementação jogável |
| --- | --- |
| Chegada | Início diante da entrada, abertura em fade, motor e porta do carro sugeridos por som, entrada com colisão, protocolo, crachá/chave, relógio 23:59 → 00:00 e um único toque do telefone. |
| Segurança | Terminal inicialmente desligado, gravador com transcrição integral, três monitores físicos, três feeds selecionáveis, zoom e identificação de relógio/porta/cadeira com correção sem penalidade. |
| Ronda | Saída de emergência, arquivo, livro e manutenção opcional. No retorno pelo corredor, três oscilações espaçadas e passos atrás do jogador; evento único. Escadaria gradeada com trecho visível e segundo andar interditado. |
| Cadeira | Anomalia coerente na CAM-03 e no arquivo, classificação e histórico, marcas físicas no piso, movimento acompanhado de arrasto quando o jogador desvia o olhar; alternativa após nove segundos. |
| Técnica | Porta aberta, corredor apagado, leitura do diagrama, quatro disjuntores e proteção de D, três batidas na porta e mensagem do rádio. A interferência da CAM-02 começa depois da energia restaurada. |
| Figura | Presença no feed, três aproximações somente ao trocar de câmera, última aproximação junto à lente, perda de sinal, passos e movimento da maçaneta com a folha da porta fechada. Sem combate ou morte. |
| Segundo Daniel | Duplo visível apenas no CCTV, percurso até o balcão, envelope na mão e olhar para a lente. Reflexo composto com duas silhuetas sobre o vidro escuro; retorno mostrando a segurança vazia. Interferência e lembrete se o jogador demora. |
| Relatório | Impressora física e som, documento datado de 11/11, assinatura, telefone com visor RAMAL 000. Pode investigar ou ignorar; a ligação termina sem atendimento. Três falas finais, relógio 01:00, fade e conclusão. |

## Sistemas de apoio

- `event_director.gd`: coordena gatilhos únicos, olhar, alternativa temporal, telefone e cancelamento de sequências ao carregar checkpoint.
- `soundscape.gd`: sintetiza PCM original em memória para chuva, ambiente elétrico, passos, arrasto, telefone, batidas, rádio e impressora. Efeitos posicionais e volumes independentes em Esc > Áudio e legendas, gravados em `user://audio.cfg`.
- Diário em J: documentos coletados, objetivo, ocorrências e transcrição das mensagens do turno.
- Checkpoints: flags, portas, eventos, documentos, mensagens, posição, orientação e estado ligado/desligado da lanterna. Saves anteriores de versão 1 continuam aceitos; documentos conhecidos são recuperados das flags.
- CCTV: um único SubViewport ativo. Os três monitores físicos retêm a última imagem inspecionada; apenas o selecionado é ao vivo. Não são três câmeras renderizando simultaneamente.

## Validação e limites

`tools/godot.ps1 -Mode check` analisa os scripts; `-Mode test` percorre o capítulo e verifica colisão da entrada, puzzles, eventos, estado da lanterna, documentos e recarga de checkpoints durante a cadeira e o final. Testa as duas decisões do telefone. Os testes usam posições controladas entre pontos e não medem a duração de uma partida.

A dublagem de Augusto e Daniel ainda precisa ser gravada e editada. As falas completas estão em transcrições/legendas; efeitos e ambiência já têm reprodução sonora. A interpretação vocal, animação humana detalhada, mixagem final, teste com novos jogadores e aferição dos 30–35 minutos continuam pendentes. Não há afirmação de qualidade comercial ou duração garantida.
