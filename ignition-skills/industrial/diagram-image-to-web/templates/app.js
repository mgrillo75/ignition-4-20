async function loadDiagram() {
  const response = await fetch('./diagram.json');
  return response.json();
}

function svgEl(name, attrs = {}) {
  const el = document.createElementNS('http://www.w3.org/2000/svg', name);
  for (const [key, value] of Object.entries(attrs)) el.setAttribute(key, String(value));
  return el;
}

function render(diagram) {
  const title = document.getElementById('title');
  const svg = document.getElementById('diagram');
  title.textContent = diagram.metadata?.title || 'Diagram Web View';
  const width = diagram.renderHints?.width || 1600;
  const height = diagram.renderHints?.height || 900;
  svg.setAttribute('viewBox', `0 0 ${width} ${height}`);

  for (const conn of diagram.connections || []) {
    const points = (conn.points || []).map(([x, y]) => `${x},${y}`).join(' ');
    svg.appendChild(svgEl('polyline', { points, class: 'trace' }));
  }

  for (const sym of diagram.symbols || []) {
    const [x, y, w, h] = sym.bbox || [0, 0, 80, 80];
    svg.appendChild(svgEl('rect', { x, y, width: w, height: h, rx: 6, class: 'symbol' }));
    if (sym.label) {
      const text = svgEl('text', { x: x + w + 12, y: y + Math.max(22, h / 2), class: 'label' });
      text.textContent = sym.label;
      svg.appendChild(text);
    }
  }
}

loadDiagram().then(render).catch(err => {
  console.error('Failed to load diagram.json', err);
});
