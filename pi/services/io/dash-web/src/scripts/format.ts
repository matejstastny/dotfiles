const KIB = 1024;
const UNITS = ["B", "K", "M", "G", "T", "P"];

/** 1536 -> "1.5K". keeps three significant-ish digits so columns stay narrow. */
export function bytes(value: number): string {
    if (!isFinite(value) || value <= 0) return "0B";
    let n = value;
    let unit = 0;
    while (n >= KIB && unit < UNITS.length - 1) {
        n /= KIB;
        unit += 1;
    }
    const digits = n >= 100 || unit === 0 ? 0 : n >= 10 ? 1 : 2;
    return `${n.toFixed(digits)}${UNITS[unit]}`;
}

export function rate(value: number): string {
    return `${bytes(value)}/s`;
}

/** 10963 -> "3h 2m". the two coarsest units are all a glance needs. */
export function duration(seconds: number): string {
    if (!isFinite(seconds) || seconds <= 0) return "—";
    const d = Math.floor(seconds / 86400);
    const h = Math.floor((seconds % 86400) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    if (d > 0) return `${d}d ${h}h`;
    if (h > 0) return `${h}h ${m}m`;
    if (m > 0) return `${m}m ${s}s`;
    return `${s}s`;
}

export function pct(value: number, digits = 0): string {
    if (!isFinite(value)) return "—";
    return `${value.toFixed(digits)}%`;
}

export function count(value: number): string {
    if (!isFinite(value)) return "—";
    if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
    if (value >= 10_000) return `${(value / 1000).toFixed(1)}k`;
    return Math.round(value).toLocaleString("en-US");
}

export function ms(value: number): string {
    if (!isFinite(value)) return "—";
    if (Math.abs(value) >= 1000) return `${(value / 1000).toFixed(2)}s`;
    if (Math.abs(value) >= 10) return `${value.toFixed(0)}ms`;
    return `${value.toFixed(1)}ms`;
}

export function ago(iso: string): string {
    const then = Date.parse(iso);
    if (!isFinite(then)) return "—";
    return `${duration((Date.now() - then) / 1000)} ago`;
}

export function clock(date: Date): string {
    return date.toLocaleTimeString("en-GB", { hour12: false });
}

export function day(date: Date): string {
    return date
        .toLocaleDateString("en-GB", { weekday: "short", day: "2-digit", month: "short" })
        .toLowerCase();
}

/** trims a long torrent or domain name from the middle, keeping both ends readable */
export function ellipsis(text: string, max: number): string {
    if (text.length <= max) return text;
    const head = Math.ceil((max - 1) * 0.6);
    const tail = max - 1 - head;
    return `${text.slice(0, head)}…${text.slice(text.length - tail)}`;
}
