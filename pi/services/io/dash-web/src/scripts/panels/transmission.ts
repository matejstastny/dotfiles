import type { TransmissionInfo } from "../api";
import { bar } from "../charts";
import { h } from "../dom";
import { bytes, duration, ellipsis, rate } from "../format";
import { empty, figure, kv, kvGrid, panel } from "../ui";

export function transmissionPanel(info: TransmissionInfo | null, accent: string): HTMLElement {
    if (!info) {
        return panel({ title: "transmission", span: "span-transmission", accent }, empty("no answer from the rpc"));
    }

    const list = info.list ?? [];

    return panel(
        {
            title: "transmission",
            meta: `${info.torrents} torrent${info.torrents === 1 ? "" : "s"}`,
            span: "span-transmission",
            accent,
            link: "https://torrent.elara.boo",
        },
        h(
            "div.figures",
            {},
            figure(rate(info.downBps), "down"),
            figure(rate(info.upBps), "up"),
            figure(info.ratio.toFixed(2), "all time ratio"),
            figure(String(info.active), "active"),
        ),
        list.length === 0
            ? empty("no torrents loaded")
            : h("div.torrents", {}, ...list.map(torrentRow)),
        kvGrid(
            kv("downloaded", bytes(info.downTotal)),
            kv("uploaded", bytes(info.upTotal)),
            kv("paused", String(info.paused)),
            kv("time active", duration(info.activeSec)),
        ),
    );
}

function torrentRow(t: {
    name: string;
    status: string;
    percent: number;
    size: number;
    downBps: number;
    upBps: number;
    peers: number;
    etaSec: number;
}): HTMLElement {
    // transmission uses a negative eta for "not downloading" and for "unknown"
    const eta = t.etaSec > 0 ? duration(t.etaSec) : t.percent >= 100 ? "complete" : "—";
    const right =
        t.downBps + t.upBps > 0
            ? `↓${rate(t.downBps)} ↑${rate(t.upBps)}`
            : `${bytes(t.size)} · ${t.status}`;

    return h(
        "div.torrent",
        { title: t.name },
        bar(ellipsis(t.name, 44), right, t.percent, false),
        h(
            "div.torrent-meta",
            {},
            h("span", { text: `${t.percent.toFixed(1)}%` }),
            h("span", { text: `${t.peers} peers` }),
            h("span", { text: eta }),
        ),
    );
}
