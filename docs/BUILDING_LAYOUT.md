# Implantação do Edifício Vesper

## Volume e circulação

Térreo em y = 0; segundo piso em y = 4,2. O corpo principal tem aproximadamente 16 × 28 m. O piso superior ocupa x = −8…8 e z = −14…10, acima das salas do térreo. As caixas das escadas são anexas ao corpo principal, compartilhadas pelos dois pavimentos.

A escada principal, ao norte do corredor, sobe 2,1 m no primeiro lance, retorna 180° no patamar e sobe mais 2,1 m. Há 12 degraus visuais por lance, rampas físicas de cerca de 25°, corrimãos, guarda-corpos com colisão, sinalização e janelas em ambos os pisos. O patamar superior entra diretamente no corredor administrativo. Nenhum teletransporte é usado durante o percurso.

A escada de serviço fica a oeste da administração e usa o mesmo retorno de dois lances. A passagem térrea segue sob o lance superior e o patamar, com altura livre para a cápsula do jogador, até a porta lateral da segurança. O bloqueio narrativo da escada principal continua obrigando essa rota no capítulo 2.

Os patamares de serviço ocupam toda a largura da caixa, até x = −8 no limiar da administração. As bordas livres têm guarda-corpos com rodapé e colisão contínua, incluindo a frente do patamar superior sobre o lance inferior e a abertura central entre os lances. O caminho aberto do piso superior entra no lance leste, faz o retorno no patamar intermediário e desce pelo lance oeste. As faces inferiores dos lances têm fechamento estrutural; a passagem térrea preserva 1,85 m de altura livre física. Três luminárias montadas nas paredes iluminam os patamares e os degraus com focos direcionados e preenchimento local, acompanhando o apagão do prédio.

O encontro da escada com os corredores tem paredes laterais e vergas completas, fechando também o espaço entre o forro do térreo e a laje superior. O patamar termina na borda do piso do andar, sem superfícies coplanares sobrepostas. Seu acabamento de ladrilho fica somente em cima, sobre uma face inferior de concreto/forro. O friso entre pavimentos acompanha o perímetro da fachada e não atravessa a escadaria.

## Exterior e aberturas

A antiga parede ao fundo da marquise foi retirada. O terreno externo tem base e perímetro com colisão, estacionamento, carros, bancos, canteiros, árvores, postes, sinalização e fundos urbanos. Marquise e pilares definem o acesso. A fachada possui frisos entre pavimentos, peitoris, drenagem, tubulações, platibanda e unidades no telhado. Grades repetidas usam MultiMesh.

As paredes com janelas são segmentadas em vergas, bases e montantes: não existe parede opaca atrás do vidro. Caixilhos, divisões, peitoris e marcas de umidade completam cada vão. Os vidros são transparentes, têm colisão e não projetam uma sombra opaca sobre o interior. A chuva com partículas de CPU fica em áreas externas ao volume coberto e funciona no renderizador Compatibility. Materiais de asfalto e poças são locais; não há SSR ou reflexos de alta fidelidade prometidos.

## Coordenadas e checkpoints

`building_layout.gd` transforma as coordenadas narrativas anteriores para a nova planta. A geometria recebe tamanhos positivos, sem espelhamento de raízes físicas. Itens, mesas, cadeiras, gatilhos e atores dos arquivos acompanham a transformação. `security_camera_layout.gd` continua sendo a referência única para lentes físicas, CCTV ao vivo e arquivos.

Saves novos incluem `map_revision: 2`. Saves sem esse campo mantêm flags, documentos e inventário e transformam a posição antiga do piso superior. A orientação horizontal também acompanha a inversão do eixo do corredor. Saves nas antigas escadas são levados ao patamar correspondente ou à passagem de serviço; não são deixados suspensos na implantação anterior.

## Verificação

O modo `check` verifica a sintaxe dos scripts no Godot 4.0. O modo `test` percorre os dois capítulos, incluindo subida e descida dos dois lances principais, reparo de energia, rede, gravações isoladas, bloqueio da escada, retorno pela escada de serviço e finais. A suíte de arquitetura verifica a projeção dos objetos no novo piso, suporte da laje, fechamento lateral/superior das portas da escada, ausência de pisos sobrepostos na transição, face inferior do patamar, colisão de vidro, acesso externo e migração de checkpoints.

Os trechos de circulação usam o controlador real. Os testes reposicionam o jogador entre objetivos; não equivalem a uma partida manual contínua. Capturas são desenhadas explicitamente pelo renderizador; o modo de teste desliga o desenho automático para evitar que janelas minimizadas interrompam a suíte. O modo normal de jogo mantém renderização contínua.

A escada de serviço também é percorrida nos dois sentidos, verificando os níveis dos patamares e a ausência de quedas livres entre quadros. Há testes físicos tentando caminhar contra as bordas protegidas, raios de suporte no antigo vão de 35 cm junto à porta, verificação da orientação das duas rampas e altura livre da passagem inferior.

Ainda cabe avaliação com jogadores de orientação, conforto dos lances, legibilidade noturna, desempenho em outras placas e ritmo. As áreas urbanas além do perímetro são cenográficas; somente dois pisos do Vesper fazem parte da partida.


## Revisão de superfícies e iluminação — 28/10/2026

- Peças antigas do tipo `wall`, vergas e rodapés do segundo andar passam pelo material arquitetônico. A seleção de faces externas inclui as torres das escadas; as faces internas preservam sua pintura. A fachada usa pintura de reboco com fissuras finas, envelhecimento mineral e umidade localizada, com menor presença de alvenaria exposta e sem a camada escura uniforme anterior.
- A poeira interna é mais translúcida e restrita aos cantos; não cobre mais o asfalto externo. O ruído espacial usa hash sem seno para evitar artefatos nas manchas. O estacionamento preserva a textura fotográfica de asfalto e detritos.
- As três poças deixam de ser cilindros opacos. Áreas irregulares de umidade são misturadas à cor, normal e rugosidade do próprio piso, sem degrau, disco preto ou colisão extra. Não se trata de uma simulação de água com profundidade ou reflexos completos do cenário.
- Vidros recebem depósitos nas bordas, escorridos e opacidade discreta; a visão para os cômodos permanece aberta. Caixilhos e portas usam pintura fosca, pequenos pontos de perda de tinta e oxidação pouco contrastada. Vãos, colisões e animações das portas não mudaram.
- O teto tem reboco pintado e manchas de infiltração discretas. As carcaças decorativas das luminárias deixam de bloquear seu próprio ponto de luz. A sinalização de direção da recepção e das escadas passa às paredes, sem sombras projetadas; não há placas suspensas abaixo dessas fontes.
- Todos os recursos visuais utilizados já estavam incluídos no projeto. Prévia técnica em `.local/material-*.png` usa os materiais reais, com HUD e grão de filme ocultados somente no script de captura para facilitar a inspeção. Os efeitos de imagem do jogo permanecem inalterados.


## Massa e hierarquia da fachada

`facade_details.gd` cria o envelope decorativo: pilares de 46 cm na frente, pilastras laterais, bases mais largas, cornijas em dois níveis, pingadeiras metálicas, marquise com 34 cm de espessura, portal da entrada e painel central do letreiro. A base da torre de serviço usa a fotografia de alvenaria já incluída; o concreto usa o conjunto `concrete_floor_worn_001` com relevo reduzido e cor própria.

A pintura externa distingue o térreo em tom mineral quente e o andar superior em verde acinzentado desbotado. As molduras de concreto são construídas ao redor das aberturas existentes. Não há aumento de pavimentos nem alteração da planta interna. Pilares e apoios novos têm colisão, mantendo livres a porta principal, a passagem de serviço e os percursos das escadas; frisos, molduras e revestimentos são detalhes visuais. Não foram adicionadas luzes, bibliotecas ou downloads ao jogo.

Capturas técnicas em `.local/facade-front.png`, `.local/facade-corner.png`, `.local/facade-entry.png` e `.local/facade-side.png`, com grão/HUD ocultados apenas para inspecionar os materiais.


## Correção dos encontros estruturais

O fechamento entre os pavimentos agora ocupa a faixa de 3,0 a 4,2 m nas faces expostas do térreo. Uma laje completa o trecho de 2,2 m entre a fachada recuada do segundo andar e os pilares do pórtico; a faixa antes aberta sob a cornija não permite enxergar o interior. As quinas dianteiras usam um único pilar de seção quadrada, substituindo os dois pilares desencontrados. Vigas laterais e frontais compartilham altura e perfil.

Os pilares estreitos, frisos e a laje antiga da marquise que ficaram sob a versão nova foram removidos. Os apoios da marquise alcançam a face inferior da laje. Base, faixa entre pisos e coroamento da escada de serviço retornam pelas paredes cegas, que também receberam uma grelha de ventilação. Os tubos de descida foram transferidos para trás, com suportes e afastamento das cornijas. O letreiro tem travessas de fixação aos pilares.

A suíte de arquitetura verifica por raios físicos o fechamento da faixa entre pisos, a quina sem fresta diagonal e o encontro do apoio com a marquise. Capturas de inspeção: `.local/facade-joint-right.png`, `.local/facade-joint-left.png` e `.local/facade-tower.png`.
