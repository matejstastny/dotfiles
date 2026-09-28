import type { VictoriaInfo } from "../api";
import { bar } from "../charts";
import { h } from "../dom";
import { bytes, count, duration } from "../format";
import { empty, figure, kv, kvGrid, panel } from "../ui";

export function storePanel(info: VictoriaInfo | null, accent: string, window: { lookback: string; step: string }): HTMLElement {
    if (!info) {
        return panel({ title: "metrics store", span: "span-store", accent }, empty("victoria-metrics did not answer"));
    }

    // the numbers are tiny next to a TB of free space, so the bar is drawn
    // against the disk rather than against the data, which is the honest shape
    const total = info.dataBytes + info.freeBytes;
    const usedPct = total > 0 ? (info.dataBytes / total) * 100 : 0;

    return panel(
        { title: "metrics store", meta: info.version, span: "span-store", accent },
        h(
            "div.figures",
            {},
            figure(count(info.series), "series"),
            figure(count(info.rows), "samples"),
            figure(bytes(info.dataBytes), "on disk"),
            figure(info.retention, "retention"),
        ),
        bar("storage", `${bytes(info.dataBytes)} of ${bytes(total)}`, Math.max(usedPct, 0.4)),
        kvGrid(
            kv("label pairs", count(info.labelPairs)),
            kv("free space", bytes(info.freeBytes)),
            kv("uptime", duration(info.uptimeSec)),
            kv("chart window", `${window.lookback} at ${window.step}`),
        ),
        h("p.micro-note", { text: "node-exporter on all three boxes, scraped every 15s over the tailnet" }),
    );
}
