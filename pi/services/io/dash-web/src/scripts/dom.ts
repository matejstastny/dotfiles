type Attrs = Record<string, string | number | boolean | undefined>;
type Child = Node | string | number | null | undefined | false;

/**
 * h("div.card", { title: "x" }, "text") builds an element from an emmet-ish
 * selector. the whole page is drawn from javascript because every panel
 * depends on data that only exists at runtime, and this keeps that readable
 * without pulling a framework onto a pi.
 */
export function h(selector: string, attrs: Attrs = {}, ...children: Child[]): HTMLElement {
    const [tagAndId, ...classes] = selector.split(".");
    const [tag, id] = tagAndId!.split("#");

    const el = document.createElement(tag || "div");
    if (id) el.id = id;
    if (classes.length) el.className = classes.join(" ");

    for (const [key, value] of Object.entries(attrs)) {
        if (value === undefined || value === false) continue;
        if (key === "style") el.setAttribute("style", String(value));
        else if (key === "text") el.textContent = String(value);
        else el.setAttribute(key, value === true ? "" : String(value));
    }

    append(el, children);
    return el;
}

export function append(parent: Node, children: Child[]): void {
    for (const child of children) {
        if (child === null || child === undefined || child === false) continue;
        parent.appendChild(typeof child === "object" ? child : document.createTextNode(String(child)));
    }
}

const SVG_NS = "http://www.w3.org/2000/svg";

export function svg(tag: string, attrs: Record<string, string | number>): SVGElement {
    const el = document.createElementNS(SVG_NS, tag);
    for (const [key, value] of Object.entries(attrs)) el.setAttribute(key, String(value));
    return el;
}

export function replace(host: Element, ...children: Child[]): void {
    host.replaceChildren();
    append(host, children);
}

export function need<T extends Element>(selector: string): T {
    const found = document.querySelector<T>(selector);
    if (!found) throw new Error(`the page is missing ${selector}`);
    return found;
}
