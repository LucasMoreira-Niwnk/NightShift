// Keep the original CC0 source intact and produce a right-arm-only skinned GLB.
import fs from 'node:fs';
const source = 'game/assets/models/wrad_arms/arms.glb';
const bytes = fs.readFileSync(source);
const jsonLength = bytes.readUInt32LE(12);
const gltf = JSON.parse(bytes.subarray(20, 20 + jsonLength).toString('utf8'));
const binaryStart = 20 + jsonLength + 8;
const binaryLength = bytes.readUInt32LE(20 + jsonLength);
const binary = bytes.subarray(binaryStart, binaryStart + binaryLength);
const sizes = {5121: 1, 5123: 2, 5125: 4, 5126: 4};
function accessor(index, components) {
  const a = gltf.accessors[index], view = gltf.bufferViews[a.bufferView];
  const width = sizes[a.componentType], stride = view.byteStride ?? width * components;
  return Array.from({length: a.count}, (_, i) => Array.from({length: components}, (_, c) => {
    const offset = (view.byteOffset ?? 0) + (a.byteOffset ?? 0) + i * stride + c * width;
    if (a.componentType === 5126) return binary.readFloatLE(offset);
    if (a.componentType === 5121) return binary.readUInt8(offset);
    if (a.componentType === 5123) return binary.readUInt16LE(offset);
    return binary.readUInt32LE(offset);
  }));
}
const primitive = gltf.meshes[0].primitives[0];
const joints = accessor(primitive.attributes.JOINTS_0, 4);
const weights = accessor(primitive.attributes.WEIGHTS_0, 4);
const positions = accessor(primitive.attributes.POSITION, 3);
const original = accessor(primitive.indices, 1).flat();
const wrist = [4.889847, -3.026639, -2.303331];
const forearmBack = [-.452402, .437848, .776931];
const right = joints.map((joint, v) => {
  const weight = joint.reduce((total, bone, c) => total + (gltf.nodes[gltf.skins[0].joints[bone]].name.endsWith('.r') ? weights[v][c] : 0), 0);
  const distance = positions[v].reduce((total, coordinate, axis) => total + (coordinate - wrist[axis]) * forearmBack[axis], 0);
  return weight > .5 && distance < 2.4;
});
const indices = [];
for (let i = 0; i < original.length; i += 3) {
  const triangle = original.slice(i, i + 3);
  if (triangle.every(v => right[v])) indices.push(...triangle);
}
if (indices.length < 300) throw new Error('Could not isolate right arm.');
const offset = Math.ceil(binary.length / 4) * 4;
const indexBytes = Buffer.alloc(Math.ceil(indices.length * 2 / 4) * 4);
indices.forEach((value, i) => indexBytes.writeUInt16LE(value, i * 2));
const viewIndex = gltf.bufferViews.length;
gltf.bufferViews.push({buffer: 0, byteOffset: offset, byteLength: indices.length * 2, target: 34963});
primitive.indices = gltf.accessors.length;
gltf.accessors.push({bufferView: viewIndex, componentType: 5123, count: indices.length, type: 'SCALAR', min: [Math.min(...indices)], max: [Math.max(...indices)]});
const outputBinary = Buffer.concat([binary, Buffer.alloc(offset - binary.length), indexBytes]);
gltf.buffers[0].byteLength = outputBinary.length;
const rawJson = Buffer.from(JSON.stringify(gltf));
const json = Buffer.concat([rawJson, Buffer.alloc((4 - rawJson.length % 4) % 4, 32)]);
const header = Buffer.alloc(20);
header.writeUInt32LE(0x46546c67, 0); header.writeUInt32LE(2, 4);
header.writeUInt32LE(12 + 8 + json.length + 8 + outputBinary.length, 8);
header.writeUInt32LE(json.length, 12); header.writeUInt32LE(0x4e4f534a, 16);
const binaryHeader = Buffer.alloc(8);
binaryHeader.writeUInt32LE(outputBinary.length, 0); binaryHeader.writeUInt32LE(0x004e4942, 4);
fs.writeFileSync('game/assets/models/wrad_arms/right_arm.glb', Buffer.concat([header, json, binaryHeader, outputBinary]));
console.log(`Prepared right arm: ${indices.length / 3} triangles; original rig and textures preserved.`);
