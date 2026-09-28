import type { AdGuardInfo, NameCount } from "../api";
import { columns, ranked } from "../charts";
import { h } from "../dom";
import { count, duration, ms, pct } from "../format";
import { empty, figure, kv, kvGrid, panel } from "../ui";

export function adguardPanel(
    info: AdGuardInfo | null,
    accent: string,
    tailnetNames: Map<string, string>,
): HTMLElement {
    if (!info) {
        return panel(
            { title: "adguard home", span: "span-adguard", accent },
            empty("no answer from the resolver api"),
        );
    }

    const hours = info.perHour ?? [];
    const blockedHours = info.blockedHour ?? [];

    return panel(
        { title: "adguard home", meta: info.version, span: "span-adguard", accent, link: "https://dns.elara.boo" },
        h(
            "div.figures",
            {},
            figure(count(info.queries), "queries 24h"),
            figure(count(info.blocked), "blocked"),
            figure(pct(info.blockedPct, 1), "block rate"),
            figure(ms(info.avgMs), "avg answer"),
        ),
        h(
            "div.histogram",
            {},
            h(
                "div.trace-head",
                {},
                h("span.micro-label", { text: "queries per hour" }),
                h("span.trace-now", { text: `peak ${count(Math.max(0, ...hours))}` }),
            ),
            columns(hours, { title: (v, i) => `${hoursAgo(hours.length, i)}: ${count(v)} queries` }),
            h(
                "div.trace-head",
                {},
                h("span.micro-label", { text: "blocked per hour" }),
                h("span.trace-now", { text: `peak ${count(Math.max(0, ...blockedHours))}` }),
            ),
            h("div.columns-blocked", {}, columns(blockedHours, { title: (v, i) => `${hoursAgo(blockedHours.length, i)}: ${count(v)} blocked` })),
        ),
        h(
            "div.tops",
            {},
            topList("most asked", info.topQueried),
            topList("most blocked", info.topBlocked),
            topList("busiest clients", named(info.topClients, tailnetNames)),
        ),
        kvGrid(
            kv("protection", info.protection ? "on" : "off", !info.protection),
            kv("upstream", shortUpstream(info.upstream)),
            kv("upstream rtt", ms(info.upstreamMs)),
            kv("uptime", duration(info.uptimeSec)),
            kv("safe browsing", count(info.safebrowsing)),
            kv("listening", (info.addresses ?? []).slice(0, 2).join(" · ") || "—"),
        ),
    );
}

/**
 * adguard only knows its clients by address, but the busiest ones are all
 * tailnet nodes, and tailscale already told us their names. relabel what we
 * can and leave the rest as the raw address.
 */
function named(rows: NameCount[] | null, tailnetNames: Map<string, string>): NameCount[] | null {
    if (!rows) return rows;
    return rows.map((row) => {
        const name = tailnetNames.get(row.name);
        return name ? { name: `${name} · ${row.name}`, count: row.count } : row;
    });
}

function topList(title: string, rows: NameCount[] | null): HTMLElement {
    return h(
        "div.top",
        {},
        h("span.micro-label", { text: title }),
        rows && rows.length > 0 ? ranked(rows.slice(0, 6), count) : empty("nothing yet"),
    );
}

function hoursAgo(total: number, index: number): string {
    const back = total - 1 - index;
    return back === 0 ? "this hour" : `${back}h ago`;
}

/** https://dns10.quad9.net:443/dns-query -> dns10.quad9.net */
function shortUpstream(url: string): string {
    if (!url) return "—";
    try {
        return new URL(url).hostname;
    } catch {
        return url;
    }
}
