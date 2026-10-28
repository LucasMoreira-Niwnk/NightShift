# Art assets — NIGHTSHIFT

## ambientCG — CC0

Author: Lennart Demes / ambientCG. Downloaded from the official asset pages. Only 1K JPG color, OpenGL normal and roughness maps are included; source archives remain in `.local/art-downloads/`.

- Tiles074 — https://ambientcg.com/view?id=Tiles074 — floor tiles, approximately 2.1 × 2.1 metres per repeat.
- PaintedPlaster017 — https://ambientcg.com/view?id=PaintedPlaster017 — photographed plaster, tinted for upper walls, lower paint and ceilings.
- Wood051 — https://ambientcg.com/view?id=Wood051 — desk and door wood.

License: Creative Commons Zero / public domain, commercial use allowed. https://docs.ambientcg.com/license/

## Kenney Furniture Kit 2.0 — CC0

Author: Kenney, https://kenney.nl/assets/furniture-kit

Imported GLB models: chair, office chair, desk, bookcases, books, radio, keyboard, mouse, ceiling light, plant, trash bin, coat rack and cardboard boxes. Materials are adapted at runtime to the Vesper palette. The original license is preserved at `models/kenney/License.txt`.

## Original project geometry

Paneled doors, frames, handles, hinges, individual narrative books, loose documents, switchboard details and telephone details are authored in `scripts/art.gd`, `door.gd` and `chapter_world.gd`. They supplement the imported models. Model visual detail does not replace the existing interaction and collision bodies.

## Poly Haven — CC0, textured glTF models

Downloaded through the official public API, using 1K textures and original geometry. Each downloaded file was checked against the MD5 supplied by the API. Source material maps are preserved at runtime, rather than replaced with the stylized Kenney palette.

- School Chair 01 — https://polyhaven.com/a/SchoolChair_01 — chair used by the archive anomaly.
- Metal Office Desk — https://polyhaven.com/a/metal_office_desk — reception, security and archive desks.
- Signal Flashlight — https://polyhaven.com/a/signal_flashlight — collectible and first-person flashlight.
- Vintage Radio Transceiver — https://polyhaven.com/a/vintage_radio_transceiver — recorder prop; only the radio body and dial are shown, excluding loose accessories.
- Desk Lamp Arm 01 — https://polyhaven.com/a/desk_lamp_arm_01 — security desk task lamp.
- Drawer Cabinet — https://polyhaven.com/a/drawer_cabinet — security storage.
- Binder Notebook — https://polyhaven.com/a/binder_notebook — closed notebook variant used by narrative books.

License: https://polyhaven.com/license — Creative Commons Zero, commercial use and redistribution allowed. Runtime fitting adjusts scale and orientation to the established level and interaction bodies. `tools/download_polyhaven_models.ps1` reproduces the downloads.

The rounded monitor housing, phone, humanoid silhouettes and HUD are original project geometry/code. The former primitive hand and Signal Flashlight viewmodel have been replaced as described below; the original Poly Haven download remains available in the asset folder.

## WRAD Arms — CC0

Author: wriks / wwwriks. https://github.com/wwwriks/wrad-arms

Imported rigged, textured FPS hand and forearm. The project derives a right-arm-only GLB, preserves the original source and license, and applies a flashlight grip pose. See `models/wrad_arms/README.md` and `LICENSE`.

## Innerscene LED flashlight — CC0

Source: https://www.innerscene.com/tools/library/3d-parts/led-flashlight-torch-aluminium-tail-switch-b30191c2

Original unbranded cylindrical flashlight, with embedded materials. Used for both the collectible and first-person item. License and source details: `models/flashlight/README.md`.

## Additional Vesper set dressing

`set_dressing.gd` builds the archive shelves and individual bound books, curved foliage and planters, vehicle bodywork/wheels, CRT housings/cabling, and exterior decay directly as project geometry. `aged_architecture.gdshader` adds room-specific joints, color variation and wear using the bundled ambientCG texture sources credited above. No additional third-party model pack or runtime dependency is required for these additions.

## Poly Haven photographic decay textures — CC0

Six additional texture sets supply actual cracked plaster, damaged plaster/exposed masonry, mossy facade, worn concrete, weathered asphalt and muddy leaf litter: `concrete_floor_worn_001`, `worn_cracked_plaster`, `damaged_plaster`, `worn_mossy_plasterwall`, `worn_asphalt`, `brown_mud_leaves_01`.

Diffuse maps are 2K; OpenGL normal, roughness and AO maps are 1K. Contributors, source pages, source download URLs and checksums are recorded in `textures/decay/README.md` and `textures/decay/manifest.json`. License: https://polyhaven.com/license (CC0-1.0). Files are bundled locally; gameplay does not access the network.


## Áudio — Vesper

Gravações CC0 de rubberduck, GboxMikeFozzy, mikeask e Joseph SARDIN (BigSoundBank / LaSonothèque), editadas para o jogo. Fontes por arquivo, modificações e licença em [audio/vesper/SOURCES.md](audio/vesper/SOURCES.md). A interferência de rádio permanece procedural; os áudios anteriores do projeto são preservados.
