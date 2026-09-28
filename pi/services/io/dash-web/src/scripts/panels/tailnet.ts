import type { Tailnet } from "../api";
import { h } from "../dom";
import { ago, bytes } from "../format";
import { empty, kv, kvGrid, panel } from "../ui";

export function tailnetPanel(net: Tailnet | null, accent: string): HTMLElement {
    if (!net) {
        return panel({ title: "tailnet", span: "span-tailnet", accent }, empty("tailscale did not answer"));
    }

    const peers = net.peers ?? [];

    return panel(
        { title: "tailnet", meta: `${net.online}/${net.total} online`, span: "span-tailnet", accent },
        h(
            "div.peers",
            {},
            h(
                "div.peer.peer-head",
                {},
                h("span", { text: "" }),
                h("span", { text: "node" }),
                h("span", { text: "os" }),
                h("span", { text: "address" }),
                h("span", { text: "path" }),
                h("span", { text: "traffic" }),
            ),
            ...peers.map(peerRow),
        ),
        kvGrid(
            kv("backend", net.backend, net.backend !== "Running"),
            kv("version", net.version),
            kv("this node", net.selfIp),
            kv("magicdns", net.domain || "—"),
        ),
    );
}

function peerRow(peer: {
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
}): HTMLElement {
    // a direct endpoint means wireguard found a path without bouncing off a
    // derp relay, which is the difference between lan speed and not. for this
    // node there is no path at all, only the derp region it homes to.
    const path = peer.self
        ? peer.relay
            ? `home derp ${peer.relay}`
            : "this node"
        : peer.direct
          ? `direct ${peer.direct}`
          : peer.relay
            ? `derp ${peer.relay}`
            : "—";
    const traffic = peer.rxBytes + peer.txBytes > 0 ? `↓${bytes(peer.rxBytes)} ↑${bytes(peer.txBytes)}` : "—";

    const tags = [
        peer.self && "self",
        peer.exitNode && "exit",
        !peer.exitNode && peer.offersExit && "can exit",
        peer.routes && `routes ${peer.routes}`,
    ].filter(Boolean) as string[];

    return h(
        "div.peer",
        { "data-online": peer.online ? "1" : "0", title: peer.online ? "online" : `last seen ${ago(peer.lastSeen)}` },
        h("span.dot", { "data-state": peer.online ? "up" : "down" }),
        h(
            "span.peer-name",
            {},
            h("b", { text: peer.name }),
            ...tags.map((tag) => h("i.tag", { text: tag })),
        ),
        h("span", { text: peer.os || "—" }),
        h("span.mono", { text: peer.ip }),
        h("span.mono", { text: peer.online ? path : `seen ${ago(peer.lastSeen)}` }),
        h("span.mono", { text: traffic }),
    );
}
