import { h } from "./dom";

type Child = Node | string | null | false;

export interface PanelOptions {
    title: string;
    /** short right aligned line in the panel header, usually a version or a count */
    meta?: string;
    /** extra classes on the section, used for grid placement */
    span?: string;
    accent?: string;
    link?: string;
}

export function panel({ title, meta, span, accent, link }: PanelOptions, ...body: Child[]): HTMLElement {
    const head = h(
        "header.panel-head",
        {},
        link
            ? h("a.panel-title", { href: link, target: "_blank", rel: "noreferrer", text: title })
            : h("h2.panel-title", { text: title }),
        meta ? h("span.panel-meta", { text: meta }) : null,
    );
    return h(
        `section.panel${span ? `.${span}` : ""}`,
        { style: accent ? `--accent:${accent}` : undefined },
        head,
        h("div.panel-body", {}, ...body),
    );
}

/** a label/value pair, the workhorse of every detail panel */
export function kv(label: string, value: Child, warn = false): HTMLElement {
    return h(
        "div.kv",
        { "data-warn": warn ? "1" : undefined },
        h("span.kv-label", { text: label }),
        typeof value === "string" ? h("span.kv-value", { text: value }) : h("span.kv-value", {}, value),
    );
}

export function kvGrid(...rows: Child[]): HTMLElement {
    return h("div.kv-grid", {}, ...rows);
}

/** a big single number with a caption under it */
export function figure(value: string, label: string, warn = false): HTMLElement {
    return h(
        "div.figure",
        { "data-warn": warn ? "1" : undefined },
        h("span.figure-value", { text: value }),
        h("span.figure-label", { text: label }),
    );
}

export function empty(text: string): HTMLElement {
    return h("p.empty", { text });
}

export function dot(state: "up" | "down" | "unprobed" | "warn"): HTMLElement {
    return h("span.dot", { "data-state": state });
}
