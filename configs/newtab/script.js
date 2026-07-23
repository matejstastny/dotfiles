// ─── clock + date ───
const DAYS   = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"];
const MONTHS = ["january","february","march","april","may","june","july","august","september","october","november","december"];

function tick() {
  const now = new Date();
  const p = n => String(n).padStart(2, "0");
  document.getElementById("clock").textContent = `${p(now.getHours())}:${p(now.getMinutes())}`;
  document.getElementById("date").textContent =
    `${DAYS[now.getDay()]}  ·  ${now.getDate()} ${MONTHS[now.getMonth()]}  ·  ${now.getFullYear()}`;
}
tick();
setInterval(tick, 1000);

// ─── parallax starfield ───
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

// ─── command jumps ───
const commands = {
  gh:        ["github",     "https://github.com/matejstastny"],
  github:    ["github",     "https://github.com/matejstastny"],
  df:        ["dotfiles",   "https://github.com/matejstastny/dotfiles"],
  dotfiles:  ["dotfiles",   "https://github.com/matejstastny/dotfiles"],
  tf:        ["trickfire",  "https://github.com/TrickfireRobotics"],
  org:       ["trickfire",  "https://github.com/TrickfireRobotics"],
  trickfire: ["trickfire",  "https://github.com/TrickfireRobotics"],
  dash:      ["dashboard",  "http://dashboard.trickfirerobotics.com/"],
  dashboard: ["dashboard",  "http://dashboard.trickfirerobotics.com/"],
  docs:      ["docs",       "http://docs.trickfirerobotics.com/"],
  web:       ["website",    "http://trickfirerobotics.com/"],
  site:      ["website",    "http://trickfirerobotics.com/"],
  urc:       ["urc",        "https://github.com/TrickfireRobotics/trickfire-urc"],
  motors:    ["motors",     "https://github.com/TrickfireRobotics/ak-series-lib"],
  drone:     ["drone",      "https://github.com/TrickfireRobotics/trickfire-drone"],
  sim:       ["simulation", "https://github.com/TrickfireRobotics/gazebo-simulations"],
};

function resolve(v) { return commands[v.trim().toLowerCase()] ?? null; }

const input = document.getElementById("search");
const hint  = document.getElementById("hint");

function updateHint() {
  const m = resolve(input.value);
  hint.innerHTML = m ? `<span class="arrow">→</span> ${m[0]}` : "";
}

input.addEventListener("input", updateHint);

document.getElementById("search-form").addEventListener("submit", e => {
  const m = resolve(input.value);
  if (m) { e.preventDefault(); window.location.href = m[1]; }
});

// grab any keystroke while input is not focused
document.addEventListener("keydown", e => {
  if (document.activeElement === input) return;
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  if (e.key === "Backspace") {
    e.preventDefault();
    input.value = input.value.slice(0, -1);
  } else if (e.key.length === 1) {
    e.preventDefault();
    input.value += e.key;
  } else { return; }
  input.focus();
  updateHint();
});

window.addEventListener("focus", () => input.focus());
input.focus();
