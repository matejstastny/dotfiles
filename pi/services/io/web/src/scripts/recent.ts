import { ago, bytes, downloadHref, dropFile, listFiles, need, type FileEntry } from "./api";

const list = need<HTMLUListElement>("#files");
const empty = need<HTMLElement>("#empty");
const meter = need<HTMLElement>("#meter-fill");
const usage = need<HTMLElement>("#usage");

function row(file: FileEntry): HTMLLIElement {
    const item = document.createElement("li");

    const title = document.createElement("span");
    title.className = "file-title";
    title.textContent = file.title || file.name;

    const facts = document.createElement("span");
    facts.className = "file-facts";
    const where = [file.cached ? "cache" : "", file.library ? "library" : ""].filter(Boolean).join(" + ");
    for (const text of [file.format, file.quality ?? "", bytes(file.size), ago(file.created), where]) {
        if (!text) continue;
        const tag = document.createElement("span");
        tag.className = "tag";
        tag.textContent = text;
        facts.append(tag);
    }
    if (file.uploader) {
        const by = document.createElement("span");
        by.textContent = file.uploader;
        facts.append(by);
    }

    const buttons = document.createElement("span");
    buttons.className = "file-actions";

    const get = document.createElement("a");
    get.className = "ghost";
    get.href = downloadHref(file.id);
    get.download = file.name;
    get.textContent = "get";
    buttons.append(get);

    const drop = document.createElement("button");
    drop.className = "ghost danger";
    drop.type = "button";
    drop.textContent = "drop";
    drop.title = file.library
        ? "remove the cached copy, the library copy on io stays"
        : "remove this file from the cache";
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

    const share = listing.cache.limit > 0 ? (listing.cache.used / listing.cache.limit) * 100 : 0;
    meter.style.width = `${Math.min(share, 100).toFixed(1)}%`;
    meter.classList.toggle("full", share > 90);
    usage.textContent = `${bytes(listing.cache.used)} of ${bytes(listing.cache.limit)} · ${listing.files.length} file${listing.files.length === 1 ? "" : "s"}`;

    list.innerHTML = "";
    for (const file of listing.files) list.append(row(file));
    empty.hidden = listing.files.length > 0;
    empty.textContent = "nothing here yet";
}

void refresh();
