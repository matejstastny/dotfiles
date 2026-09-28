import type { HostStats, ServiceStatus } from "../api";
import { h } from "../dom";
import { ms } from "../format";
import { empty, panel } from "../ui";

export function servicesPanel(services: ServiceStatus[], hosts: HostStats[]): HTMLElement {
    const accents = new Map(hosts.map((host) => [host.name, host.accent]));
    const glyphs = new Map(hosts.map((host) => [host.name, host.glyph]));

    const up = services.filter((s) => s.state === "up").length;
    const probed = services.filter((s) => s.state !== "unprobed").length;

    // grouped by host so the column reads like the fleet does, rather than as
    // one long alphabetical list
    const groups = hosts
        .map((host) => ({ host, items: services.filter((s) => s.host === host.name) }))
        .filter((group) => group.items.length > 0);

    const orphans = services.filter((s) => !accents.has(s.host));
    if (orphans.length > 0) {
        groups.push({ host: { name: "elsewhere", accent: "", glyph: "·" } as HostStats, items: orphans });
    }

    return panel(
        { title: "services", meta: `${up}/${probed} answering`, span: "span-services" },
        groups.length === 0
            ? empty("nothing in the catalog")
            : h(
                  "div.service-groups",
                  {},
                  ...groups.map((group) =>
                      h(
                          "div.service-group",
                          { style: group.host.accent ? `--accent:${group.host.accent}` : undefined },
                          h(
                              "div.service-group-head",
                              {},
                              h("span.host-glyph", { text: glyphs.get(group.host.name) ?? "·" }),
                              h("span", { text: group.host.name }),
                          ),
                          h("div.service-list", {}, ...group.items.map(serviceRow)),
                      ),
                  ),
              ),
    );
}

function serviceRow(service: ServiceStatus): HTMLElement {
    const detail =
        service.state === "down"
            ? service.note || "no answer"
            : service.state === "unprobed"
              ? "no probe"
              : ms(service.latencyMs);

    const body = [
        h("span.dot", { "data-state": service.state }),
        h("span.service-name", { text: service.name }),
        h("span.service-detail", { text: detail }),
    ];

    const attrs = { title: `${service.blurb}${service.code ? ` · http ${service.code}` : ""}` };

    return service.link
        ? h("a.service", { ...attrs, href: service.link, target: "_blank", rel: "noreferrer" }, ...body)
        : h("div.service", attrs, ...body);
}
