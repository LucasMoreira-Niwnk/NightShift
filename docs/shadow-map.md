# Mapa de sombras

Gerado por `tools/godot.ps1 -Mode shadows`, depois de mexer no ambiente.
Confira o diff: uma malha que a história move e que apareça como fixa
perderia a sombra ao ser assada; uma fixa listada como dinâmica paga
sombra em tempo real à toa.

| | malhas |
|---|---|
| sombra fixa (assável) | 3737 |
| sombra dinâmica | 685 |

## Fixas, por quem construiu

| dono | malhas |
|---|---|
| aged_sign.gd | 130 |
| authored_fixture.gd | 21 |
| building_exterior.gd | 1291 |
| chapter_world.gd | 1124 |
| facade_details.gd | 111 |
| folded_stairs.gd | 530 |
| lighting_fixture.gd | 98 |
| prop_slot.gd | 57 |
| second_floor.gd | 177 |
| wall_clock.gd | 198 |

## Dinâmicas, por motivo

| dono — motivo | malhas |
|---|---|
| interactable.gd — objeto interativo da história | 4 |
| memesis_malha.gd — Mêmesis de malha (anda) | 1 |
| memesis_olhos.gd — vulto de névoa | 2 |
| memesis_olhos.gd — vulto volumétrico | 2 |
| objeto: access_log — objeto interativo da história | 6 |
| objeto: admin_notice — objeto interativo da história | 6 |
| objeto: breakers — objeto interativo da história | 11 |
| objeto: cam04 — objeto interativo da história | 5 |
| objeto: cam05 — objeto interativo da história | 5 |
| objeto: chair — objeto interativo da história | 1 |
| objeto: diagram — objeto interativo da história | 5 |
| objeto: emergency — objeto interativo da história | 3 |
| objeto: emergency_map — objeto interativo da história | 2 |
| objeto: envelope — objeto interativo da história | 7 |
| objeto: flashlight — objeto interativo da história | 8 |
| objeto: fuse10 — objeto interativo da história | 3 |
| objeto: fuse20 — objeto interativo da história | 3 |
| objeto: fuse_slot — objeto interativo da história | 4 |
| objeto: handover — objeto interativo da história | 6 |
| objeto: henrique_photo — objeto interativo da história | 6 |
| objeto: it_cabinet — objeto interativo da história | 8 |
| objeto: it_cabinet_note — objeto interativo da história | 1 |
| objeto: it_key — objeto interativo da história | 4 |
| objeto: it_terminal — objeto interativo da história | 2 |
| objeto: knock_door — objeto interativo da história | 1 |
| objeto: logbook — objeto interativo da história | 2 |
| objeto: maintenance — objeto interativo da história | 2 |
| objeto: meeting_minutes — objeto interativo da história | 6 |
| objeto: meeting_terminal — objeto interativo da história | 1 |
| objeto: network_log — objeto interativo da história | 6 |
| objeto: network_patch — objeto interativo da história | 9 |
| objeto: personnel_key — objeto interativo da história | 4 |
| objeto: phone — objeto interativo da história | 20 |
| objeto: recorder — objeto interativo da história | 14 |
| objeto: repair_note — objeto interativo da história | 7 |
| objeto: report — objeto interativo da história | 6 |
| objeto: staff_register — objeto interativo da história | 6 |
| objeto: voice_door — objeto interativo da história | 3 |
| porta: administration — porta (gira ao abrir) | 34 |
| porta: archive — porta (gira ao abrir) | 34 |
| porta: break_room — porta (gira ao abrir) | 45 |
| porta: entrance — porta (gira ao abrir) | 18 |
| porta: it — porta (gira ao abrir) | 34 |
| porta: meeting — porta (gira ao abrir) | 34 |
| porta: personnel — porta (gira ao abrir) | 45 |
| porta: security — porta (gira ao abrir) | 34 |
| porta: service_exit — porta (gira ao abrir) | 34 |
| porta: service_upper — porta (gira ao abrir) | 34 |
| porta: stairs — porta (gira ao abrir) | 34 |
| porta: stores — porta (gira ao abrir) | 45 |
| porta: technical — porta (gira ao abrir) | 34 |
| porta: upper_gate — porta (gira ao abrir) | 34 |
