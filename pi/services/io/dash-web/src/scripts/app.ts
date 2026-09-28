import { fetchStats, type StatsResponse } from "./api";
import { h, need, replace } from "./dom";
import { clock, day, duration } from "./format";
import { adguardPanel } from "./panels/adguard";
import { hostCards } from "./panels/hosts";
import { mediaPanel } from "./panels/media";
import { servicesPanel } from "./panels/services";
import { storePanel } from "./panels/store";
import { tailnetPanel } from "./panels/tailnet";
import { fleetStrip, warningsBar } from "./panels/topbar";
import { transmissionPanel } from "./panels/transmission";

const POLL_MS = 5_000;
const CLOCK_MS = 1_000;
const STALE_AFTER_MS = 90_000;

const fleetHost = need<HTMLElement>("#fleet");
const warningHost = need<HTMLElement>("#warnings");
const gridHost = need<HTMLElement>("#grid");
const clockHost = need<HTMLElement>("#clock");
const dayHost = need<HTMLElement>("#day");
const pulseHost = need<HTMLElement>("#pulse");
const pulseNote = need<HTMLElement>("#pulse-note");

let lastGenerated = "";
let lastFetchOk = 0;
let lastData: StatsResponse | null = null;

function render(data: StatsResponse): void {
    const hosts = data.hosts ?? [];
    const services = data.services ?? [];

    // every host has its own accent; the shared panels borrow the accent of
    // whichever box actually runs the thing they describe
    const accentOf = (name: string) => hosts.find((host) => host.name === name)?.accent ?? "#9b6bc9";

    // adguard reports its clients by ip, and most of them are tailnet nodes
    // tailscale can name for us
    const tailnetNames = new Map(
        (data.tailnet?.peers ?? []).filter((peer) => peer.ip).map((peer) => [peer.ip, peer.name]),
    );

    replace(fleetHost, fleetStrip(data.fleet));
    replace(warningHost, warningsBar(data.fleet.warnings));

    replace(
        gridHost,
        h("div.hosts-wrap", {}, hostCards(hosts)),
        servicesPanel(services, hosts),
        adguardPanel(data.integrations.adguard, accentOf("thebe"), tailnetNames),
        transmissionPanel(data.integrations.transmission, accentOf("io")),
        mediaPanel(
            data.integrations.jellyfin,
            data.integrations.ytdl,
            data.integrations.share,
            accentOf("io"),
        ),
        tailnetPanel(data.tailnet, accentOf("leda")),
        storePanel(data.integrations.victoria, accentOf("io"), data.window),
    );
}

function tickClock(): void {
    const now = new Date();
    clockHost.textContent = clock(now);
    dayHost.textContent = day(now);

    if (lastFetchOk === 0) {
        pulseNote.textContent = "connecting";
        pulseHost.dataset.state = "cold";
        return;
    }

    const since = Date.now() - lastFetchOk;
    const generated = lastData ? Date.now() - Date.parse(lastData.generatedAt) : 0;
    pulseHost.dataset.state = since > STALE_AFTER_MS ? "stale" : "live";
    pulseNote.textContent =
        since > STALE_AFTER_MS
            ? `no answer for ${duration(since / 1000)}`
            : `metrics ${duration(Math.max(generated, 0) / 1000)} old`;
}

async function refresh(): Promise<void> {
    const data = await fetchStats().catch(() => null);
    if (!data) return;

    lastFetchOk = Date.now();
    lastData = data;

    // the server only recomputes on its own schedule, so redrawing when the
    // payload has not moved would just throw away the dom for nothing
    if (data.generatedAt === lastGenerated) return;
    lastGenerated = data.generatedAt;
    render(data);
}

tickClock();
setInterval(tickClock, CLOCK_MS);

void refresh();
setInterval(() => void refresh(), POLL_MS);

// a dashboard left open on a second screen stops polling when the tab is
// hidden; catch it up the moment it comes back rather than up to five seconds
// later
document.addEventListener("visibilitychange", () => {
    if (!document.hidden) void refresh();
});
