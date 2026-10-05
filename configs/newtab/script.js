const canvas = document.getElementById("canvas");
const ctx    = canvas.getContext("2d");
let W, H, stars;
let mx = 0, my = 0, tmx = 0, tmy = 0;

function resize() {
  W = canvas.width  = window.innerWidth;
  H = canvas.height = window.innerHeight;
  makeStars();
}

function makeStars() {
  stars = Array.from({ length: 150 }, () => ({
    x:   Math.random() * W,
    y:   Math.random() * H,
    r:   Math.random() * 1.1 + 0.15,
    o:   Math.random() * 0.4  + 0.08,
    dep: Math.random() * 0.75 + 0.25,
    tw:  Math.random() * Math.PI * 2,
    twS: 0.003 + Math.random() * 0.007,
  }));
}

function draw() {
  tmx += (mx - tmx) * 0.06;
  tmy += (my - tmy) * 0.06;

  ctx.clearRect(0, 0, W, H);

  const offX = (tmx / W - 0.5) * 28;
  const offY = (tmy / H - 0.5) * 28;

  for (const s of stars) {
    s.tw += s.twS;
    const tw = 0.6 + 0.4 * Math.sin(s.tw);
    const px = ((s.x + offX * s.dep) % W + W) % W;
    const py = ((s.y + offY * s.dep) % H + H) % H;
    ctx.beginPath();
    ctx.arc(px, py, s.r, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(220,224,244,${s.o * tw})`;
    ctx.fill();
  }
  requestAnimationFrame(draw);
}

window.addEventListener("mousemove", e => { mx = e.clientX; my = e.clientY; });
window.addEventListener("resize", resize);
resize();
requestAnimationFrame(draw);

const ACCENTS = ["--a1", "--a2", "--a3", "--a4", "--a5"];

function render(groups) {
  const root = document.getElementById("links");
  root.replaceChildren();

  Object.entries(groups).forEach(([name, links], i) => {
    const group = document.createElement("div");
    group.className = "group";
    group.style.setProperty("--accent", `var(${ACCENTS[i % ACCENTS.length]})`);

    const title = document.createElement("div");
    title.className = "group-name";
    title.textContent = name.replace(/[-_]/g, " ");
    group.append(title);

    Object.entries(links).forEach(([label, url]) => {
      const a = document.createElement("a");
      a.href = url;
      const text = document.createElement("span");
      text.textContent = label;
      a.append(text);
      group.append(a);
    });

    root.append(group);
  });
}

fetch("links.json")
  .then(r => r.json())
  .then(render)
  .catch(err => {
    console.error("links.json:", err);
    document.getElementById("links").innerHTML =
      `<p id="error">could not load links.json</p>`;
  });
