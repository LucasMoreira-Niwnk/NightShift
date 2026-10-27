# Implantação do Edifício Vesper

## Volume e circulação

Térreo em y = 0; segundo piso em y = 4,2. O corpo principal tem aproximadamente 16 × 28 m. O piso superior ocupa x = −8…8 e z = −14…10, acima das salas do térreo. As caixas das escadas são anexas ao corpo principal, compartilhadas pelos dois pavimentos.

A escada principal, ao norte do corredor, sobe 2,1 m no primeiro lance, retorna 180° no patamar e sobe mais 2,1 m. Há 12 degraus visuais por lance, rampas físicas de cerca de 25°, corrimãos, guarda-corpos com colisão, sinalização e janelas em ambos os pisos. O patamar superior entra diretamente no corredor administrativo. Nenhum teletransporte é usado durante o percurso.

A escada de serviço fica a oeste da administração e usa o mesmo retorno de dois lances. A passagem térrea segue sob o lance superior e o patamar, com altura livre para a cápsula do jogador, até a porta lateral da segurança. O bloqueio narrativo da escada principal continua obrigando essa rota no capítulo 2.

## Exterior e aberturas

A antiga parede ao fundo da marquise foi retirada. O terreno externo tem base e perímetro com colisão, estacionamento, carros, bancos, canteiros, árvores, postes, sinalização e fundos urbanos. Marquise e pilares definem o acesso. A fachada possui frisos entre pavimentos, peitoris, drenagem, tubulações, platibanda e unidades no telhado. Grades repetidas usam MultiMesh.

As paredes com janelas são segmentadas em vergas, bases e montantes: não existe parede opaca atrás do vidro. Caixilhos, divisões, peitoris e marcas de umidade completam cada vão. Os vidros são transparentes, têm colisão e não projetam uma sombra opaca sobre o interior. A chuva com partículas de CPU fica em áreas externas ao volume coberto e funciona no renderizador Compatibility. Materiais de asfalto e poças são locais; não há SSR ou reflexos de alta fidelidade prometidos.

## Coordenadas e checkpoints

`building_layout.gd` transforma as coordenadas narrativas anteriores para a nova planta. A geometria recebe tamanhos positivos, sem espelhamento de raízes físicas. Itens, mesas, cadeiras, gatilhos e atores dos arquivos acompanham a transformação. `security_camera_layout.gd` continua sendo a referência única para lentes físicas, CCTV ao vivo e arquivos.

Saves novos incluem `map_revision: 2`. Saves sem esse campo mantêm flags, documentos e inventário e transformam a posição antiga do piso superior. A orientação horizontal também acompanha a inversão do eixo do corredor. Saves nas antigas escadas são levados ao patamar correspondente ou à passagem de serviço; não são deixados suspensos na implantação anterior.

## Verificação

O modo `check` verifica a sintaxe dos scripts no Godot 4.0. O modo `test` percorre os dois capítulos, incluindo subida e descida dos dois lances principais, reparo de energia, rede, gravações isoladas, bloqueio da escada, retorno pela escada de serviço e finais. A suíte de arquitetura verifica a projeção dos objetos no novo piso, suporte da laje, colisão de vidro, acesso externo e migração de checkpoints.

Os trechos de circulação usam o controlador real. Os testes reposicionam o jogador entre objetivos; não equivalem a uma partida manual contínua. Capturas são desenhadas explicitamente pelo renderizador; o modo de teste desliga o desenho automático para evitar que janelas minimizadas interrompam a suíte. O modo normal de jogo mantém renderização contínua.

Ainda cabe avaliação com jogadores de orientação, conforto dos lances, legibilidade noturna, desempenho em outras placas e ritmo. As áreas urbanas além do perímetro são cenográficas; somente dois pisos do Vesper fazem parte da partida.
