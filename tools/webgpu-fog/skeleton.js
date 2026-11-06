// Esqueleto 2D para a criatura de nevoa.
//
// Ideia: o desenho continua sendo uma imagem so. O esqueleto define QUAIS regioes
// dela acompanham cada membro. Mover um osso distorce a imagem naquela regiao, o
// que da a sensacao de andar/sentar sem precisar redesenhar frame a frame.
//
// A deformacao e feita invertida (para cada pixel de saida, de onde ele veio),
// porque e assim que da pra reconstruir a imagem sem buracos.

const TAU = Math.PI * 2;

// Esqueleto base humanoide, em coordenadas da imagem (0..1). O usuario arrasta
// as juntas para encaixar na arte dele; nunca precisa comecar do zero.
export const BASE_BONES = [
  { nome: 'tronco',     pai: -1, ax: 0.50, ay: 0.58, bx: 0.50, by: 0.30, r: 0.22 },
  { nome: 'cabeca',     pai:  0, ax: 0.50, ay: 0.30, bx: 0.50, by: 0.14, r: 0.14 },
  { nome: 'braco E +',  pai:  0, ax: 0.43, ay: 0.34, bx: 0.31, by: 0.46, r: 0.11 },
  { nome: 'braco E -',  pai:  2, ax: 0.31, ay: 0.46, bx: 0.22, by: 0.58, r: 0.10 },
  { nome: 'braco D +',  pai:  0, ax: 0.57, ay: 0.34, bx: 0.69, by: 0.46, r: 0.11 },
  { nome: 'braco D -',  pai:  4, ax: 0.69, ay: 0.46, bx: 0.78, by: 0.58, r: 0.10 },
  { nome: 'perna E +',  pai:  0, ax: 0.45, ay: 0.58, bx: 0.43, by: 0.76, r: 0.12 },
  { nome: 'perna E -',  pai:  6, ax: 0.43, ay: 0.76, bx: 0.42, by: 0.95, r: 0.11 },
  { nome: 'perna D +',  pai:  0, ax: 0.55, ay: 0.58, bx: 0.57, by: 0.76, r: 0.12 },
  { nome: 'perna D -',  pai:  8, ax: 0.57, ay: 0.76, bx: 0.58, by: 0.95, r: 0.11 },
];

// amplitude (em radianos) de cada osso no ciclo de caminhada, e o atraso de fase
const ANDAR = {
  'perna E +': [ 0.45, 0 ], 'perna E -': [ 0.30, 0.9 ],
  'perna D +': [-0.45, 0 ], 'perna D -': [ 0.30, 0.9 + Math.PI ],
  'braco E +': [-0.35, 0 ], 'braco E -': [ 0.18, 0.6 ],
  'braco D +': [ 0.35, 0 ], 'braco D -': [ 0.18, 0.6 + Math.PI ],
  'tronco':    [ 0.04, 0 ],
};

export function clonarBase() {
  return BASE_BONES.map(b => ({ ...b, ang: 0 }));
}

// --- matrizes 2x3 (m00 m01 tx / m10 m11 ty) ---
const mul = (A, B) => ({
  m00: A.m00*B.m00 + A.m01*B.m10, m01: A.m00*B.m01 + A.m01*B.m11,
  m10: A.m10*B.m00 + A.m11*B.m10, m11: A.m10*B.m01 + A.m11*B.m11,
  tx:  A.m00*B.tx  + A.m01*B.ty  + A.tx,
  ty:  A.m10*B.tx  + A.m11*B.ty  + A.ty,
});
const aplicar = (M, x, y) => [M.m00*x + M.m01*y + M.tx, M.m10*x + M.m11*y + M.ty];
function inverter(M) {
  const det = M.m00*M.m11 - M.m01*M.m10 || 1e-6;
  const i00 =  M.m11/det, i01 = -M.m01/det, i10 = -M.m10/det, i11 = M.m00/det;
  return { m00:i00, m01:i01, m10:i10, m11:i11,
           tx: -(i00*M.tx + i01*M.ty), ty: -(i10*M.tx + i11*M.ty) };
}

// Cinematica direta: a pose de um osso e a do pai mais a propria rotacao,
// girada em torno da sua junta de origem. E o que faz o antebraco seguir o braco.
export function poses(bones) {
  const out = [];
  for (let i = 0; i < bones.length; i++) {
    const b = bones[i], c = Math.cos(b.ang || 0), s = Math.sin(b.ang || 0);
    const local = { m00:c, m01:-s, m10:s, m11:c,
                    tx: b.ax - (c*b.ax - s*b.ay), ty: b.ay - (s*b.ax + c*b.ay) };
    const M = b.pai >= 0 ? mul(out[b.pai].M, local) : local;
    out.push({ M, inv: inverter(M),
               pa: aplicar(M, b.ax, b.ay), pb: aplicar(M, b.bx, b.by), r: b.r });
  }
  return out;
}

function distSeg(px, py, a, b, ar) {
  const dx = (b[0]-a[0])*ar, dy = b[1]-a[1];
  const ex = (px-a[0])*ar,  ey = py-a[1];
  const l2 = dx*dx + dy*dy;
  const t = l2 > 0 ? Math.max(0, Math.min(1, (ex*dx + ey*dy)/l2)) : 0;
  const cx = ex - dx*t, cy = ey - dy*t;
  return Math.hypot(cx, cy);
}

// Reamostra a mascara segundo a pose. Trabalha em no maximo MAXW de largura:
// nevoa nao precisa da resolucao cheia e isso mantem o rebake rapido o bastante
// para arrastar a junta e ver o resultado.
const MAXW = 512;
export function deformar(src, bones, aspect) {
  const sc = Math.min(1, MAXW / src.width);
  const w = Math.max(2, Math.round(src.width*sc)), h = Math.max(2, Math.round(src.height*sc));
  const cv = document.createElement('canvas'); cv.width = w; cv.height = h;
  const g = cv.getContext('2d', { willReadFrequently:true });
  g.drawImage(src, 0, 0, w, h);
  const srcData = g.getImageData(0, 0, w, h), s = srcData.data;
  const out = g.createImageData(w, h), o = out.data;

  const P = poses(bones), ar = aspect || 1;
  for (let y = 0; y < h; y++) {
    const v = (y + 0.5) / h;
    for (let x = 0; x < w; x++) {
      const u = (x + 0.5) / w;
      let soma = 0, rx = 0, ry = 0;
      for (const p of P) {
        const d = distSeg(u, v, p.pa, p.pb, ar);
        let wt = 1 - d/p.r;
        if (wt <= 0) continue;
        wt *= wt;
        const q = aplicar(p.inv, u, v);
        rx += wt*q[0]; ry += wt*q[1]; soma += wt;
      }
      const su = soma > 0 ? rx/soma : u, sv = soma > 0 ? ry/soma : v;
      const sx = Math.round(su*w - 0.5), sy = Math.round(sv*h - 0.5);
      const di = (y*w + x)*4;
      if (sx < 0 || sy < 0 || sx >= w || sy >= h) continue;   // fora: fica vazio
      const si = (sy*w + sx)*4;
      o[di] = s[si]; o[di+1] = s[si+1]; o[di+2] = s[si+2]; o[di+3] = s[si+3];
    }
  }
  g.putImageData(out, 0, 0);
  return cv;
}

// --- editor -----------------------------------------------------------------

export function criarEditor({ raiz, aoMudar }) {
  let bones = clonarBase(), sel = 0, modo = 'encaixar', andando = false, t0 = 0;
  let fundo = null, aspect = 1, arrastando = null, grande = false, sobre = null;
  const RAIO = 9;   // bolinha da junta, em pixels de tela

  raiz.innerHTML = `
    <div class=sk-top>
      <b>esqueleto</b>
      <label><input type=radio name=skmodo value=encaixar checked> encaixar</label>
      <label><input type=radio name=skmodo value=posar> posar</label>
      <button class=sk-zoom title="usa a altura da janela">ampliar</button>
    </div>
    <canvas class=sk-cv></canvas>
    <div class=sk-bot>
      <select class=sk-sel></select>
      <label>angulo <input class=sk-ang type=range min=-180 max=180 value=0></label>
      <label>alcance <input class=sk-r type=range min=2 max=40 value=12></label>
      <label><input class=sk-andar type=checkbox> andar</label>
      <button class=sk-zero>zerar pose</button>
      <button class=sk-exp>exportar json</button>
    </div>`;

  const cv = raiz.querySelector('.sk-cv'), g = cv.getContext('2d');
  const selEl = raiz.querySelector('.sk-sel'), angEl = raiz.querySelector('.sk-ang');
  const rEl = raiz.querySelector('.sk-r');

  bones.forEach((b, i) => selEl.add(new Option(b.nome, i)));

  function redimensionar() {
    const h = Math.round(innerHeight * (grande ? 0.86 : 0.52));
    cv.height = h; cv.width = Math.max(120, Math.round(h * Math.max(aspect, 0.05)));
    cv.style.width = cv.width + 'px'; cv.style.height = h + 'px';
    raiz.closest('#sk').classList.toggle('grande', grande);
    desenhar();
  }
  addEventListener('resize', redimensionar);

  const paraTela = (u, v) => [u*cv.width, v*cv.height];
  const paraUV = (x, y) => [x/cv.width, y/cv.height];

  function desenhar() {
    g.clearRect(0, 0, cv.width, cv.height);
    if (fundo) { g.globalAlpha = 0.65; g.drawImage(fundo, 0, 0, cv.width, cv.height); g.globalAlpha = 1; }
    const P = poses(bones);
    P.forEach((p, i) => {
      const [ax, ay] = paraTela(...p.pa), [bx, by] = paraTela(...p.pb);
      g.strokeStyle = i === sel ? '#ffd24a' : '#6cf';
      g.lineWidth = i === sel ? 3 : 2;
      g.beginPath(); g.moveTo(ax, ay); g.lineTo(bx, by); g.stroke();
      if (i === sel) {   // alcance do osso: a regiao da imagem que ele leva junto
        g.strokeStyle = '#ffd24a55'; g.lineWidth = bones[i].r*2*cv.width;
        g.beginPath(); g.moveTo(ax, ay); g.lineTo(bx, by); g.stroke(); g.lineWidth = 2;
      }
      for (const [j, [x, y]] of [[0, [ax, ay]], [1, [bx, by]]]) {
        const alvo = sobre && sobre.i === i && sobre.ponta === (j ? 'b' : 'a');
        g.fillStyle = alvo ? '#ffd24a' : '#fff';
        g.strokeStyle = '#000a'; g.lineWidth = 2;
        g.beginPath(); g.arc(x, y, alvo ? RAIO + 3 : RAIO, 0, TAU); g.fill(); g.stroke();
      }
    });
  }

  function marcarMudanca() { desenhar(); aoMudar(bones); }

  function selecionar(i) {
    sel = i; selEl.value = String(i);
    angEl.value = String(Math.round((bones[i].ang || 0) * 180/Math.PI));
    rEl.value = String(Math.round(bones[i].r * 100));
    desenhar();
  }

  // Pega a junta mais proxima medindo em PIXELS de tela: medir em UV fazia uma
  // imagem alta e estreita ter uma area de clique achatada e quase impossivel.
  function pegarJunta(u, v) {
    const P = poses(bones);
    let achou = null, dmin = RAIO * 2.2;
    P.forEach((p, i) => {
      for (const [ponta, pt] of [['a', p.pa], ['b', p.pb]]) {
        const [x, y] = paraTela(...pt);
        const d = Math.hypot(x - u*cv.width, y - v*cv.height);
        if (d < dmin) { dmin = d; achou = { i, ponta }; }
      }
    });
    return achou;
  }

  // --- arrastar juntas (modo encaixar) ---
  cv.addEventListener('pointerdown', e => {
    const rect = cv.getBoundingClientRect();
    const [u, v] = paraUV(e.clientX - rect.left, e.clientY - rect.top);
    const melhor = pegarJunta(u, v);
    if (!melhor) {   // clicou longe de junta: so seleciona o osso mais proximo
      let dl = 1e9;
      poses(bones).forEach((p, i) => {
        const d = distSeg(u, v, p.pa, p.pb, aspect);
        if (d < dl) { dl = d; melhor = { i, ponta: null }; }
      });
      if (melhor) selecionar(melhor.i);
      return;
    }
    selecionar(melhor.i);
    if (modo === 'encaixar') { arrastando = melhor; cv.setPointerCapture(e.pointerId); }
  });

  cv.addEventListener('pointermove', e => {
    const r0 = cv.getBoundingClientRect();
    if (!arrastando) {
      const [hu, hv] = paraUV(e.clientX - r0.left, e.clientY - r0.top);
      const novo = pegarJunta(hu, hv);
      const mudou = (novo && sobre) ? (novo.i !== sobre.i || novo.ponta !== sobre.ponta)
                                    : (novo !== sobre);
      sobre = novo;
      cv.style.cursor = novo ? 'grab' : 'crosshair';
      if (mudou) desenhar();
      return;
    }
    const rect = cv.getBoundingClientRect();
    const [u, v] = paraUV(e.clientX - rect.left, e.clientY - rect.top);
    const { i, ponta } = arrastando, b = bones[i];
    const ox = b[ponta+'x'], oy = b[ponta+'y'];
    b[ponta+'x'] = u; b[ponta+'y'] = v;
    // junta compartilhada anda junto, senao o membro filho descola do pai
    bones.forEach(f => {
      if (Math.abs(f.ax - ox) < 1e-6 && Math.abs(f.ay - oy) < 1e-6) { f.ax = u; f.ay = v; }
      if (Math.abs(f.bx - ox) < 1e-6 && Math.abs(f.by - oy) < 1e-6 && f !== b) { f.bx = u; f.by = v; }
    });
    marcarMudanca();
  });
  cv.addEventListener('pointerup', () => { arrastando = null; });

  raiz.querySelectorAll('input[name=skmodo]').forEach(r =>
    r.addEventListener('change', () => { modo = r.value; }));
  selEl.addEventListener('change', () => selecionar(+selEl.value));
  angEl.addEventListener('input', () => {
    bones[sel].ang = (+angEl.value) * Math.PI/180; marcarMudanca();
  });
  rEl.addEventListener('input', () => { bones[sel].r = (+rEl.value)/100; marcarMudanca(); });
  raiz.querySelector('.sk-zoom').addEventListener('click', e => {
    grande = !grande; e.target.textContent = grande ? 'reduzir' : 'ampliar'; redimensionar();
  });
  raiz.querySelector('.sk-zero').addEventListener('click', () => {
    bones.forEach(b => b.ang = 0); angEl.value = '0'; marcarMudanca();
  });
  raiz.querySelector('.sk-andar').addEventListener('change', e => {
    andando = e.target.checked; t0 = performance.now();
    if (!andando) { bones.forEach(b => b.ang = 0); marcarMudanca(); }
  });
  raiz.querySelector('.sk-exp').addEventListener('click', () => {
    const blob = new Blob([JSON.stringify({ bones }, null, 2)], { type:'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = 'esqueleto.json'; a.click();
  });

  return {
    get bones() { return bones; },
    definirFundo(img, asp) { fundo = img; aspect = asp; redimensionar(); },
    // chamado todo frame; so devolve true quando a pose mudou de verdade
    tick(now) {
      if (!andando) return false;
      const t = (now - t0)/1000;
      for (const b of bones) {
        const a = ANDAR[b.nome];
        b.ang = a ? a[0] * Math.sin(t*2.4 + a[1]) : 0;
      }
      desenhar();
      return true;
    },
  };
}
