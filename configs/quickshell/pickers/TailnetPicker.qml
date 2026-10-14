import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../common"

// the `tls` fzf script, as a drawer, plus an off row the script never had.
// `switch --list` knows which profile is selected but not whether the tunnel is
// actually up, so the state comes from two calls and the rows wait on both: a
// stopped tailscaled still has a selected profile, and showing that as active
// would make the off row a lie
CommandPicker {
    id: root

    popoutName: "tailnet"
    placeholder: "tailnet"
    emptyText: "no tailscale profiles"
    mode: "list"

    // which tailnet is live is state, not an explanation of the current row
    quietSubtitles: false

    property var profiles: []
    property string backendState: ""
    readonly property bool connected: root.backendState === "Running"

    // the step list of the action in flight, and the label its notice shows
    property var queue: []
    property string pending: ""
    property string failure: ""

    notice: root.failure.length > 0 ? root.failure : (root.pending.length > 0 ? `󰒍 ${root.pending}…` : "")

    rows: {
        const out = [];
        for (const profile of root.profiles) {
            const selected = profile.selected === true;
            const live = selected && root.connected;
            out.push({
                key: profile.id,
                label: profile.nickname || profile.account,
                subtitle: live ? `active · ${profile.tailnet}` : (selected ? `last used · ${profile.tailnet}` : profile.tailnet),
                icon: live ? "󰒍" : "󰒎",
                highlighted: live,
                keywords: `${profile.account} ${profile.tailnet}`,
                selected,
                live
            });
        }
        // last, so the cursor never starts on it and so hitting enter straight
        // after an off reconnects rather than toggling back and forth
        out.push({
            key: "off",
            label: "off",
            subtitle: root.connected ? "disconnect" : "active",
            icon: "󰅖",
            highlighted: !root.connected,
            keywords: "down disconnect",
            off: true
        });
        return out;
    }

    function refresh(): void {
        lister.running = true;
        statusCheck.running = true;
    }

    function start(label: string, steps: var): void {
        root.failure = "";
        root.pending = label;
        root.queue = steps;
        root.step();
    }

    function step(): void {
        if (root.queue.length === 0) {
            root.pending = "";
            root.closeRequested();
            return;
        }
        runner.command = root.queue[0];
        root.queue = root.queue.slice(1);
        runner.running = true;
    }

    Process {
        id: lister
        command: ["tailscale", "switch", "--list", "--json"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.profiles = JSON.parse(text);
                } catch (e) {
                    root.profiles = [];
                    root.failure = "tailscaled is not reachable";
                }
            }
        }
    }

    Process {
        id: statusCheck
        command: ["tailscale", "status", "--json"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.backendState = JSON.parse(text).BackendState ?? "";
                } catch (e) {
                    root.backendState = "";
                }
            }
        }
    }

    Process {
        id: runner

        stderr: StdioCollector {
            id: runnerError
        }

        onExited: code => {
            if (code === 0) {
                root.step();
                return;
            }
            const label = root.pending;
            root.pending = "";
            root.queue = [];
            // the useful line is the last one: `up` leads with its own progress
            // chatter before whatever actually went wrong
            const reason = runnerError.text.trim().split("\n").pop();
            root.failure = reason.length > 0 ? reason : `could not finish ${label}`;
            root.refresh();
        }
    }

    onOpenChanged: {
        if (!root.open)
            return;
        root.queue = [];
        root.pending = "";
        root.failure = "";
        root.refresh();
    }

    onSelected: item => {
        if (root.pending.length > 0)
            return;

        if (item.off) {
            if (!root.connected) {
                root.closeRequested();
                return;
            }
            root.start("disconnecting", [["tailscale", "down"]]);
            return;
        }

        // picking the tailnet already up means "yes, that one" - there is
        // nothing to switch, so the drawer has done its job
        if (item.live) {
            root.closeRequested();
            return;
        }

        // `switch` only selects a profile, it does not start a stopped
        // tailscaled - so coming back from an off always needs the `up` too.
        // without a timeout `up` blocks forever on a profile whose auth has
        // expired, which would leave the drawer stuck behind its notice
        const up = ["tailscale", "up", "--timeout=15s"];
        root.start(`switching to ${item.label}`, item.selected ? [up] : [["tailscale", "switch", item.key], up]);
    }
}
