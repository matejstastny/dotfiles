import {
    bytes,
    clock,
    createJob,
    downloadHref,
    need,
    probe,
    rate,
    type FileEntry,
    type JobRequest,
    type Update,
} from "./api";

const form = need<HTMLFormElement>("#grab");
const urlField = need<HTMLInputElement>("#url");
const button = need<HTMLButtonElement>("#go");

const metaBox = need<HTMLElement>("#meta");
const metaTitle = need<HTMLElement>("#meta-title");
const metaBy = need<HTMLElement>("#meta-by");
const metaLength = need<HTMLElement>("#meta-length");

const heightRow = need<HTMLElement>("#row-height");
const heightSelect = need<HTMLSelectElement>("#height");
const bitrateRow = need<HTMLElement>("#row-bitrate");
const bitrateSelect = need<HTMLSelectElement>("#bitrate");
const modeSelect = need<HTMLSelectElement>("#mode");

const coverCheck = need<HTMLInputElement>("#thumbnail");
const sponsorLabel = need<HTMLElement>("#sponsor-label");

const statusBox = need<HTMLElement>("#status");
const stageText = need<HTMLElement>("#stage");
const fill = need<HTMLElement>("#fill");
const nums = need<HTMLElement>("#nums");
const note = need<HTMLElement>("#note");
const actions = need<HTMLElement>("#result");

const LADDER = [2160, 1440, 1080, 720, 480, 360];

let stream: EventSource | null = null;
let probing: AbortController | null = null;
let settled = true;

function chosenFormat(): "mp4" | "mp3" {
    return need<HTMLInputElement>("input[name='format']:checked").value === "mp3" ? "mp3" : "mp4";
}

function syncFormat(): void {
    const audio = chosenFormat() === "mp3";
    heightRow.hidden = audio;
    bitrateRow.hidden = !audio;
    sponsorLabel.textContent = audio ? "cut sponsor segments" : "mark sponsor segments";
    coverCheck.parentElement?.setAttribute("title", audio ? "cover art in the mp3 tags" : "cover art as the mp4 poster frame");
}

// only offer resolutions the video actually has, tallest first, so a 240p
// upload never pretends it can give you 1080p
function fillHeights(available: number[]): void {
    const options = available.length > 0 ? [...new Set(available)].sort((a, b) => b - a) : LADDER;
    const previous = Number(heightSelect.value);

    heightSelect.innerHTML = "";
    for (const height of options) {
        heightSelect.add(new Option(`${height}p`, String(height)));
    }
    heightSelect.add(new Option("best available", "0"));

    const preferred = options.includes(previous)
        ? previous
        : (options.find((height) => height <= 1080) ?? options[0]);
    heightSelect.value = String(preferred);
}

async function runProbe(url: string): Promise<void> {
    probing?.abort();
    probing = new AbortController();

    try {
        const found = await probe(url, probing.signal);
        metaTitle.textContent = found.title;
        metaBy.textContent = found.uploader ?? "unknown";
        metaLength.textContent = [found.duration, found.source?.toLowerCase()].filter(Boolean).join(" · ");
        metaBox.hidden = false;
        fillHeights(found.heights);
    } catch (error) {
        if (error instanceof DOMException && error.name === "AbortError") return;
        metaBox.hidden = true;
        say(error instanceof Error ? error.message : "could not read that link", true);
    }
}

function say(message: string, bad = false): void {
    statusBox.hidden = false;
    note.textContent = message;
    note.classList.toggle("bad", bad);
    note.classList.toggle("good", !bad);
}

function paint(update: Update): void {
    statusBox.hidden = false;
    stageText.textContent = update.label ?? update.stage;

    const known = update.percent > 0 && update.stage !== "queued" && update.stage !== "prepare";
    fill.classList.toggle("indeterminate", !known && update.stage !== "error");
    fill.style.width = known ? `${update.percent.toFixed(1)}%` : "";

    const parts = [
        known ? `${update.percent.toFixed(0)}%` : "",
        rate(update.speed ?? 0),
        update.eta && update.eta > 0 ? `eta ${clock(update.eta)}` : "",
        update.total ? bytes(update.total) : "",
    ].filter(Boolean);
    nums.textContent = parts.join("   ");
}

function pull(entry: FileEntry): void {
    const link = document.createElement("a");
    link.href = downloadHref(entry.id);
    link.download = entry.name;
    link.rel = "noopener";
    document.body.append(link);
    link.click();
    link.remove();
}

function landed(entry: FileEntry): void {
    const where = entry.library && entry.cached ? "cached and filed into io's library" : entry.library ? "filed into io's library" : "in io's cache";
    say(`${entry.name} · ${bytes(entry.size)} · ${where}`);

    actions.innerHTML = "";
    const get = document.createElement("a");
    get.className = "ghost";
    get.href = downloadHref(entry.id);
    get.download = entry.name;
    get.textContent = "save to this device";
    actions.append(get);

    if (entry.path) {
        const path = document.createElement("span");
        path.className = "tag";
        path.textContent = entry.path;
        actions.append(path);
    }

    // library only means she asked for it to stay on io, so do not push a copy
    if (modeSelect.value !== "library") pull(entry);
}

function watch(id: string): void {
    stream?.close();
    stream = new EventSource(`/api/jobs/${id}/events`);

    stream.onmessage = (message: MessageEvent<string>) => {
        const update = JSON.parse(message.data) as Update;
        paint(update);

        if (update.stage === "done" && update.entry) {
            settle();
            landed(update.entry);
        } else if (update.stage === "error") {
            settle();
            say(update.message ?? "that download failed", true);
        }
    };

    stream.onerror = () => {
        if (settled) return;
        settle();
        say("lost contact with the server, check recent to see if it landed anyway", true);
    };
}

function settle(): void {
    settled = true;
    stream?.close();
    stream = null;
    button.disabled = false;
    button.textContent = "download";
}

function reset(): void {
    settle();
    form.reset();
    syncFormat();
    metaBox.hidden = true;
    statusBox.hidden = true;
    actions.innerHTML = "";
    urlField.focus();
}

form.addEventListener("submit", async (submitted: SubmitEvent) => {
    submitted.preventDefault();
    if (!settled) return;

    const url = urlField.value.trim();
    if (url === "") {
        urlField.focus();
        return;
    }

    const job: JobRequest = {
        url,
        format: chosenFormat(),
        height: chosenFormat() === "mp4" ? Number(heightSelect.value) : 0,
        bitrate: Number(bitrateSelect.value),
        mode: modeSelect.value as JobRequest["mode"],
        metadata: need<HTMLInputElement>("#metadata").checked,
        thumbnail: coverCheck.checked,
        sponsorblock: need<HTMLInputElement>("#sponsorblock").checked,
    };

    settled = false;
    button.disabled = true;
    button.textContent = "working";
    actions.innerHTML = "";
    note.textContent = "";
    paint({ stage: "queued", label: "handing it to yt-dlp", percent: 0 });

    try {
        const { id } = await createJob(job);
        watch(id);
    } catch (error) {
        settle();
        say(error instanceof Error ? error.message : "could not start that download", true);
    }
});

let debounce: number | undefined;
urlField.addEventListener("input", () => {
    window.clearTimeout(debounce);
    const url = urlField.value.trim();
    if (!/^https?:\/\/\S+$/.test(url)) {
        metaBox.hidden = true;
        return;
    }
    debounce = window.setTimeout(() => void runProbe(url), 400);
});

for (const radio of document.querySelectorAll<HTMLInputElement>("input[name='format']")) {
    radio.addEventListener("change", syncFormat);
}

document.addEventListener("keydown", (pressed: KeyboardEvent) => {
    if (pressed.key === "Escape") {
        pressed.preventDefault();
        reset();
    }
});

syncFormat();
urlField.focus();
