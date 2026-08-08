import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

PopupWindow {
    id: root
    popoutName: "calc"
    title: "calc"
    popupWidth: 420
    popupHeight: 172

    property string resultText: ""
    property bool hasError: false

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

    SearchField {
        id: input
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        placeholder: "2 + 2 * sqrt(4)..."
        fontSize: 14

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
            if (root.resultText.length > 0 && !root.hasError) {
                Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", root.resultText])
                root.closeRequested()
            }
        }
    }

    Text {
        anchors.top: input.bottom
        anchors.topMargin: 18
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        verticalAlignment: Text.AlignTop
        text: root.resultText.length > 0 ? root.resultText : " "
        color: root.hasError ? theme.rose : theme.bright
        font.pixelSize: 19
        font.bold: true
        font.family: theme.fontFamily
        elide: Text.ElideRight
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
            }
        }
    }

    onOpenChanged: {
        if (open) {
            input.clear()
            root.resultText = ""
            root.hasError = false
            input.focusInput()
        }
    }
}
