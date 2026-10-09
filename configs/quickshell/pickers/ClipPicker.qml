import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

CommandPicker {
    id: root

    popoutName: "clip"
    placeholder: "clipboard"
    emptyText: "clipboard is empty"

    // what a clip *is* is the most useful thing on the row, and it is state
    // rather than an explanation of the row the cursor happens to be on
    quietSubtitles: false

    property var clips: []

    readonly property var imagePattern: /^\[\[ binary data (.+?) ([a-z]+) (\d+)x(\d+) \]\]$/i
    readonly property var colorPattern: /^#(?:[0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i
    readonly property var urlPattern: /^(?:https?|ftp|magnet|ssh):\/\/\S+$/i
    readonly property var pathPattern: /^(?:~|\/|\.\/)[^\s]*$/

    // a clipboard is never one kind of thing. telling a colour from a url from
    // a wall of yaml at a glance is most of what makes the list usable
    function classify(preview: string): var {
        const image = root.imagePattern.exec(preview);
        if (image)
            return {
                label: "image",
                subtitle: image[3] + " × " + image[4] + "  " + image[1].trim(),
                icon: "▧",
                accent: Theme.rose,
                highlighted: true
            };

        // cliphist hands back one already-flattened line per record, truncated
        // at about a hundred characters - so there is no line count to report
        // and no honest length to quote. plain text gets no subtitle at all and
        // the row elides, which says "there is more" without inventing a number
        const trimmed = preview.trim();
        const oneLine = trimmed.replace(/\s+/g, " ");

        if (root.colorPattern.test(trimmed))
            return {
                label: trimmed.toLowerCase(),
                subtitle: "colour",
                swatch: trimmed,
                accent: Theme.rose
            };

        if (root.urlPattern.test(trimmed))
            return {
                label: oneLine,
                subtitle: "link",
                icon: "󰖟",
                accent: Theme.purple,
                highlighted: true
            };

        if (root.pathPattern.test(trimmed) && trimmed.length < 200)
            return {
                label: oneLine,
                subtitle: "path",
                icon: "󰉋"
            };

        return {
            label: oneLine,
            subtitle: "",
            icon: "▤"
        };
    }

    Process {
        id: lister
        // cliphist prints one record per line, so a multi-line clip arrives as
        // its own preview already collapsed by cliphist itself
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    const tab = line.indexOf("\t");
                    const preview = tab >= 0 ? line.slice(tab + 1) : line;
                    const row = root.classify(preview);
                    row.key = line;
                    out.push(row);
                }
                root.clips = out;
            }
        }
    }

    rows: root.clips

    actions: [
        {
            key: "delete",
            code: Qt.Key_Backspace,
            hint: "alt+backspace  forget this clip"
        }
    ]

    onOpenChanged: if (root.open)
        lister.running = true

    onSelected: (item, action) => {
        if (action === "delete") {
            // cliphist delete reads the record off stdin, same format as list
            deleter.command = ["bash", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "_", item.key];
            deleter.running = true;
            return;
        }
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "_", item.key]);
        root.closeRequested();
    }

    Process {
        id: deleter
        onExited: lister.running = true
    }
}
