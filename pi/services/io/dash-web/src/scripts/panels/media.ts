import type { JellyfinInfo, ShareInfo, YtdlInfo } from "../api";
import { bar } from "../charts";
import { h } from "../dom";
import { ago, bytes, duration, ellipsis, pct } from "../format";
import { empty, kv, kvGrid, panel } from "../ui";

export function mediaPanel(
    jellyfin: JellyfinInfo | null,
    ytdl: YtdlInfo | null,
    share: ShareInfo | null,
    accent: string,
): HTMLElement {
    return panel(
        { title: "media & files", span: "span-media", accent },
        h(
            "div.stack",
            {},
            jellyfinBlock(jellyfin),
            ytdlBlock(ytdl),
            shareBlock(share),
        ),
    );
}

function jellyfinBlock(info: JellyfinInfo | null): HTMLElement {
    return h(
        "div.block",
        {},
        blockHead("jellyfin", "https://jellyfin.elara.boo", info ? info.version : ""),
        info
            ? kvGrid(
                  kv("server", info.name),
                  kv("product", info.product),
                  kv("setup", info.setupOk ? "complete" : "wizard pending", !info.setupOk),
              )
            : empty("no answer"),
    );
}

function ytdlBlock(info: YtdlInfo | null): HTMLElement {
    if (!info) {
        return h("div.block", {}, blockHead("ytdl", "https://yt.elara.boo", ""), empty("no answer"));
    }
    const recent = info.recent ?? [];
    return h(
        "div.block",
        {},
        blockHead("ytdl", "https://yt.elara.boo", `${info.count} cached`),
        bar("cache", `${bytes(info.cacheUsed)} / ${bytes(info.cacheLimit)}`, info.cachePct, info.cachePct > 90),
        recent.length === 0
            ? empty("cache is empty")
            : h(
                  "ul.files",
                  {},
                  ...recent.map((file) =>
                      h(
                          "li.file",
                          { title: `${file.title} · ${file.uploader}` },
                          h("span.file-name", { text: ellipsis(file.title, 40) }),
                          h("span.file-meta", {
                              text: `${file.format} ${file.quality} · ${duration(file.duration)} · ${bytes(file.size)}`,
                          }),
                      ),
                  ),
              ),
        h("p.micro-note", { text: `${pct(info.cachePct, 2)} of the 20 GB cache used` }),
    );
}

function shareBlock(info: ShareInfo | null): HTMLElement {
    if (!info) {
        return h("div.block", {}, blockHead("share", "https://share.elara.boo", ""), empty("no answer"));
    }
    const recent = info.recent ?? [];
    return h(
        "div.block",
        {},
        blockHead("share", "https://share.elara.boo", `${info.count}/${info.limit} slots`),
        recent.length === 0
            ? empty("nothing shared right now")
            : h(
                  "ul.files",
                  {},
                  ...recent.map((file) =>
                      h(
                          "li.file",
                          { title: file.name },
                          h("span.file-name", { text: ellipsis(file.name, 40) }),
                          h("span.file-meta", { text: `${bytes(file.size)} · ${ago(file.created)}` }),
                      ),
                  ),
              ),
        h("p.micro-note", { text: `${bytes(info.bytes)} held in the drop` }),
    );
}

function blockHead(title: string, link: string, meta: string): HTMLElement {
    return h(
        "div.block-head",
        {},
        h("a.block-title", { href: link, target: "_blank", rel: "noreferrer", text: title }),
        meta ? h("span.block-meta", { text: meta }) : null,
    );
}
