# NIGHTSHIFT — Capítulo 1: O Primeiro Turno

Roteiro de produção v1.0 | Godot 4 | Terror psicológico 3D em primeira pessoa



Este capítulo será o primeiro contato do jogador com o Edifício Vesper. O objetivo é criar uma experiência de aproximadamente **30–35 minutos**, com exploração, investigação, monitoramento de câmeras, puzzles e momentos de terror cuidadosamente distribuídos.

O jogador deve começar acreditando que está apenas trabalhando em um prédio abandonado. Ao final, precisa ter certeza de que algo impossível está acontecendo — mas sem compreender sua origem.

Duração-alvo

# 30–35 min

Cenas principais

# 8

Puzzles

# 3

Sustos principais

# 3

---

**Princípio de direção:** o terror deve surgir principalmente da percepção do jogador. Evitar sustos sonoros constantes, perseguições ou inimigos agressivos neste capítulo.

## 1. Planta jogável e progressão

Para a primeira versão, o capítulo utiliza apenas o térreo e um pequeno trecho do segundo andar. Os demais andares ficam inacessíveis.

[Planta conceitual: recepção, segurança, corredor, arquivo e sala técnica.]

Planta conceitual do térreo. As dimensões e posições finais serão definidas no blockout 3D.

O segundo andar será apenas parcialmente visível por meio das câmeras e de uma porta de escada bloqueada. Isso cria expectativa para o Capítulo 2 sem exigir sua implementação agora.

## 2. Linha do tempo do capítulo

Os tempos são referências para ritmo. Nenhuma cena deve depender de uma contagem regressiva obrigatória. A progressão acontece por objetivos e gatilhos.

---

## 3. Roteiro completo — Cena por cena

### Cena 1 — Chegada ao Vesper

Duração: 4 minutos | Local: recepção | Intensidade: 1/5



**Abertura**

Tela preta. Sons de chuva, motor desligando e uma porta de carro sendo fechada.

Um texto aparece:

> 14 de novembro de 2008 — 23h57
>
> Edifício Vesper, Setor Administrativo.

A imagem surge com Daniel diante da entrada. O jogador assume o controle imediatamente.

**Objetivos:**

1. Entrar no edifício.
2. Encontrar o envelope na recepção.
3. Ler as instruções.
4. Coletar o crachá e a chave.

**Elementos interativos:** porta de entrada, envelope, folha de instruções, relógio da recepção e telefone desligado.

**Documento encontrado — Protocolo de Vigilância:**

> Bem-vindo ao Edifício Vesper.
>
> Seu turno começa à meia-noite e termina às seis horas.
>
> Todas as ocorrências devem ser registradas no terminal de segurança.
>
> Não atenda ligações do ramal 000.
>
> Não permaneça em áreas sem iluminação.
>
> Caso encontre alguém no prédio, retorne imediatamente à sala de segurança.
>
> Caso uma câmera mostre sua própria imagem em outro local, desligue o monitor.
>
> Não tente acessar o subsolo.

**Primeiro evento de estranhamento:**

Quando o jogador recolhe o envelope, o relógio de parede avança de 23h59 para 00h00 e permanece parado por alguns segundos.

O telefone emite um único toque, mas não há possibilidade de atendê-lo.

**Implementação:**

| ID | Gatilho | Resultado |
|--------|--------|--------|
| `C1_S1_ENTER` | Jogador cruza a entrada | Inicia ambience interno |
| `C1_S1_ENVELOPE` | Interação com envelope | Abre UI do documento |
| `C1_S1_BADGE` | Crachá coletado | Desbloqueia segurança |
| `C1_S1_CLOCK` | Envelope recolhido | Relógio para e telefone toca |
| `C1_S1_EXIT` | Jogador entra na segurança | Conclui cena |

O telefone não deve tocar novamente nessa cena. O objetivo é estabelecer desconforto, não assustar.

### Cena 2 — A sala de segurança

Duração: 4 minutos | Local: sala de segurança | Intensidade: 1/5



Ao entrar, Daniel encontra três monitores de vigilância, um terminal de ocorrências e um gravador de áudio.

O jogador precisa ligar o terminal e reproduzir a mensagem do supervisor.

**Áudio do supervisor — gravação 001**

> "Boa noite, Daniel. Aqui é Augusto, supervisor de segurança do Vesper."
>
> "Imagino que já tenha encontrado as instruções. O procedimento é simples: observe as câmeras, registre alterações e faça rondas quando o terminal solicitar."
>
> "A maioria dos alarmes é causada por sensores antigos. Não há motivo para preocupação."
>
> "Uma última coisa: o sistema de gravação apresenta atrasos ocasionais. Se encontrar algo estranho, verifique duas vezes antes de reportar."
>
> "Bom turno."

**Tutorial CCTV**

O jogador aprende a alternar entre três câmeras:

| Câmera | Local | Estado inicial |
|--------|--------|--------|
| CAM-01 | Recepção | Normal |
| CAM-02 | Corredor principal | Normal |
| CAM-03 | Arquivo | Normal |

A interface permite selecionar a câmera, ampliar a imagem e abrir o painel de ocorrências.

**Puzzle 1 — Verificação de inicialização**

O sistema solicita a identificação de três elementos:

- Relógio visível na recepção.
- Porta fechada no corredor.
- Cadeira posicionada diante da mesa do arquivo.

O jogador deve verificar os três elementos e confirmar a inspeção.

Não existe penalidade por erro neste tutorial.

**Gatilho final:** após confirmar a inspeção, o terminal mostra:

`INSPEÇÃO CONCLUÍDA — RONDA PRESENCIAL OBRIGATÓRIA.`

### Cena 3 — Primeira ronda

Duração: 4 minutos | Local: corredor e arquivo | Intensidade: 2/5



Daniel deve verificar o corredor e encontrar um livro de registros no arquivo.

O corredor possui iluminação parcialmente defeituosa, mas não há ameaça real.

**Objetivos:**

1. Inspecionar a porta de emergência.
2. Entrar no arquivo.
3. Encontrar o livro de registros.
4. Retornar à sala de segurança.

**Documento opcional — Registro de Manutenção**

> 12/11/2008 — Substituição das câmeras concluída.
>
> O equipamento CAM-03 apresentou falhas de sincronização.
>
> A equipe técnica informou que a câmera estava exibindo imagens com horários incompatíveis.
>
> Solicitação de substituição negada pela administração.

**Evento ambiental:**

Quando o jogador está voltando, a luz do corredor pisca três vezes. No último apagão, ouve-se um ruído semelhante a passos atrás dele.

Ao virar, não há ninguém.

Esse evento deve ocorrer apenas uma vez, com volume moderado e sem uma figura surgindo na tela.

**Gatilho final:** retorno à sala de segurança e interação com o terminal.

### Cena 4 — A cadeira deslocada

Duração: 5 minutos | Local: segurança e arquivo | Intensidade: 2/5



Esta cena apresenta a primeira anomalia real.

A câmera CAM-03 mostra que a cadeira do arquivo foi deslocada da mesa para perto da porta.

O jogador precisa perceber a alteração e registrá-la.

**Puzzle 2 — Reportar a anomalia**

A interface de ocorrências permite escolher:

- Câmera: CAM-03.
- Categoria: Objeto deslocado.
- Confirmar ocorrência.

Após o reporte correto, o sistema apresenta:

`OCORRÊNCIA 001 REGISTRADA — VERIFICAÇÃO PRESENCIAL RECOMENDADA.`

O jogador retorna ao arquivo.

A cadeira está exatamente onde a câmera mostrou. Ao aproximar-se, percebe marcas no piso, como se alguém a tivesse arrastado.

**Susto principal 1 — O movimento**

Quando o jogador examina as marcas, a cadeira se move lentamente alguns centímetros, fora do centro da visão.

Um ruído de madeira arrastando acompanha o movimento.

Se o jogador estiver olhando diretamente para ela, a cadeira permanece parada até que ele desvie o olhar. Há um limite de espera e um gatilho alternativo para evitar travamento.

Ao voltar para a segurança, a CAM-03 mostra a cadeira novamente em sua posição original.

### Cena 5 — A porta aberta

Duração: 5 minutos | Local: corredor e sala técnica | Intensidade: 3/5



A CAM-02 registra a porta da sala técnica aberta, embora Daniel a tenha encontrado fechada durante a ronda.

O terminal solicita uma verificação presencial.

**Objetivos:**

1. Inspecionar a porta.
2. Entrar na sala técnica.
3. Identificar uma falha no circuito.
4. Restaurar a iluminação do corredor.

**Puzzle 3 — Quadro elétrico**

O quadro possui quatro disjuntores identificados por etiquetas:

| Disjuntor | Circuito | Estado correto |
|--------|--------|--------|
| A | Recepção | Ligado |
| B | Corredor | Ligado |
| C | Arquivo | Ligado |
| D | Subsolo | Desligado |

O jogador encontra um diagrama indicando quais circuitos devem permanecer ativos.

Se ligar o circuito D, a iluminação apaga por alguns segundos e o terminal emite um aviso. O disjuntor retorna ao estado desligado, sem impedir o progresso.

**Susto principal 2 — A batida**

Após restaurar o circuito B, três batidas violentas ocorrem na porta da sala técnica.

Quando Daniel abre a porta, o corredor está vazio.

O rádio transmite uma voz distorcida:

> "Não devia ter ligado a luz."

A partir desse momento, a câmera CAM-02 apresenta interferências ocasionais.

### Cena 6 — A figura no corredor

Duração: 4 minutos | Local: sala de segurança | Intensidade: 4/5



Daniel retorna ao terminal.

A CAM-02 mostra uma figura humana imóvel no final do corredor. Seu rosto não é visível.

O terminal solicita que o jogador verifique a ocorrência.

O jogador pode observar a figura, ampliar a câmera e registrar a categoria `Presença não autorizada`.

**Evento de terror:**

A figura começa a se aproximar da câmera somente quando o jogador alterna para outro monitor.

Ao retornar à CAM-02, ela aparece mais perto.

Depois da terceira alternância, a figura está diante da lente.

A transmissão apresenta interferência intensa e fica preta.

**Mensagem no terminal:**

`MOVIMENTO DETECTADO — SALA DE SEGURANÇA`

O jogador ouve passos do lado de fora.

A maçaneta se move lentamente, mas a porta permanece fechada.

Após alguns segundos, os passos se afastam.

O evento termina sem perseguição ou morte. O jogador deve sentir que escapou de uma ameaça que ainda não compreende.

### Cena 7 — O segundo Daniel

Duração: 4 minutos | Local: sala de segurança | Intensidade: 5/5



A transmissão da CAM-01 retorna espontaneamente.

Ela mostra Daniel caminhando pela recepção.

O jogador está dentro da sala de segurança, portanto a imagem é impossível.

A figura na câmera se aproxima do balcão, recolhe um envelope e olha diretamente para a lente.

O terminal começa a exibir uma mensagem:

`OPERADOR IDENTIFICADO — DANIEL REIS`

`LOCALIZAÇÃO: RECEPÇÃO`

`LOCALIZAÇÃO: SALA DE SEGURANÇA`

`ERRO DE SINCRONIZAÇÃO`

**Susto principal 3 — O reflexo**

O monitor da CAM-01 apaga por um instante.

Na superfície escura, o jogador vê o reflexo de uma pessoa parada atrás de Daniel.

Ao virar a câmera, não há ninguém.

O monitor volta a funcionar, agora mostrando a sala de segurança vazia, como se Daniel não estivesse nela.

**Objetivo:** desligar o monitor conforme o protocolo encontrado na recepção.

Se o jogador demorar, a imagem apresenta interferências progressivas e a voz do supervisor repete:

> "Daniel... desligue a câmera."

O evento não mata o jogador e não depende de reflexos rápidos.

### Cena 8 — Relatório impossível

Duração: 3–5 minutos | Local: segurança e recepção | Intensidade: 3/5



Após desligar o monitor, o terminal imprime um relatório de ocorrência.

O documento contém:

> **RELATÓRIO DE INCIDENTE — VESPER**
>
> Operador: Daniel Reis
>
> Data: 11/11/2008
>
> Horário: 03h17
>
> Ocorrência: Duplicação de operador
>
> Status: Não resolvido
>
> Observação: O operador insiste que esta é sua primeira noite.

Daniel encontra uma assinatura idêntica à sua no final do documento.

Nesse momento, o telefone da recepção começa a tocar.

O jogador pode ignorar a ligação ou ir até o aparelho. Ao aproximar-se, o visor exibe `RAMAL 000`.

O telefone para de tocar antes que possa ser atendido.

A voz do supervisor é reproduzida pelo sistema de som:

> "Primeira hora concluída, Daniel."
>
> "O sistema registrou algumas inconsistências, mas não se preocupe."
>
> "Isso aconteceu da última vez também."

O relógio da sala de segurança avança para 01h00.

A tela escurece lentamente.

## CAPÍTULO 1 CONCLUÍDO

O Primeiro Turno

Próximo capítulo: Registros Incompletos

---
