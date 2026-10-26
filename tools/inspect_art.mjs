import fs from 'node:fs';
import path from 'node:path';
const root = 'game/assets/models/kenney';
for (const name of ['chair', 'desk', 'bookcaseOpen', 'books', 'radio', 'computerKeyboard', 'lampSquareCeiling']) {
  const bytes = fs.readFileSync(path.join(root, name + '.glb'));
  const length = bytes.readUInt32LE(12);
  const gltf = JSON.parse(bytes.subarray(20, 20 + length).toString('utf8'));
  const bounds = gltf.meshes.map(mesh => mesh.primitives.map(primitive => {
    const accessor = gltf.accessors[primitive.attributes.POSITION];
    return {min: accessor.min, max: accessor.max};
  }));
  console.log(JSON.stringify({name, bounds, nodes: gltf.nodes.map(({name, scale, translation, rotation}) => ({name, scale, translation, rotation})), images: gltf.images, materials: gltf.materials?.map(m => ({name: m.name, color: m.pbrMetallicRoughness?.baseColorFactor}))}));
}
