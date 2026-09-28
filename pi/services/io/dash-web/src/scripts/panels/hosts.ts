import type { HostStats } from "../api";
import { bar, columns, gauge, sparkline } from "../charts";
import { h } from "../dom";
import { bytes, duration, ms, pct, rate } from "../format";
import { kv, kvGrid } from "../ui";

const WARN_TEMP = 70;
const WARN_MEM = 85;
const WARN_DISK = 85;
const WARN_CPU = 90;

export function hostCards(hosts: HostStats[]): HTMLElement {
    return h("div.host-grid", {}, ...hosts.map(hostCard));
}

function hostCard(host: HostStats): HTMLElement {
    const style = `--accent:${host.accent}; --accent-alt:${host.accentAlt}`;

    if (!host.online) {
        return h(
            "article.host.host-offline",
            { style },
            header(host),
            h("p.empty", { text: "no metrics in the last scrape window" }),
        );
    }

    return h(
        "article.host",
        { style },
        header(host),
        h(
            "div.gauges",
            {},
            gauge({
                label: "cpu",
                value: pct(host.cpuPct),
                fill: host.cpuPct,
                warn: host.cpuPct > WARN_CPU,
                sub: `${host.cores} cores`,
            }),
            gauge({
                label: "memory",
                value: pct(host.memPct),
                fill: host.memPct,
                warn: host.memPct > WARN_MEM,
                sub: `${bytes(host.memUsed)}/${bytes(host.memTotal)}`,
            }),
            gauge({
                label: "disk",
                value: pct(host.diskPct),
                fill: host.diskPct,
                warn: host.diskPct > WARN_DISK,
                sub: rootSub(host),
            }),
            gauge({
                label: "temp",
                value: `${host.tempC.toFixed(0)}°`,
                // the pi throttles at 80, so the ring reads against that
                fill: (host.tempC / 80) * 100,
                warn: host.tempC > WARN_TEMP,
                sub: `${host.freqMHz.toFixed(0)} MHz`,
            }),
        ),

        h(
            "div.cores",
            {},
            h("span.micro-label", { text: "cores" }),
            columns(host.corePct ?? [], {
                max: 100,
                warnAt: WARN_CPU,
                title: (v, i) => `cpu${i} ${v.toFixed(1)}%`,
            }),
            h("span.micro-note", { text: host.governor }),
        ),

        h(
            "div.traces",
            {},
            trace("cpu", host.series.cpu, pct(host.cpuPct, 1)),
            trace("temp", host.series.temp, `${host.tempC.toFixed(1)}°`),
            trace("net in", host.series.netRx, rate(host.netRxBps)),
            trace("net out", host.series.netTx, rate(host.netTxBps)),
        ),

        h("div.fs", {}, ...(host.filesystems ?? []).map(fsBar)),

        kvGrid(
            kv("load", `${host.load1.toFixed(2)} ${host.load5.toFixed(2)} ${host.load15.toFixed(2)}`),
            kv("uptime", duration(host.uptimeSec)),
            kv("disk io", `↓${rate(host.diskReadBps)} ↑${rate(host.diskWriteBps)}`),
            kv("net total", `↓${bytes(host.netRxTotal)} ↑${bytes(host.netTxTotal)}`),
            kv("procs", `${host.procsRunning.toFixed(0)} run · ${host.procsBlocked.toFixed(0)} blocked`, host.procsBlocked > 0),
            kv("ctx switch", `${Math.round(host.ctxSwitches).toLocaleString("en-US")}/s`),
            kv("file desc", `${Math.round(host.fdUsed).toLocaleString("en-US")} open`),
            kv("conntrack", Math.round(host.conntrack).toLocaleString("en-US")),
            kv("swap", host.swapTotal > 0 ? `${bytes(host.swapUsed)}/${bytes(host.swapTotal)}` : "none"),
            kv("io wait", pct(host.ioWaitPct, 2), host.ioWaitPct > 10),
            kv("clock drift", ms(host.driftMs), Math.abs(host.driftMs) > 200),
            kv("scrape", ms(host.scrapeMs), host.scrapeMs > 1000),
            kv("net errors", Math.round(host.netErrs).toLocaleString("en-US"), host.netErrs > 0),
            kv("oom kills", Math.round(host.oomKills).toLocaleString("en-US"), host.oomKills > 0),
        ),
    );
}

function header(host: HostStats): HTMLElement {
    return h(
        "header.host-head",
        {},
        h(
            "div.host-title",
            {},
            h("span.host-glyph", { text: host.glyph }),
            h("h2.host-name", { text: host.name }),
            h("span.host-role", { text: host.role }),
            h("span.host-state", { "data-online": host.online ? "1" : "0" }),
        ),
        h("p.host-blurb", { text: host.blurb }),
        h(
            "div.host-facts",
            {},
            fact("tailnet", host.tailnet || "—"),
            fact("lan", host.lan || "—"),
            fact("iface", host.netDevice || "—"),
            fact("kernel", host.kernel || "—"),
            fact("board", `${host.model} · ${host.arch}`),
        ),
    );
}

function fact(label: string, value: string): HTMLElement {
    return h("span.fact", { title: `${label}: ${value}` }, h("i", { text: label }), h("b", { text: value }));
}

function rootSub(host: HostStats): string {
    const root = (host.filesystems ?? []).find((fs) => fs.mount === "/");
    return root ? `${bytes(root.used)}/${bytes(root.size)}` : "—";
}

function fsBar(fs: { mount: string; used: number; size: number; pct: number; fstype: string }): HTMLElement {
    return bar(
        `${fs.mount} · ${fs.fstype}`,
        `${bytes(fs.used)} / ${bytes(fs.size)}`,
        fs.pct,
        fs.pct > WARN_DISK,
    );
}

function trace(label: string, values: number[] | undefined, now: string): HTMLElement {
    return h(
        "div.trace",
        {},
        h("div.trace-head", {}, h("span.micro-label", { text: label }), h("span.trace-now", { text: now })),
        sparkline(values),
    );
}
