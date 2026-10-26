import fs from 'node:fs';
const root = 'game/assets/signage';
fs.mkdirSync(root, { recursive: true });
const px = x => 450 + x * 32;
const py = z => 672 + z * 32;
const rooms = [
  ['RECEPÇÃO', -6, 4, 12, 8, '#d8d6c2'],
  ['CORREDOR', -2, -16, 4, 20, '#e9e5d6'],
  ['SEGURANÇA', -8, -2, 6, 6, '#aebfb1'],
  ['ARQUIVO', 2, -10, 6, 8, '#c9c1aa'],
  ['SALA TÉCNICA', -8, -14, 6, 8, '#bdc6c5'],
];
for (const [name, point] of [['reception', [-4.8, 5.2]], ['security', [-5, -1.5]]]) {
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="900" height="1300" viewBox="0 0 900 1300">
  <rect width="900" height="1300" fill="#e8e1ca"/>
  <rect x="22" y="22" width="856" height="1256" fill="none" stroke="#3f514c" stroke-width="3"/>
  <rect x="22" y="22" width="856" height="92" fill="#243c36"/>
  <text x="450" y="62" text-anchor="middle" font-family="sans-serif" font-size="30" fill="#eee7d1">EDIFÍCIO VESPER</text>
  <text x="450" y="94" text-anchor="middle" font-family="sans-serif" font-size="28" fill="#c6d1bd">PLANTA DO TÉRREO · ORIENTAÇÃO INTERNA</text>
  <g font-family="sans-serif" text-anchor="middle" fill="#263831">`;
  for (const [label, x, z, w, d, color] of rooms) {
    svg += `<rect x="${px(x)}" y="${py(z)}" width="${w * 32}" height="${d * 32}" fill="${color}" stroke="#263831" stroke-width="6"/>`;
    const cx = px(x + w / 2), cy = py(z + d / 2);
    if (label === 'CORREDOR') svg += `<text x="${cx}" y="${cy}" font-size="22" transform="rotate(-90 ${cx} ${cy})">CORREDOR PRINCIPAL</text>`;
    else if (label === 'SALA TÉCNICA') svg += `<text x="${cx}" y="${cy - 8}" font-size="28">SALA</text><text x="${cx}" y="${cy + 18}" font-size="28">TÉCNICA</text>`;
    else svg += `<text x="${cx}" y="${cy - 10}" font-size="28">${label}</text>`;
  }
  // Real door positions, plus the open reception/corridor connection.
  for (const [x, z] of [[-2, 1], [2, -5], [-2, -10]]) {
    svg += `<path d="M ${px(x)} ${py(z - .75)} V ${py(z + .75)}" stroke="#e8e1ca" stroke-width="9"/>
    <path d="M ${px(x)} ${py(z - .75)} l -36 35" stroke="#536e5d" stroke-width="4"/>`;
  }
  svg += `<path d="M ${px(-1.9)} ${py(4)} H ${px(1.9)}" stroke="#e9e5d6" stroke-width="10"/>
  <rect x="${px(1.7)}" y="${py(-14)}" width="10" height="40" fill="#536e5d"/>
  <text x="760" y="245" font-size="16">SAÍDA DE</text><text x="760" y="266" font-size="16">EMERGÊNCIA</text>
  <path d="M 708 260 L ${px(1.8)} ${py(-13.4)}" fill="none" stroke="#536e5d" stroke-width="2"/>
  <text x="450" y="143" font-size="17">ESCADA BLOQUEADA · SEM ACESSO</text>
  <circle cx="${px(point[0])}" cy="${py(point[1])}" r="12" fill="#a34230" stroke="#fff3db" stroke-width="4"/>
  <rect x="92" y="1110" width="716" height="115" fill="#dad5bf" stroke="#526159" stroke-width="2"/>
  <circle cx="135" cy="1141" r="10" fill="#a34230"/>
  <text x="165" y="1148" text-anchor="start" font-size="22">VOCÊ ESTÁ AQUI</text>
  <text x="125" y="1180" text-anchor="start" font-size="22">Segurança: primeiro acesso à esquerda no corredor.</text>
  <text x="125" y="1206" text-anchor="start" font-size="22">Arquivo à direita · Técnica à esquerda, ao fundo.</text>
  <text x="450" y="1254" font-size="15">VESPER / ADMINISTRAÇÃO · REV. 11/2008 · NÃO ACESSAR O SUBSOLO</text>
  </g></svg>`;
  fs.writeFileSync(`${root}/floor_plan_${name}.svg`, svg);
}

