// Live uptime-style clock
function tick() {
  const now = new Date();
  const p = (n) => String(n).padStart(2, "0");
  document.getElementById("clock").textContent =
    p(now.getHours()) + ":" + p(now.getMinutes()) + ":" + p(now.getSeconds());
}
tick();
setInterval(tick, 1000);

// Keep the block cursor positioned right after the typed text
const input = document.getElementById("search");
const cursor = document.getElementById("cursor");
const measure = document.createElement("span");
measure.style.position = "absolute";
measure.style.visibility = "hidden";
measure.style.whiteSpace = "pre";
measure.style.font = getComputedStyle(input).font;
document.body.appendChild(measure);

// input starts 8px from the form's left edge (its margin-left)
const baseLeft = 8;
function moveCursor() {
  measure.textContent = input.value;
  cursor.style.left = baseLeft + measure.offsetWidth + 1 + "px";
}
input.addEventListener("input", moveCursor);
window.addEventListener("resize", moveCursor);
moveCursor();

// Make the terminal input the main search bar: grab focus and any typing
function focusInput() {
  input.focus();
}
focusInput();
window.addEventListener("load", focusInput);
window.addEventListener("focus", focusInput);

document.addEventListener("keydown", (e) => {
  if (document.activeElement === input) return;
  if (e.ctrlKey || e.metaKey || e.altKey) return;

  if (e.key === "Backspace") {
    e.preventDefault();
    input.value = input.value.slice(0, -1);
    input.focus();
    moveCursor();
    return;
  }

  if (e.key.length !== 1) return;

  e.preventDefault();
  input.value += e.key;
  input.focus();
  moveCursor();
});
