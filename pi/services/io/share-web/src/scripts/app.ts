import { ago, bytes, downloadHref, dropFile, listFiles, need, upload, type FileEntry } from "./api";

const dropzone = need<HTMLLabelElement>("#drop");
const dropText = need<HTMLElement>("#drop-text");
const fileInput = need<HTMLInputElement>("#file");

const statusBox = need<HTMLElement>("#status");
const stageText = need<HTMLElement>("#stage");
const fill = need<HTMLElement>("#fill");
const nums = need<HTMLElement>("#nums");
const note = need<HTMLElement>("#note");

const meter = need<HTMLElement>("#meter-fill");
const usage = need<HTMLElement>("#usage");
const list = need<HTMLUListElement>("#files");
const empty = need<HTMLElement>("#empty");

const DEFAULT_DROP_TEXT = "drop a file here or click to choose";

let busy = false;

function say(message: string, bad = false): void {
    statusBox.hidden = false;
    note.textContent = message;
    note.classList.toggle("bad", bad);
    note.classList.toggle("good", !bad);
}

function paint(fraction: number, label: string): void {
    statusBox.hidden = false;
    stageText.textContent = label;
    fill.style.width = `${(fraction * 100).toFixed(1)}%`;
    nums.textContent = `${(fraction * 100).toFixed(0)}%`;
}

function row(file: FileEntry): HTMLLIElement {
    const item = document.createElement("li");

    const title = document.createElement("span");
    title.className = "file-title";
    title.textContent = file.name;

    const facts = document.createElement("span");
    facts.className = "file-facts";
    for (const text of [bytes(file.size), ago(file.created)]) {
        const tag = document.createElement("span");
        tag.className = "tag";
        tag.textContent = text;
        facts.append(tag);
    }

    const buttons = document.createElement("span");
    buttons.className = "file-actions";

    const copy = document.createElement("button");
    copy.className = "ghost";
    copy.type = "button";
    copy.textContent = "copy link";
    copy.addEventListener("click", async () => {
        const link = `${location.origin}${downloadHref(file)}`;
        await navigator.clipboard.writeText(link).catch(() => undefined);
        copy.textContent = "copied";
        setTimeout(() => (copy.textContent = "copy link"), 1500);
    });
    buttons.append(copy);

    const get = document.createElement("a");
    get.className = "ghost";
    get.href = downloadHref(file);
    get.download = file.name;
    get.textContent = "get";
    buttons.append(get);

    const drop = document.createElement("button");
    drop.className = "ghost danger";
    drop.type = "button";
    drop.textContent = "drop";
    drop.addEventListener("click", async () => {
        drop.disabled = true;
        await dropFile(file.id).catch(() => undefined);
        await refresh();
    });
    buttons.append(drop);

    item.append(title, facts, buttons);
    return item;
}

async function refresh(): Promise<void> {
    const listing = await listFiles().catch(() => null);
    if (!listing) {
        empty.hidden = false;
        empty.textContent = "could not reach the service";
        return;
    }

    const share = listing.limit > 0 ? (listing.files.length / listing.limit) * 100 : 0;
    meter.style.width = `${Math.min(share, 100).toFixed(1)}%`;
    meter.classList.toggle("full", listing.files.length >= listing.limit);
    usage.textContent = `${listing.files.length} of ${listing.limit} kept`;

    list.innerHTML = "";
    for (const file of listing.files) list.append(row(file));
    empty.hidden = listing.files.length > 0;
    empty.textContent = "nothing here yet";
}

async function send(file: File): Promise<void> {
    if (busy) return;
    busy = true;
    dropText.textContent = file.name;
    note.textContent = "";
    paint(0, "uploading");

    try {
        await upload(file, (fraction) => paint(fraction, "uploading"));
        say(`${file.name} is up`);
        await refresh();
    } catch (error) {
        say(error instanceof Error ? error.message : "that upload failed", true);
    } finally {
        busy = false;
        dropText.textContent = DEFAULT_DROP_TEXT;
        fileInput.value = "";
    }
}

fileInput.addEventListener("change", () => {
    const file = fileInput.files?.[0];
    if (file) void send(file);
});

dropzone.addEventListener("dragover", (event) => {
    event.preventDefault();
    dropzone.classList.add("drag");
});
dropzone.addEventListener("dragleave", () => dropzone.classList.remove("drag"));
dropzone.addEventListener("drop", (event) => {
    event.preventDefault();
    dropzone.classList.remove("drag");
    const file = event.dataTransfer?.files?.[0];
    if (file) void send(file);
});

void refresh();
