# Vesper — gravações e tratamento de áudio

Todos os novos arquivos desta pasta derivam de fontes **CC0 1.0** (domínio público), autorizadas para edição, redistribuição e uso comercial. Licença: https://creativecommons.org/publicdomain/zero/1.0/ . Consulta: 28/10/2026. Os arquivos `infrasound.wav` e `Sublevel Void.wav` anteriores, fora desta pasta, não foram substituídos.

| Autor / fonte primária | Originais utilizados | Arquivos no jogo |
| --- | --- | --- |
| rubberduck — [40 CC0 water / splash / slime SFX](https://opengameart.org/content/40-cc0-water-splash-slime-sfx) | `loop_rain.ogg` | `rain.wav`, `rain_inside.wav` |
| rubberduck — [100 CC0 SFX](https://opengameart.org/content/100-cc0-sfx) | `door_open.ogg`, `door_close_02.ogg`, `door_close_04.ogg`, `switch_01.ogg` | `door_open.wav`, `door_close.wav`, `car_door.wav`, `switch.wav` |
| rubberduck — [100 CC0 metal and wood SFX](https://opengameart.org/content/100-cc0-metal-and-wood-sfx) | `wood_hit_02.ogg`, `wood_squeak_01.ogg`, `wood_squeak_02.ogg` | `knock.wav`, `drag.wav` |
| GboxMikeFozzy — [Footsteps](https://opengameart.org/content/footsteps-0) | `01-footstep_0.ogg`, `02-footstep.ogg` até `06-footstep.ogg` | seis `step_hard_*.wav` (registro de passos em passagem subterrânea) |
| mikeask — [Steps in wood floor](https://opengameart.org/content/steps-in-wood-floor) | `steps in wood floor.wav` | quatro `step_wood_*.wav`, recortados em passos individuais |
| Joseph SARDIN / BigSoundBank — [Fixed Telephone Ring #4](https://bigsoundbank.com/fixed-telephone-ring-4-s0253.html) | `0253.ogg` | `ring.wav`, um toque recortado |
| Joseph SARDIN / BigSoundBank — [Car (reverse and stop)](https://bigsoundbank.com/car-reverse-and-stop--s0188.html) | `0188.ogg` | `engine.wav`, trecho final do motor |
| Joseph SARDIN / LaSonothèque — [Ordinateur, Ventilation #1](https://lasonotheque.org/ordinateur-1-ventillation-s0125.html) | `0125.ogg` | `hum.wav`, ventilação filtrada em loop |
| Joseph SARDIN / LaSonothèque — [Calculatrice-imprimante #3](https://lasonotheque.org/calculatrice-imprimante-3-s3555.html) | `3555.ogg` | `printer.wav`, mecanismo de impressão de escritório antigo |

## Adaptação ao Vesper

- Conversão para PCM mono de 16 bits / 22.050 Hz, remoção de componente DC, filtragem suave de graves/agudos, cortes e fades; picos máximos de -3,1 dBFS nos eventos e -6 dBFS nos ambientes. Os volumes finais são menores, definidos em `soundscape.gd` e nos eventos narrativos.
- Chuva interna tem agudos amortecidos. Os dois loops de chuva permanecem sincronizados e recebem transição de volume ao cruzar a entrada. Os loops recebem sobreposição de 250 ms para suavizar a emenda.
- Passos usam seis tomadas de piso rígido e quatro de madeira, sem repetição imediata, com pequena variação de afinação. Madeira somente na administração e na sala de reuniões; escadas e demais pisos usam a família rígida. As tomadas rígidas já contêm reverberação do local da gravação.
- Portas usam gravação de mecanismo de porta; o fechamento do carro na abertura é uma adaptação filtrada de porta, não uma gravação específica de automóvel. O arrasto da cadeira é uma composição de três fricções/rangidos de madeira ao longo dos 1,5 s do movimento, não uma gravação específica da cadeira do modelo.
- Batidas, toque e impressora são posicionais nos objetos existentes. A reverberação dos efeitos cresce discretamente dentro do prédio; distância reduz volume e agudos. Não há simulação acústica de paredes/portas nem oclusão sonora completa.
- O ruído de ventilação some suavemente quando a rede do prédio cai. Chuva, lanterna e o leito de infrassom já existente permanecem independentes da energia. O rádio mantém interferência procedural intencional; não há novas vozes/dublagem.

## Reprodução do tratamento

`manifest.json` registra SHA-256 dos arquivos processados e dos originais, duração e pico. `tools/prepare_audio.py` reproduz o tratamento a partir das fontes em `.local/audio-sources/`, usando Python/numpy e ffmpeg apenas na preparação. O jogo utiliza os WAV incluídos e não requer essas ferramentas nem internet. Os pacotes completos baixados ficam fora do Git.

A edição foi verificada por medidas de sinal e testes de importação/execução. A mixagem perceptiva final em fones e caixas ainda deve ser avaliada em playtest.
