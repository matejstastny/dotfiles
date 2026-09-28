export interface Filesystem {
    mount: string;
    device: string;
    fstype: string;
    used: number;
    size: number;
    pct: number;
}

export interface HostStats {
    name: string;
    role: string;
    blurb: string;
    glyph: string;
    accent: string;
    accentAlt: string;
    lan: string;
    tailnet: string;
    model: string;
    online: boolean;

    kernel: string;
    arch: string;
    uptimeSec: number;

    cores: number;
    cpuPct: number;
    corePct: number[] | null;
    ioWaitPct: number;
    freqMHz: number;
    governor: string;
    load1: number;
    load5: number;
    load15: number;

    memUsed: number;
    memTotal: number;
    memPct: number;
    memCached: number;
    swapUsed: number;
    swapTotal: number;

    filesystems: Filesystem[] | null;
    diskPct: number;

    diskReadBps: number;
    diskWriteBps: number;

    netDevice: string;
    netRxBps: number;
    netTxBps: number;
    netRxTotal: number;
    netTxTotal: number;
    netErrs: number;

    tempC: number;

    procsRunning: number;
    procsBlocked: number;
    ctxSwitches: number;
    forks: number;
    fdUsed: number;
    fdMax: number;
    conntrack: number;
    driftMs: number;
    oomKills: number;
    scrapeMs: number;

    series: Record<string, number[] | undefined>;
}

export type ServiceState = "up" | "down" | "unprobed";

export interface ServiceStatus {
    name: string;
    host: string;
    blurb: string;
    link: string;
    detail: string;
    state: ServiceState;
    latencyMs: number;
    code: number;
    note: string;
}

export interface NameCount {
    name: string;
    count: number;
}

export interface AdGuardInfo {
    version: string;
    protection: boolean;
    running: boolean;
    uptimeSec: number;
    queries: number;
    blocked: number;
    blockedPct: number;
    safebrowsing: number;
    avgMs: number;
    upstream: string;
    upstreamMs: number;
    addresses: string[] | null;
    perHour: number[] | null;
    blockedHour: number[] | null;
    topQueried: NameCount[] | null;
    topBlocked: NameCount[] | null;
    topClients: NameCount[] | null;
}

export interface Torrent {
    name: string;
    status: string;
    percent: number;
    size: number;
    downBps: number;
    upBps: number;
    ratio: number;
    peers: number;
    etaSec: number;
}

export interface TransmissionInfo {
    torrents: number;
    active: number;
    paused: number;
    downBps: number;
    upBps: number;
    downTotal: number;
    upTotal: number;
    ratio: number;
    activeSec: number;
    list: Torrent[] | null;
}

export interface JellyfinInfo {
    name: string;
    version: string;
    product: string;
    setupOk: boolean;
}

export interface YtdlFile {
    title: string;
    uploader: string;
    format: string;
    quality: string;
    size: number;
    duration: number;
    created: string;
    library: boolean;
}

export interface YtdlInfo {
    cacheUsed: number;
    cacheLimit: number;
    cachePct: number;
    count: number;
    recent: YtdlFile[] | null;
}

export interface ShareFile {
    name: string;
    size: number;
    created: string;
}

export interface ShareInfo {
    count: number;
    limit: number;
    bytes: number;
    recent: ShareFile[] | null;
}

export interface VictoriaInfo {
    series: number;
    labelPairs: number;
    rows: number;
    dataBytes: number;
    freeBytes: number;
    uptimeSec: number;
    version: string;
    retention: string;
}

export interface Integrations {
    adguard: AdGuardInfo | null;
    transmission: TransmissionInfo | null;
    jellyfin: JellyfinInfo | null;
    ytdl: YtdlInfo | null;
    share: ShareInfo | null;
    victoria: VictoriaInfo | null;
}

export interface TailPeer {
    name: string;
    os: string;
    ip: string;
    online: boolean;
    self: boolean;
    exitNode: boolean;
    offersExit: boolean;
    relay: string;
    direct: string;
    routes: string;
    rxBytes: number;
    txBytes: number;
    lastSeen: string;
}

export interface Tailnet {
    backend: string;
    version: string;
    selfIp: string;
    domain: string;
    peers: TailPeer[] | null;
    online: number;
    total: number;
}

export interface FleetSummary {
    hostsUp: number;
    hostsTotal: number;
    servicesUp: number;
    servicesDown: number;
    servicesUnprobed: number;
    servicesTotal: number;
    cores: number;
    cpuPct: number;
    memUsed: number;
    memTotal: number;
    diskUsed: number;
    diskTotal: number;
    netRxBps: number;
    netTxBps: number;
    maxTempC: number;
    hottestHost: string;
    youngestSec: number;
    youngestHost: string;
    warnings: string[] | null;
}

export interface StatsResponse {
    generatedAt: string;
    window: { lookback: string; step: string };
    fleet: FleetSummary;
    hosts: HostStats[] | null;
    services: ServiceStatus[] | null;
    integrations: Integrations;
    tailnet: Tailnet | null;
}

export async function fetchStats(): Promise<StatsResponse> {
    const response = await fetch("/api/stats", { cache: "no-store" });
    if (!response.ok) throw new Error(`the server answered ${response.status}`);
    return (await response.json()) as StatsResponse;
}
