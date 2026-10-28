# Malhas da mão em primeira pessoa

Recursos nativos do Godot usados por `res://scenes/mao_lanterna.tscn`.

- `right_hand_mesh.res`: derivado de `../wrad_arms/right_arm.glb`, WRAD Arms (CC0), com o material local usado pelo projeto. Contém somente os 390 vértices referenciados pelos triângulos do braço direito; os vértices sem uso foram removidos. A cena usa apenas 23 ossos da cadeia direita, sem o esqueleto esquerdo nem controladores auxiliares do arquivo original.
- `Lanterna_*.res`: partes de `../flashlight/led_flashlight.glb`, Innerscene (CC0), com as texturas locais. Créditos e licenças originais permanecem nessas pastas.
- `UniformSleeve.res`: manga criada no projeto.

As malhas ficam separadas do arquivo de cena para manter posições, ossos e animações legíveis e editáveis. A cena salva a pose de pegada; o script apenas aplica a animação salva, posiciona o feixe na lente e controla o balanço durante a caminhada.
