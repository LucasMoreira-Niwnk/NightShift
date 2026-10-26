# WRAD Arms — right-hand viewmodel

Source: https://github.com/wwwriks/wrad-arms
Author: wriks / wwwriks
License: CC0 1.0 Universal; original license preserved in LICENSE.

`arms.glb` and the two albedo PNGs are the unmodified upstream source files.
`right_arm.glb` is a derived file made by `tools/prepare_fpv_arm.mjs`. It retains the original mesh attributes, skin weights, skeleton and embedded texture, but indexes only the right hand and forearm. The unused left arm and upper-arm triangles are omitted.

`scripts/hand.gd` applies a finger grip pose, aligns the authored wrist/socket to the first-person camera and hides the model from CCTV. No new anatomy is assembled from cylinders. This is a textured low-poly FPS asset, not a photorealistic hand or a complete animation set.
