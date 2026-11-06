// Malha 3D a partir da mesma criatura.
//
// O campo de densidade que o raymarch consome ja e 3D: silhueta x espessura.
// Entao da para extrair a superficie onde ele cruza um limiar e sair com um
// corpo de verdade, com os ossos do editor virando um Skeleton3D nativo.
//
// Usa surface nets em vez de marching cubes: produz o mesmo tipo de superficie
// fechada para formas gordas como esta, sem as tabelas de 1400 numeros.

// ---------------------------------------------------------------- campo 2D

// Pre-calcula mascara dilatada e espessura numa grade 2D. Sem isso o laco 3D
// refaria a dilatacao (7 amostras) em cada um do milhao de voxels.
function mapas2D(maskCv, { inflate, largura }) {
  const w = Math.min(largura, maskCv.width);
  const h = Math.max(2, Math.round(w * maskCv.height / maskCv.width));
  const c = document.createElement('canvas'); c.width = w; c.height = h;
  const g = c.getContext('2d', { willReadFrequently: true });
  g.drawImage(maskCv, 0, 0, w, h);
  const d = g.getImageData(0, 0, w, h).data;

  const mask = new Float32Array(w*h), esp = new Float32Array(w*h);
  for (let i = 0, j = 0; i < d.length; i += 4, j++) {
    mask[j] = d[i+3]/255;
    esp[j]  = d[i]/255;
  }
  if (inflate > 0.01) {                       // mesma dilatacao do shader
    const r = Math.max(1, Math.round(inflate * 0.07 * w));
    const dil = new Float32Array(w*h);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
      let m = mask[y*w + x];
      for (let k = 0; k < 6; k++) {
        const a = k * Math.PI/3;
        const sx = Math.round(x + Math.cos(a)*r), sy = Math.round(y + Math.sin(a)*r);
        if (sx >= 0 && sy >= 0 && sx < w && sy < h) m = Math.max(m, mask[sy*w + sx]);
      }
      dil[y*w + x] = m;
    }
    return { w, h, mask: dil, esp };
  }
  return { w, h, mask, esp };
}

const bilinear = (arr, w, h, u, v) => {
  const x = Math.min(w-1.001, Math.max(0, u*w - 0.5));
  const y = Math.min(h-1.001, Math.max(0, v*h - 0.5));
  const x0 = Math.floor(x), y0 = Math.floor(y), fx = x - x0, fy = y - y0;
  const i = y0*w + x0;
  return (arr[i]*(1-fx) + arr[i+1]*fx)*(1-fy) +
         (arr[i+w]*(1-fx) + arr[i+w+1]*fx)*fy;
};

// ------------------------------------------------------------ surface nets

export function gerarMalha(maskCv, opts) {
  const { artAsp, thick, inflate, res } = opts;
  const m2 = mapas2D(maskCv, { inflate, largura: 320 });

  // caixa do modelo: mesma do shader, x em [-artAsp/2, artAsp/2]
  const meiaX = artAsp/2, meiaY = 0.5;
  const maxZ = Math.max(thick, 0.05) * 0.6 + 0.02;
  const nx = Math.max(16, Math.round(res * artAsp)), ny = res;
  const nz = Math.max(8, Math.round(res * maxZ * 2));

  const campo = (x, y, z) => {
    const u = x/artAsp + 0.5, v = 0.5 - y;
    if (u < 0 || u > 1 || v < 0 || v > 1) return -1;
    const mk = bilinear(m2.mask, m2.w, m2.h, u, v);
    const halfZ = Math.max(bilinear(m2.esp, m2.w, m2.h, u, v) + inflate*0.6, 0.03) * thick;
    return Math.min(mk - 0.45, 1 - Math.abs(z)/Math.max(halfZ, 1e-3));
  };

  const px = i => -meiaX + (2*meiaX) * i/nx;
  const py = j =>  meiaY - (2*meiaY) * j/ny;
  const pz = k => -maxZ  + (2*maxZ)  * k/nz;

  // amostra a grade inteira uma vez
  const sx = nx+1, sy = ny+1, sz = nz+1;
  const g = new Float32Array(sx*sy*sz);
  const ig = (i,j,k) => (k*sy + j)*sx + i;
  for (let k = 0; k < sz; k++) for (let j = 0; j < sy; j++) for (let i = 0; i < sx; i++)
    g[ig(i,j,k)] = campo(px(i), py(j), pz(k));

  // um vertice por celula que tem troca de sinal, na media dos cruzamentos
  const CANTOS = [[0,0,0],[1,0,0],[0,1,0],[1,1,0],[0,0,1],[1,0,1],[0,1,1],[1,1,1]];
  const ARESTAS = [[0,1],[2,3],[4,5],[6,7],[0,2],[1,3],[4,6],[5,7],[0,4],[1,5],[2,6],[3,7]];
  const idxCel = new Int32Array(nx*ny*nz).fill(-1);
  const ic = (i,j,k) => (k*ny + j)*nx + i;
  const pos = [], nor = [];

  for (let k = 0; k < nz; k++) for (let j = 0; j < ny; j++) for (let i = 0; i < nx; i++) {
    const v = CANTOS.map(([a,b,c]) => g[ig(i+a, j+b, k+c)]);
    let dentro = 0;
    for (const s of v) if (s > 0) dentro++;
    if (dentro === 0 || dentro === 8) continue;

    let cx = 0, cy = 0, cz = 0, n = 0;
    for (const [a, b] of ARESTAS) {
      if ((v[a] > 0) === (v[b] > 0)) continue;
      const t = v[a] / (v[a] - v[b]);
      const A = CANTOS[a], B = CANTOS[b];
      cx += A[0] + (B[0]-A[0])*t; cy += A[1] + (B[1]-A[1])*t; cz += A[2] + (B[2]-A[2])*t;
      n++;
    }
    cx /= n; cy /= n; cz /= n;
    const X = px(i) + cx*(2*meiaX/nx);
    const Y = py(j) - cy*(2*meiaY/ny);
    const Z = pz(k) + cz*(2*maxZ/nz);

    const e = 1/res;   // normal pelo gradiente do campo: mais lisa que por face
    let gx = campo(X+e,Y,Z) - campo(X-e,Y,Z);
    let gy = campo(X,Y+e,Z) - campo(X,Y-e,Z);
    let gz = campo(X,Y,Z+e) - campo(X,Y,Z-e);
    const L = Math.hypot(gx,gy,gz) || 1;

    idxCel[ic(i,j,k)] = pos.length/3;
    pos.push(X, Y, Z);
    nor.push(gx/L, gy/L, gz/L);
  }

  // cada aresta da grade com troca de sinal vira um quad entre as 4 celulas
  const idx = [];
  const quad = (a,b,c,d, inverter) => {
    if (a<0||b<0||c<0||d<0) return;
    if (inverter) idx.push(a,c,b, a,d,c); else idx.push(a,b,c, a,c,d);
  };
  for (let k = 0; k < sz; k++) for (let j = 0; j < sy; j++) for (let i = 0; i < sx; i++) {
    const s0 = g[ig(i,j,k)] > 0;
    if (i < nx && j > 0 && k > 0 && (g[ig(i+1,j,k)] > 0) !== s0)
      quad(idxCel[ic(i,j-1,k-1)], idxCel[ic(i,j,k-1)], idxCel[ic(i,j,k)], idxCel[ic(i,j-1,k)], s0);
    if (j < ny && i > 0 && k > 0 && (g[ig(i,j+1,k)] > 0) !== s0)
      quad(idxCel[ic(i-1,j,k-1)], idxCel[ic(i-1,j,k)], idxCel[ic(i,j,k)], idxCel[ic(i,j,k-1)], s0);
    if (k < nz && i > 0 && j > 0 && (g[ig(i,j,k+1)] > 0) !== s0)
      quad(idxCel[ic(i-1,j-1,k)], idxCel[ic(i,j-1,k)], idxCel[ic(i,j,k)], idxCel[ic(i-1,j,k)], s0);
  }

  // UV planar frontal: e o mesmo mapeamento que o shader usa, entao o desenho
  // cai na malha sem ninguem precisar pintar nada
  const uv = [];
  for (let i = 0; i < pos.length; i += 3)
    uv.push(pos[i]/artAsp + 0.5, 0.5 - pos[i+1]);

  return { pos: new Float32Array(pos), nor: new Float32Array(nor),
           uv: new Float32Array(uv), idx: new Uint32Array(idx) };
}

// ------------------------------------------------------------------ pesos

// Mesma conta de distancia ao segmento que ja deforma a imagem; aqui ela vira
// peso de vertice. Os ossos do editor ficam no plano z=0.
export function pesos(malha, ossos, artAsp) {
  const n = malha.pos.length/3;
  const jnt = new Uint8Array(n*4), wgt = new Float32Array(n*4);
  const emModelo = (u, v) => [ (u - 0.5)*artAsp, 0.5 - v ];

  for (let i = 0; i < n; i++) {
    const x = malha.pos[i*3], y = malha.pos[i*3+1], z = malha.pos[i*3+2];
    const cand = [];
    ossos.forEach((b, bi) => {
      const [ax, ay] = emModelo(b.ax, b.ay), [bx, by] = emModelo(b.bx, b.by);
      const dx = bx-ax, dy = by-ay, l2 = dx*dx + dy*dy;
      const t = l2 > 0 ? Math.max(0, Math.min(1, ((x-ax)*dx + (y-ay)*dy)/l2)) : 0;
      const d = Math.hypot(x - (ax+dx*t), y - (ay+dy*t), z);
      const w = 1 - d/Math.max(b.r, 1e-3);
      if (w > 0) cand.push([bi, w*w]);
    });
    cand.sort((a, b) => b[1] - a[1]);
    const top = cand.slice(0, 4);
    const soma = top.reduce((s, c) => s + c[1], 0);
    if (soma <= 0) { jnt[i*4] = 0; wgt[i*4] = 1; continue; }
    top.forEach((c, k) => { jnt[i*4+k] = c[0]; wgt[i*4+k] = c[1]/soma; });
  }
  return { jnt, wgt };
}

// -------------------------------------------------------------------- glb

const alinhar4 = n => (n + 3) & ~3;

export async function exportarGLB(malha, skin, ossos, artAsp, texturaCanvas) {
  const blobPng = await new Promise(r => texturaCanvas.toBlob(r, 'image/png'));
  const png = new Uint8Array(await blobPng.arrayBuffer());

  const partes = [], vistas = [], acessores = [];
  let desl = 0;
  const por = (dados, alvo) => {
    const bytes = new Uint8Array(dados.buffer, dados.byteOffset, dados.byteLength);
    partes.push(bytes, new Uint8Array(alinhar4(bytes.length) - bytes.length));
    const v = { buffer: 0, byteOffset: desl, byteLength: bytes.length };
    if (alvo) v.target = alvo;
    vistas.push(v);
    desl += alinhar4(bytes.length);
    return vistas.length - 1;
  };
  const acessor = (vista, tipoComp, conta, tipo, extra = {}) => {
    acessores.push({ bufferView: vista, componentType: tipoComp, count: conta, type: tipo, ...extra });
    return acessores.length - 1;
  };

  let minP = [1e9,1e9,1e9], maxP = [-1e9,-1e9,-1e9];
  for (let i = 0; i < malha.pos.length; i += 3) for (let k = 0; k < 3; k++) {
    minP[k] = Math.min(minP[k], malha.pos[i+k]);
    maxP[k] = Math.max(maxP[k], malha.pos[i+k]);
  }
  const nv = malha.pos.length/3;
  const aPos = acessor(por(malha.pos, 34962), 5126, nv, 'VEC3', { min: minP, max: maxP });
  const aNor = acessor(por(malha.nor, 34962), 5126, nv, 'VEC3');
  const aUv  = acessor(por(malha.uv,  34962), 5126, nv, 'VEC2');
  const aJnt = acessor(por(skin.jnt, 34962), 5121, nv, 'VEC4');
  const aWgt = acessor(por(skin.wgt, 34962), 5126, nv, 'VEC4');
  const aIdx = acessor(por(malha.idx, 34963), 5125, malha.idx.length, 'SCALAR');

  // matriz inversa de bind: no repouso cada osso so translada ate sua junta
  const cabeca = b => [ (b.ax - 0.5)*artAsp, 0.5 - b.ay, 0 ];
  const ibm = new Float32Array(ossos.length*16);
  ossos.forEach((b, i) => {
    const [x,y,z] = cabeca(b);
    ibm.set([1,0,0,0, 0,1,0,0, 0,0,1,0, -x,-y,-z,1], i*16);
  });
  const aIbm = acessor(por(ibm), 5126, ossos.length, 'MAT4');
  const vPng = por(png);

  const nosOssos = ossos.map((b, i) => {
    const p = cabeca(b);
    const pai = b.pai >= 0 ? cabeca(ossos[b.pai]) : [0,0,0];
    const no = { name: b.nome.replace(/\s+/g, '_'),
                 translation: [p[0]-pai[0], p[1]-pai[1], p[2]-pai[2]] };
    const filhos = ossos.map((f, k) => f.pai === i ? k + 1 : -1).filter(k => k > 0);
    if (filhos.length) no.children = filhos;
    return no;
  });
  const raizes = ossos.map((b, i) => b.pai < 0 ? i + 1 : -1).filter(i => i > 0);

  const gltf = {
    asset: { version: '2.0', generator: 'fog-creature' },
    scene: 0,
    scenes: [{ nodes: [0, ...raizes] }],
    nodes: [{ name: 'criatura', mesh: 0, skin: 0 }, ...nosOssos],
    meshes: [{ name: 'criatura', primitives: [{
      attributes: { POSITION: aPos, NORMAL: aNor, TEXCOORD_0: aUv,
                    JOINTS_0: aJnt, WEIGHTS_0: aWgt },
      indices: aIdx, material: 0 }] }],
    skins: [{ inverseBindMatrices: aIbm, joints: ossos.map((_, i) => i + 1),
              skeleton: raizes[0] }],
    materials: [{ name: 'nevoa', doubleSided: true, alphaMode: 'MASK', alphaCutoff: 0.5,
      pbrMetallicRoughness: { baseColorTexture: { index: 0 },
                              metallicFactor: 0, roughnessFactor: 1 } }],
    textures: [{ source: 0, sampler: 0 }],
    images: [{ bufferView: vPng, mimeType: 'image/png' }],
    samplers: [{ magFilter: 9729, minFilter: 9729, wrapS: 33071, wrapT: 33071 }],
    buffers: [{ byteLength: desl }],
    bufferViews: vistas,
    accessors: acessores,
  };

  const json = new TextEncoder().encode(JSON.stringify(gltf));
  const jsonPad = new Uint8Array(alinhar4(json.length) - json.length).fill(0x20);
  const bin = new Uint8Array(desl);
  let o = 0; for (const p of partes) { bin.set(p, o); o += p.length; }

  const total = 12 + 8 + json.length + jsonPad.length + 8 + bin.length;
  const buf = new ArrayBuffer(total), dv = new DataView(buf), u8 = new Uint8Array(buf);
  dv.setUint32(0, 0x46546C67, true); dv.setUint32(4, 2, true); dv.setUint32(8, total, true);
  dv.setUint32(12, json.length + jsonPad.length, true); dv.setUint32(16, 0x4E4F534A, true);
  u8.set(json, 20); u8.set(jsonPad, 20 + json.length);
  const oBin = 20 + json.length + jsonPad.length;
  dv.setUint32(oBin, bin.length, true); dv.setUint32(oBin + 4, 0x004E4942, true);
  u8.set(bin, oBin + 8);
  return new Blob([buf], { type: 'model/gltf-binary' });
}
