# NIGHTSHIFT — Capítulo 2: Registros Incompletos

Roteiro narrativo e técnico v1.0 | Terror psicológico 3D | Godot 4



O segundo capítulo de NIGHTSHIFT deve aprofundar o mistério do Edifício Vesper, expandir a exploração para o segundo andar e transformar o sistema de câmeras em uma ferramenta essencial para resolver enigmas.

No primeiro capítulo, Daniel descobriu que as câmeras registravam acontecimentos impossíveis. Agora, ele perceberá algo ainda mais perturbador: **as gravações parecem mostrar acontecimentos antes de eles ocorrerem.**

O terror continua psicológico, com sustos pontuais e uma sensação crescente de estar sendo observado.

Duração-alvo

# 35–45 min

Cenas

# 9

Puzzles

# 3

Sustos principais

# 3

---

Intenção narrativa

O jogador deixa de confiar nas câmeras, mas passa a depender delas para avançar.

## 1. Sinopse — A segunda hora

São 01h00.

Após encontrar um relatório de ocorrência assinado por ele mesmo, Daniel tenta utilizar o telefone da recepção para entrar em contato com a empresa responsável por sua contratação.

A ligação não completa.

O terminal de segurança exibe uma nova mensagem:

> **FALHA DE COMUNICAÇÃO — CAM-04**
>
> Localização: Segundo andar, corredor administrativo.
>
> Última transmissão: 01h03.
>
> Inspeção presencial obrigatória.

Daniel percebe que o sistema está registrando horários que ainda não chegaram.

Quando tenta ignorar a mensagem, o supervisor Augusto entra em contato pelo rádio:

> "Daniel, tivemos uma falha no segundo andar. Preciso que você verifique o equipamento."
>
> "A equipe de manutenção não estará disponível até o amanhecer."
>
> "Não se preocupe. É apenas uma câmera."

Daniel responde:

> "Augusto, encontrei um relatório com meu nome. De três dias atrás."
>
> "Você já trabalhou aqui antes?"

Silêncio.

> "Daniel... concentre-se na câmera."

A transmissão é encerrada.

O objetivo inicial parece simples: restaurar a CAM-04. Mas, ao explorar o segundo andar, Daniel encontra evidências de que os sistemas de vigilância eram utilizados em experimentos comportamentais.

---

## 2. Expansão do cenário

O Capítulo 2 reutiliza as áreas do térreo e libera uma nova região do segundo andar.

[Planta conceitual: escadaria, administração, corredor CAM-04, TI, reuniões e serviço.]

Planta conceitual do segundo andar. As salas compartilham módulos de paredes, portas, iluminação e mobiliário para reduzir o custo de produção.

| Ambiente | Função no gameplay |
|--------|--------|
| Escadaria | Transição entre térreo e segundo andar |
| Corredor administrativo | Principal área de anomalias e aparições |
| Administração | Documentos e pistas sobre o MÍMESIS |
| Sala de TI | Puzzle de conectividade da CAM-04 |
| Sala de reuniões | Investigação de eventos registrados pelas câmeras |

**Novas câmeras:** CAM-04 (corredor administrativo) e CAM-05 (sala de reuniões). A CAM-05 será ativada durante a história.

## 3. Linha do tempo

---

# 4. Roteiro completo — Cena por cena

## Cena 1 — Uma chamada não completada

Duração: 4 minutos | Local: térreo | Intensidade: 2/5



O capítulo começa exatamente após o encerramento do Capítulo 1.

Daniel está na sala de segurança, diante do relatório impossível. O relógio marca 01h00.

**Objetivos:**

1. Examinar novamente o relatório.
2. Tentar contatar o supervisor.
3. Verificar o alerta da CAM-04.
4. Obter autorização para acessar o segundo andar.

**Diálogo:**

Daniel pega o telefone.

> **Daniel:** "Alô? Central de segurança? Meu nome é Daniel Reis. Estou no Edifício Vesper."
>
> **Operadora automática:** "Sua ligação não pode ser completada. O número informado não existe."
>
> **Daniel:** "Como assim não existe?"

O rádio começa a emitir estática.

> **Augusto:** "Daniel, preciso que verifique a câmera do segundo andar."
>
> **Daniel:** "Antes disso, quero saber o que está acontecendo aqui."
>
> **Augusto:** "Apenas faça seu trabalho."
>
> **Daniel:** "Encontrei um relatório assinado por mim. Antes de eu começar."
>
> **Augusto:** "..."
>
> **Augusto:** "Você recebeu seu crachá, não recebeu? Ele libera a escada."

A transmissão termina.

**Evento ambiental:** o terminal exibe `ÚLTIMA TRANSMISSÃO CAM-04 — 01:03:17`, embora o relógio esteja em 01h01.

**Gatilho:** `C2_S1_CAMERA_ALERT_ACKNOWLEDGED`.

## Cena 2 — O segundo andar

Duração: 4 minutos | Local: escadaria e corredor | Intensidade: 2/5



Daniel utiliza o crachá para desbloquear a escadaria.

Ao subir, percebe que as paredes apresentam sinais de abandono mais avançados do que no térreo.

O segundo andar parece estar fechado há anos.

**Objetivos:**

1. Desbloquear a escadaria.
2. Chegar ao segundo andar.
3. Localizar a CAM-04.
4. Examinar o corredor.

**Evento de estranhamento:**

No meio da escadaria, Daniel ouve passos acima dele.

Se parar, os passos também param.

Se continuar subindo, os passos recomeçam.

Ao alcançar o segundo andar, não há ninguém.

Esse comportamento é implementado por um sistema simples que reage à velocidade do jogador, sem necessidade de NPC.

**Documento opcional — Aviso Administrativo**

> ACESSO RESTRITO — SEGUNDO ANDAR
>
> Por determinação da diretoria, o acesso ao setor administrativo está suspenso até a conclusão da auditoria.
>
> Funcionários que encontrarem inconsistências nos registros de presença devem reportá-las diretamente ao Departamento de Pesquisa Comportamental.

O documento introduz a existência de um setor que não aparece na planta do edifício.

## Cena 3 — O corredor vazio

Duração: 5 minutos | Local: corredor administrativo | Intensidade: 3/5



Daniel encontra a CAM-04 montada no teto.

O indicador luminoso está aceso, apesar de o terminal informar que ela está offline.

Ao examinar a câmera, descobre que seu cabo de rede está conectado.

**Objetivos:**

1. Inspecionar a CAM-04.
2. Verificar o cabeamento.
3. Localizar a sala de TI.

**Primeiro susto — A porta que responde**

Ao passar por uma porta fechada, Daniel escuta três batidas vindas do outro lado.

Se bater na porta utilizando a interação, recebe três batidas de resposta.

Na segunda tentativa, as batidas vêm de uma porta atrás dele.

Quando se vira, a porta está entreaberta.

Não existe entidade visível.

**Pista:** uma etiqueta na CAM-04 indica `RACK 2B — PORTA 07`.

Essa informação será necessária para o puzzle seguinte.

## Cena 4 — A sala de TI

Duração: 6 minutos | Local: sala de TI | Intensidade: 2/5



Daniel encontra um rack de rede parcialmente funcional, um pequeno terminal de diagnóstico e um quadro de identificação de cabos.

O equipamento registra tráfego da CAM-04, mas a transmissão não chega ao sistema de segurança.

**Puzzle 1 — Restaurar a conectividade**

O jogador deve identificar a porta correta e restabelecer o caminho da câmera até o gravador.

**Simulação do puzzle de rede**

PATCH PANEL — RACK 2B

[Testar conexão]

Protótipo interativo da lógica. No jogo, a conexão será feita por interação física com o patch panel e o terminal.

A solução é conectar a CAM-04 à porta 07, conforme a etiqueta encontrada no corredor.

**Documento — Log de Rede**

```text
VESPER NETWORK DIAGNOSTICS
CAM-04 / RACK 2B / PORT 07

01:03:17 - VIDEO STREAM RECEIVED
01:03:18 - OPERATOR DETECTED
01:03:19 - DUPLICATE SESSION
01:03:20 - SIGNAL LOST
```

O relógio do jogo ainda não chegou a 01h03.

Ao restaurar a conexão, o terminal apresenta:

`STREAM RECOVERED — PLAYBACK BUFFER AVAILABLE`

O jogador desbloqueia a primeira gravação antecipada.

## Cena 5 — A transmissão antecipada

Duração: 5 minutos | Local: sala de TI e corredor | Intensidade: 4/5



Daniel acessa o buffer da CAM-04.

A gravação mostra o corredor do segundo andar, com o horário de 01h03.

Na imagem, Daniel aparece saindo da sala de TI.

Poucos segundos depois, a porta atrás dele se fecha violentamente.

**Diálogo:**

> **Daniel:** "Isso não aconteceu..."
>
> **Daniel:** "Eu ainda estou aqui."

O jogador pode rever a gravação e observar detalhes.

Ao sair da sala, encontra o corredor exatamente como estava no vídeo.

**Segundo susto — A antecipação**

A porta da sala de TI começa a se fechar.

O jogador pode segurá-la ou afastar-se.

Independentemente da escolha, o evento confirma que a gravação mostrava um acontecimento futuro, mas o resultado muda:

- Se impedir o fechamento, o sistema registra uma inconsistência.
- Se permitir o fechamento, a cena ocorre exatamente como foi gravada.

Essa decisão será registrada para o Capítulo 4, quando o jogador descobrirá que MÍMESIS estuda suas reações.

**Flag narrativa:** `future_event_resisted`.

## Cena 6 — A reunião que não aconteceu

Duração: 5 minutos | Local: sala de reuniões | Intensidade: 3/5



A restauração da CAM-04 ativa um alerta de movimento na CAM-05, localizada na sala de reuniões.

Daniel entra no ambiente e encontra uma mesa com seis cadeiras, um projetor e uma pasta de documentos.

**Objetivos:**

1. Inspecionar a sala.
2. Localizar o relatório da reunião.
3. Verificar a CAM-05.
4. Comparar os registros.

**Puzzle 2 — Participantes ausentes**

O relatório informa que uma reunião aconteceu às 23h40, com seis participantes.

A câmera registra apenas cinco pessoas entrando na sala.

O jogador precisa identificar o participante ausente usando uma lista de funcionários e os horários de acesso.

**Registro de acesso — 23h40**

| Funcionário | Entrada registrada |
|--------|--------|
| Helena Duarte | 23h35 |
| Marcos Vidal | 23h36 |
| Clara Nunes | 23h37 |
| Rafael Costa | 23h38 |
| Elisa Prado | 23h39 |
| Henrique Almeida | Sem registro |

O jogador deve selecionar o funcionário que aparece na ata, mas não possui registro de entrada.

Helena Duarte

Marcos Vidal

Henrique Almeida

Elisa Prado

[Confirmar investigação]

Ao selecionar Henrique, Daniel encontra uma fotografia antiga do funcionário.

No verso, está escrito:

> "Se ele estiver na gravação, não significa que esteve aqui."

A CAM-05 mostra uma sexta cadeira sendo puxada lentamente para trás.

Na sala física, a cadeira permanece imóvel.

## Cena 7 — O caminho de volta

Duração: 5 minutos | Local: corredor e escadaria | Intensidade: 4/5



Daniel recebe uma mensagem no rádio:

> **Augusto:** "A câmera voltou. Pode retornar à sala de segurança."
>
> **Daniel:** "Quem é Henrique Almeida?"
>
> **Augusto:** "Onde você ouviu esse nome?"
>
> **Daniel:** "Ele aparece nos documentos."
>
> **Augusto:** "Daniel, saia do segundo andar. Agora."

A iluminação principal falha.

A porta da escadaria está trancada eletronicamente.

**Puzzle 3 — Rota alternativa**

O jogador precisa consultar o mapa de emergência e encontrar uma passagem pela administração, que leva a uma escada de serviço.

Durante o trajeto, ouve uma voz idêntica à sua vindo de uma sala fechada.

> **Voz de Daniel:** "Não abre. Eu já tentei."

**Terceiro susto — O outro lado**

Quando o jogador se aproxima da porta, uma sombra passa rapidamente pela pequena janela de vidro.

O evento não inicia perseguição. A tensão vem da dúvida sobre quem está do outro lado.

Ao alcançar a escada de serviço, o jogador encontra uma mensagem escrita na parede:

`VOCÊ SEMPRE VOLTA PELO MESMO CAMINHO.`

A mensagem desaparece caso o jogador olhe novamente após atravessar a porta.

## Cena 8 — A gravação do amanhã

Duração: 5 minutos | Local: sala de segurança | Intensidade: 4/5



Daniel retorna à sala de segurança.

O terminal indica que todas as câmeras estão online.

Uma nova gravação aparece no arquivo:

`REGISTRO DISPONÍVEL — 15/11/2008 — 00:00`

A data corresponde ao dia seguinte.

O jogador abre a gravação.

Ela mostra a recepção do edifício. Um novo funcionário entra, encontra um envelope e recolhe um crachá.

O rosto do funcionário não aparece.

A câmera registra uma voz:

> **Funcionário:** "Alô? Tem alguém aqui?"
>
> **Voz de Augusto:** "Boa noite. Seu turno começa à meia-noite."

A gravação termina antes de revelar quem é o funcionário.

Daniel tenta apagar o arquivo, mas o sistema apresenta:

`ARQUIVO PROTEGIDO — ORIGEM: MÍMESIS`

É a primeira vez que o nome do sistema aparece explicitamente.

## Cena 9 — A segunda ocorrência

Duração: 4–6 minutos | Local: sala de segurança | Intensidade: 3/5



O terminal imprime um novo relatório.

> **RELATÓRIO DE OCORRÊNCIA — 002**
>
> Operador: Daniel Reis
>
> Horário: 01h57
>
> Evento: Divergência temporal
>
> Observação: O operador identificou uma gravação anterior à ocorrência.
>
> Resposta comportamental: Inesperada.
>
> Status: Análise em andamento.

Daniel lê o relatório e percebe que ele descreve suas ações no segundo andar.

Se o jogador impediu o fechamento da porta na Cena 5, aparece uma observação adicional:

`O OPERADOR ALTEROU O EVENTO PREVISTO.`

Caso contrário:

`O OPERADOR REPRODUZIU O EVENTO PREVISTO.`

O rádio transmite a voz de Augusto:

> **Augusto:** "Daniel, você fez um bom trabalho."
>
> **Daniel:** "O que é MÍMESIS?"
>
> **Augusto:** "Não deveria ter encontrado esse nome."
>
> **Daniel:** "O que vocês estão fazendo comigo?"
>
> **Augusto:** "Nós não estamos fazendo nada."
>
> **Augusto:** "Estamos apenas observando."

O terminal exibe:

`PERFIL COMPORTAMENTAL ATUALIZADO`

`CORRESPONDÊNCIA: 68%`

`REFERÊNCIA: HENRIQUE ALMEIDA`

O relógio avança para 02h00.

As câmeras permanecem ligadas, mas a CAM-04 mostra Henrique sentado na sala de segurança, exatamente na cadeira ocupada por Daniel.

A tela escurece.

## CAPÍTULO 2 CONCLUÍDO

Registros Incompletos

Próximo capítulo: O Funcionário Ausente

---

## 5. Mecânicas introduzidas no Capítulo 2

| Mecânica | Descrição | Reutilização |
|--------|--------|--------|
| Diagnóstico de câmeras | Verificar falhas físicas e lógicas | Cap. 2–5 |
| Arquivo CCTV | Assistir gravações e comparar eventos | Cap. 2–5 |
| Eventos antecipados | Visualizar acontecimentos futuros | Cap. 2–5 |
| Decisões persistentes | Registrar escolhas do jogador | Cap. 2–5 |
| Investigação documental | Cruzar evidências e identificar inconsistências | Cap. 2–5 |
| Rotas alternativas | Desbloquear caminhos durante falhas | Cap. 2–5 |

O Capítulo 2 não introduz combate, inventário complexo ou perseguições. A exploração e a observação continuam sendo os principais sistemas.

## 6. Arquitetura técnica e eventos

### Estados narrativos

```text
CH2_START
    ↓
CH2_SECOND_FLOOR
    ↓
CH2_CAMERA_INSPECTION
    ↓
CH2_NETWORK_REPAIR
    ↓
CH2_FUTURE_RECORDING
    ↓
CH2_MEETING_INVESTIGATION
    ↓
CH2_ALTERNATE_ROUTE
    ↓
CH2_TOMORROW_RECORDING
    ↓
CH2_FINAL_REPORT
    ↓
CHAPTER_COMPLETED
```

### Eventos e gatilhos

| ID | Gatilho | Resultado |
|--------|--------|--------|
| `C2_S1_ALERT` | Início do capítulo | CAM-04 fica offline |
| `C2_S2_STAIRS` | Crachá utilizado | Escadaria desbloqueada |
| `C2_S3_CAMERA` | Inspeção física | Identificação RACK 2B |
| `C2_S3_KNOCK` | Jogador se aproxima da porta | Batidas e resposta |
| `C2_S4_REPAIR` | Conexão correta | CAM-04 restaurada |
| `C2_S5_PREVIEW` | Buffer reproduzido | Evento futuro preparado |
| `C2_S5_DOOR` | Jogador sai da sala de TI | Escolha registrada |
| `C2_S6_HENRIQUE` | Investigação concluída | CAM-05 exibe anomalia |
| `C2_S7_BLACKOUT` | Retorno iniciado | Escadaria bloqueada |
| `C2_S7_ESCAPE` | Escada de serviço alcançada | Retorno liberado |
| `C2_S8_RECORDING` | Arquivo aberto | Nome MÍMESIS revelado |
| `C2_S9_REPORT` | Relatório examinado | Capítulo encerrado |

### Novos dados persistentes

```json

{
  "chapter": 2,
  "scene": "CH2_FINAL_REPORT",
  "flags": {
    "cam04_restored": true,
    "future_recording_watched": true,
    "future_event_resisted": false,
    "henrique_identified": true,
    "alternate_route_unlocked": true,
    "mimesis_discovered": true
  },
  "evidence": [
    "network_log_2b",
    "meeting_attendance",
    "henrique_photo",
    "tomorrow_recording"
  ]
}
```

Esse exemplo representa o estado lógico que o SaveManager deverá preservar. A implementação deve ser compatível com o sistema de salvamento do Capítulo 1.
