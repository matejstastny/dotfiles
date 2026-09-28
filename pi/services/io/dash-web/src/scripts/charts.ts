import { h, svg } from "./dom";

const RADIUS = 16;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

export interface GaugeOptions {
    label: string;
    value: string;
    /** 0-100, drives how much of the ring is drawn */
    fill: number;
    warn?: boolean;
    sub?: string;
}

/** a ring gauge. the track is always a full circle so an empty one still reads as a dial. */
export function gauge({ label, value, fill, warn, sub }: GaugeOptions): HTMLElement {
    const drawn = Math.max(0, Math.min(100, fill)) / 100;

    const ring = svg("svg", { class: "gauge-ring", viewBox: "0 0 40 40" });
    ring.append(
        svg("circle", { class: "gauge-track", cx: 20, cy: 20, r: RADIUS }),
        svg("circle", {
            class: "gauge-fill",
            cx: 20,
            cy: 20,
            r: RADIUS,
            "stroke-dasharray": `${(drawn * CIRCUMFERENCE).toFixed(2)} ${CIRCUMFERENCE.toFixed(2)}`,
        }),
    );

    return h(
        "div.gauge",
        { "data-warn": warn ? "1" : undefined },
        h("div.gauge-dial", {}, ring, h("span.gauge-value", { text: value })),
        h("span.gauge-label", { text: label }),
        sub ? h("span.gauge-sub", { text: sub }) : null,
    );
}

/**
 * a filled sparkline. values are scaled to their own min/max rather than to an
 * absolute range, because the shape over the window is the point, not the
 * altitude, which the gauge next to it already shows.
 */
export function sparkline(values: number[] | undefined, extra = ""): SVGElement {
    const chart = svg("svg", {
        class: `spark ${extra}`.trim(),
        viewBox: "0 0 100 30",
        preserveAspectRatio: "none",
    });
    if (!values || values.length < 2) return chart;

    const min = Math.min(...values);
    const max = Math.max(...values);
    const range = max - min || 1;
    const x = (i: number) => (i / (values.length - 1)) * 100;
    const y = (v: number) => 28 - ((v - min) / range) * 26;

    const line = values.map((v, i) => `${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(" ");

    chart.append(
        svg("polygon", { class: "spark-area", points: `0,30 ${line} 100,30` }),
        svg("polyline", { class: "spark-line", points: line }),
        svg("circle", { class: "spark-head", cx: 100, cy: y(values[values.length - 1]!), r: 1.6 }),
    );
    return chart;
}

/** a labelled horizontal bar, used for filesystems and caches */
export function bar(label: string, right: string, fill: number, warn = false): HTMLElement {
    return h(
        "div.bar",
        { "data-warn": warn ? "1" : undefined },
        h("div.bar-head", {}, h("span.bar-label", { text: label }), h("span.bar-right", { text: right })),
        h(
            "div.bar-track",
            {},
            h("div.bar-fill", { style: `width:${Math.max(0, Math.min(100, fill)).toFixed(1)}%` }),
        ),
    );
}

/**
 * a row of vertical bars: cpu cores, or adguard's 24 hour query histogram.
 * each bar sits in its own track so an idle core still reads as an empty
 * slot rather than disappearing into a hairline.
 */
export function columns(
    values: number[],
    options: { max?: number; warnAt?: number; title?: (v: number, i: number) => string } = {},
): HTMLElement {
    const ceiling = options.max ?? Math.max(1, ...values);
    return h(
        "div.columns",
        {},
        ...values.map((v, i) =>
            h(
                "span.column",
                {
                    "data-warn": options.warnAt !== undefined && v >= options.warnAt ? "1" : undefined,
                    title: options.title ? options.title(v, i) : `${v}`,
                },
                h("i.column-fill", { style: `height:${Math.max(3, (v / ceiling) * 100).toFixed(1)}%` }),
            ),
        ),
    );
}

/** a ranked list with a bar behind each row, for adguard's top-N tables */
export function ranked(rows: { name: string; count: number }[], render: (value: number) => string): HTMLElement {
    const max = Math.max(1, ...rows.map((r) => r.count));
    return h(
        "ul.ranked",
        {},
        ...rows.map((row) =>
            h(
                "li.ranked-row",
                { title: row.name },
                h("span.ranked-track", { style: `width:${((row.count / max) * 100).toFixed(1)}%` }),
                h("span.ranked-name", { text: row.name }),
                h("span.ranked-count", { text: render(row.count) }),
            ),
        ),
    );
}
