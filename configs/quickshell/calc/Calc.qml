import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "calc"
    title: "calc"
    popupWidth: 440
    popupHeight: 208

    property string resultText: ""
    property bool hasError: false
    property bool pendingCopy: false

    readonly property string evalScript: `
import sys, math
expr = sys.argv[1]
ns = {k: getattr(math, k) for k in dir(math) if not k.startswith('_')}
ns['__builtins__'] = {}
try:
    r = eval(expr, ns)
    if isinstance(r, float) and r == int(r) and abs(r) < 1e15:
        print(int(r))
    else:
        print(r)
except Exception as e:
    print('? ' + str(e))
`

    function tryCopy() {
        if (root.resultText.length > 0 && !root.hasError) {
            Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy --type text/plain", "_", root.resultText])
            root.closeRequested()
        }
    }

    SearchField {
        id: input
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        placeholder: ""
        fontSize: 16

        onTextChanged: {
            if (text.trim().length === 0) {
                root.resultText = ""
                root.hasError = false
            } else {
                debounce.restart()
            }
        }
        onEscapePressed: root.closeRequested()
        onAccepted: {
            if (input.text.trim().length === 0) return
            if (!debounce.running && !evalProc.running) {
                root.tryCopy()
                return
            }
            // eval is still pending or in flight - copy once it lands instead of
            // copying stale text. killing an in-flight process here would fire its
            // onStreamFinished with empty output and consume this flag early.
            root.pendingCopy = true
            if (debounce.running) {
                debounce.stop()
                evalProc.running = true
            }
        }
    }

    Item {
        id: resultArea
        anchors.top: input.bottom
        anchors.topMargin: 22
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footer.top
        anchors.bottomMargin: 10

        Text {
            id: equalsGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.resultText.length > 0
            text: root.hasError ? "⚠" : "="
            color: root.hasError ? theme.rose : theme.dim
            font.pixelSize: 16
            font.family: theme.fontFamily
        }

        Text {
            id: resultLabel
            anchors.left: equalsGlyph.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.hasError ? "invalid" : root.resultText
            color: root.hasError ? theme.rose : theme.bright
            font.pixelSize: 26
            font.bold: true
            font.family: theme.fontFamily
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 14

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "esc  close"
            color: theme.dim
            font.pixelSize: 10
            font.family: theme.fontFamily
            opacity: 0.55
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "⏎  copy"
            color: theme.dim
            font.pixelSize: 10
            font.family: theme.fontFamily
            opacity: (root.resultText.length > 0 && !root.hasError) ? 0.7 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: evalProc.running = true
    }

    Process {
        id: evalProc
        command: ["python3", "-c", root.evalScript, input.text]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim()
                if (out.startsWith("?")) {
                    root.hasError = true
                    root.resultText = "invalid expression"
                } else {
                    root.hasError = false
                    root.resultText = out
                }
                if (root.pendingCopy) {
                    root.pendingCopy = false
                    root.tryCopy()
                }
            }
        }
    }

    onOpenChanged: {
        if (open) {
            input.clear()
            root.resultText = ""
            root.hasError = false
            root.pendingCopy = false
            input.focusInput()
        }
    }
}
