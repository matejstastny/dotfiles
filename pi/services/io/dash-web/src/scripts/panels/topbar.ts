import type { FleetSummary } from "../api";
import { h } from "../dom";
import { bytes, duration, pct, rate } from "../format";

export function fleetStrip(fleet: FleetSummary): HTMLElement {
    const chips: HTMLElement[] = [
        chip("hosts", `${fleet.hostsUp}/${fleet.hostsTotal}`, fleet.hostsUp < fleet.hostsTotal),
        chip(
            "services",
            `${fleet.servicesUp}/${fleet.servicesUp + fleet.servicesDown}`,
            fleet.servicesDown > 0,
        ),
        chip("cpu", `${pct(fleet.cpuPct, 1)} of ${fleet.cores} cores`),
        chip("memory", `${bytes(fleet.memUsed)} / ${bytes(fleet.memTotal)}`),
        chip("disk", `${bytes(fleet.diskUsed)} / ${bytes(fleet.diskTotal)}`),
        chip("network", `↓${rate(fleet.netRxBps)} ↑${rate(fleet.netTxBps)}`),
        chip("hottest", `${fleet.maxTempC.toFixed(1)}° ${fleet.hottestHost}`, fleet.maxTempC > 70),
        chip("newest boot", `${duration(fleet.youngestSec)} · ${fleet.youngestHost}`),
    ];
    return h("div.fleet", {}, ...chips);
}

function chip(label: string, value: string, warn = false): HTMLElement {
    return h(
        "div.chip",
        { "data-warn": warn ? "1" : undefined },
        h("span.chip-label", { text: label }),
        h("span.chip-value", { text: value }),
    );
}

export function warningsBar(warnings: string[] | null): HTMLElement | null {
    if (!warnings || warnings.length === 0) return null;
    return h(
        "div.warnings",
        {},
        h("span.warnings-mark", { text: "!" }),
        h("span", { text: warnings.join(" · ") }),
    );
}
