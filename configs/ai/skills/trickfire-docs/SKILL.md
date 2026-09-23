---
name: trickfire-docs
description: Write and polish documentation for TrickFire Robotics' docs framework (trickfire-docs, fumadocs/MDX-based). Use whenever creating or editing .mdx/.md files under a docs/ folder next to a docs.config.json, running `trickfire-docs`/`npx trickfire-docs init`, or the user asks to write/improve TrickFire docs, add callouts, tabs, steps, or accordions to a docs page.
---

# TrickFire Docs authoring

You are writing content for **trickfire-docs**, TrickFire Robotics' internal documentation
framework (Next.js + fumadocs). Member project repos each have their own `docs/` folder and
`docs.config.json`, and get aggregated into `docs.trickfirerobotics.com`. These content repos do
**not** have `fumadocs-ui` installed, so never write `import ... from "fumadocs-ui/..."` in an
MDX file — `Callout`, `Tabs`/`Tab`, `Steps`/`Step`, and `Accordions`/`Accordion` are injected
globally and used bare, with no import statement.

If you have local access to the framework's own repo (the one with `src/components/mdx.tsx`),
its `docs/writing-content.mdx` and `docs/configuration.mdx` are the live source of truth — prefer
them over this skill if they ever disagree, since the framework can evolve after this was written.

## Detecting this applies

A repo is a trickfire-docs content repo if it has `docs.config.json` at its root and a `docs/`
folder of `.mdx`/`.md` files. If neither exists yet and the user wants to start docs, the setup
flow is `npx trickfire-docs init` (scaffolds `docs/getting-started.mdx`, `docs.config.json`, and
a `.github/workflows/docs.yml`), then `npx trickfire-docs dev` to preview locally.

## Frontmatter

Every page can start with YAML frontmatter:

```mdx
---
title: My Page Title
description: A short summary shown in search results.
---
```

`title` defaults to the first H1 if omitted. Always write a `description` — it shows in search
results and under the page title, and a missing one is the single most common "why does this
page look unfinished" gap.

## Headings

One H1 per page (usually implicit via `title`, or write `# Title` if the page needs it inline).
Use `##` for top-level sections, `###` for subsections. Don't skip levels, and don't go past
`###` on a docs page — if you need a fourth level, the page is probably trying to cover too much
and should split, or the content belongs in an `Accordion` instead of a heading.

## Links

Internal links use relative paths **including the `.mdx` extension** — the resolver matches on
file path, not URL slug:

```mdx
[Getting Started](./getting-started.mdx)
[See the FAQ](./reference/faq.mdx)
```

External links are plain markdown links: `[GitHub](https://github.com/TrickfireRobotics)`.

## Images

Place images in `docs/assets/` and reference relatively: `![Wiring diagram](./assets/wiring.png)`.
SVGs work the same way.

To constrain size, wrap the markdown image in the global `Image` component (also no import) -
it centers by default:

```mdx
<Image width="50%">![Wiring diagram](./assets/wiring.png)</Image>
```

`width` accepts any CSS width (`"50%"`, `"300px"`) or a bare number treated as pixels; `center`
defaults to `true` (`center={false}` left-aligns). Always pass the image as markdown syntax
inside `<Image>`, never as an `src` prop directly on it - only the markdown form goes through the
`remark-image` pipeline that resolves the file path and optimizes it, so an `src` prop would
silently point at the wrong (or a broken) URL once content is aggregated into the docs site.

## Code blocks

Fenced blocks with a language tag get syntax highlighting (`python`, `typescript`, `bash`,
`yaml`, `json`, `c`, `cpp`, and most common languages).

Show a filename with `title`:

````mdx
```python title="examples/send_message.py"
...
```
````

Highlight specific lines with a trailing `# [!code highlight]` comment on that line — use this to
draw the eye to the one or two lines that matter in a longer snippet, not the whole block:

````mdx
```python
import can

bus = can.Bus(...)
msg = can.Message(...) # [!code highlight]
bus.send(msg) # [!code highlight]
```
````

## Tables

```mdx
| Column A | Column B | Column C |
| -------- | -------- | -------- |
| Row 1    | Value    | Value    |
```

Alignment: `:---` left, `:---:` center, `---:` right. Reach for a table for structured,
scannable comparisons (fields, flags, options) — not as a substitute for prose paragraphs.

## Callouts (admonitions)

`Callout` is global, no import. Five types, each with a distinct icon and accent color:

```mdx
<Callout type="info" title="Note">
    Extra context that's useful but not critical.
</Callout>

<Callout type="idea" title="Tip">
    A recommended shortcut or best practice.
</Callout>

<Callout type="warning" title="Warning">
    Something that can break things if ignored.
</Callout>

<Callout type="error" title="Danger">
    Do not do this - data loss or hardware damage possible.
</Callout>

<Callout type="success" title="Result">
    The expected good outcome once you've done the preceding steps.
</Callout>
```

`title` is optional — omit it for a short inline aside, include it when the callout needs to be
spottable while skimming. `warn` and `tip` are accepted as aliases for `warning`/`info`, but
prefer the canonical names for clarity.

**Choosing a type** (this is the part that's easy to get wrong — pick by *stakes and intent*,
not by keyword-matching the sentence):

- `info` — neutral context the reader benefits from but can skip. Background, clarifications, "note that X."
- `idea` — a shortcut, best practice, or optional optimization. Skippable, upside-only.
- `warning` — a footgun. Following the happy path without reading this risks breaking something (a bad build, a bricked config, wasted time).
- `error` — real, hard-to-reverse damage: data loss, hardware damage, destroying work. Reserve this for genuine danger — overusing `error` for ordinary warnings trains readers to ignore it.
- `success` — confirms an expected good outcome, usually the last step of a procedure ("you should now see X").

**Don't overuse callouts.** They work by interrupting the reading flow to demand attention — a
page with five callouts in a row has zero effective callouts, because nothing stands out anymore.
If more than ~1 callout appears per 2–3 screens of content, most of them should be regular prose,
a table, or folded into an `Accordion` instead. Never use a callout as a substitute for structuring
the explanation properly first.

## Tabs

For presenting the *same step* with alternatives that depend on the reader's environment (OS,
package manager, language) — not for unrelated content that happens to be adjacent:

```mdx
<Tabs items={["Linux", "macOS"]}>
    <Tab value="Linux">Install with apt: `sudo apt install can-utils`</Tab>
    <Tab value="macOS">Install with brew: `brew install can-utils`</Tab>
</Tabs>
```

Also global, no import. Keep tab labels short and parallel (`Linux` / `macOS`, not `Linux` /
`On a Mac you should`). If there's only one path most readers take, don't manufacture tabs to
look fancy — a single code block reads better than a one-tab `Tabs`.

## Steps

For a sequential procedure where order matters and each step is a discrete action:

```mdx
<Steps>
    <Step>Install the CAN utilities: `sudo apt install can-utils`.</Step>
    <Step>Bring the interface up: `sudo ip link set can0 up type can bitrate 500000`.</Step>
    <Step>Verify it's listening: `candump can0`.</Step>
</Steps>
```

Also global. Use `Steps` for "do this, then this, then this" setup/install flows. Don't use it
for a loosely-ordered list of options — that's a bullet list — and don't nest heavy content (long
code blocks, tables) inside every step; if a step needs that much explanation, consider giving it
its own `##` heading with the step as prose lead-in instead.

## Accordions (toggle sections)

For content that shouldn't all be visible at once — FAQs, troubleshooting entries, optional
detail a skimming reader doesn't need:

```mdx
<Accordions>
    <Accordion title="candump shows no traffic">
        Check the interface is up (`ip link show can0`) and the bitrate matches the bus.
    </Accordion>
    <Accordion title="Bus errors under load">
        Usually a termination resistor problem - verify both ends of the bus are terminated at 120Ω.
    </Accordion>
</Accordions>
```

Also global. Only one item is open at a time by default; add `multiple` to `Accordions` to allow
several open at once (use this for reference-style FAQs where readers may want two open side by
side; leave it off for troubleshooting flows where one answer at a time is clearer). Never put a
step readers *must* see (a prerequisite, a required config) inside an accordion — collapsed
content is, by design, content some readers will never open.

## File organization & sidebar

Without a `sidebar` in `docs.config.json`, pages are listed alphabetically by filename, folder
and file names title-cased. That's fine for a handful of pages. For anything bigger, define
`sidebar` explicitly for controlled ordering, custom labels, and grouping:

```json
{
    "$schema": "https://docs.trickfirerobotics.com/docs.config.schema.json",
    "name": "TrickFire CAN",
    "description": "CAN bus driver and protocol library for TrickFire robots.",
    "sidebar": [
        { "label": "Getting Started", "slug": "getting-started" },
        {
            "label": "Reference",
            "icon": "BookOpen",
            "items": [
                { "label": "API", "slug": "reference/api" },
                { "label": "FAQ", "slug": "reference/faq" }
            ]
        }
    ]
}
```

- Doc link: `{ "label": ..., "slug": "path/relative/to/docs/without/.mdx" }`
- External link: `{ "label": ..., "link": "https://..." }`
- Group: `{ "label": ..., "icon"?: "<lucide-react icon name>", "items": [...] }` — items must live
  in a matching subfolder (a `"Guides"` group's items live under `docs/guides/`). Groups render
  flat and always-expanded, not as a collapsible accordion, so don't over-nest — one level of
  grouping is usually enough.

`meta.json` files are generated from this config automatically on `dev`/`build`; don't hand-edit
them.

## Putting it together: what makes a page look good

1. **Lead with an H1-level description, not a callout.** The first paragraph should say what the
   page covers and who it's for, in plain prose — save callouts for asides, not the intro.
2. **Structure before you decorate.** Get the heading hierarchy and paragraph flow right first.
   Add `Callout`/`Tabs`/`Steps`/`Accordions` afterward, only where they solve a real reading
   problem (this alternative is environment-dependent → `Tabs`; this is a strict sequence →
   `Steps`; this needs to interrupt the reader → `Callout`; this is optional/skippable →
   `Accordion`).
3. **Match component to intent, not vibes.** A component chosen because it "looks nice" but
   doesn't fit the content's actual shape (e.g. `Tabs` for two things that aren't really
   alternatives, `Steps` for options that aren't sequential) reads as noise, not polish.
4. **Vary the page rhythm.** A page that's all prose is dense; a page that's all components feels
   fragmented and try-hard. Real signal: prose for explanation, a table for structured facts, a
   code block for exact syntax, a `Callout` for the one thing that must not be missed, `Steps` for
   the one procedure, `Accordions` for the long tail of edge cases.
5. **Write a `description` in frontmatter and keep code blocks runnable** (real commands/paths,
   not placeholders like `<your-thing>` unless genuinely user-specific) — these are the details
   that separate a docs page that feels finished from one that feels drafted.
