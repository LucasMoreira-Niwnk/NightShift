# WRAD Arms — right-hand viewmodel

Source: https://github.com/wwwriks/wrad-arms
Author: wriks / wwwriks
License: CC0 1.0 Universal; original license preserved in LICENSE.

`arms.glb` and the two albedo PNGs are the unmodified upstream source files.
`right_arm.glb` is a derived file made by `tools/prepare_fpv_arm.mjs`. It retains the original mesh attributes, skin weights, skeleton and embedded texture, but indexes only the right hand and forearm. The unused left arm and upper-arm triangles are omitted.

`right_arm.glb` still carries the source's unused left-arm bones. The editable `scenes/mao_lanterna.tscn` removes those bones and uses `assets/models/viewmodel/right_hand_mesh.res`, with only referenced right-arm vertices and a 23-bone right-arm skin. The grip is authored in its `Pegada` animation; `scripts/hand.gd` loads that pose and aligns the beam to the lens. No new anatomy is assembled from cylinders. This is a textured low-poly FPS asset, not a photorealistic hand or a complete animation set.
