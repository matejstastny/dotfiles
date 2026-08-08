import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    signal unlocked()

    // shared across every screen's LockSurface so they all reflect the same state
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property bool unlocking: false

    readonly property int unlockFadeDuration: 550

    onCurrentTextChanged: showFailure = false

    Timer {
        id: unlockFadeTimer
        interval: root.unlockFadeDuration
        onTriggered: root.unlocked()
    }

    function tryUnlock() {
        if (currentText === "" || unlockInProgress) return
        root.unlockInProgress = true
        if (!pam.start()) {
            root.unlockInProgress = false
            root.showFailure = true
        }
    }

    PamContext {
        id: pam

        // own PAM service installed in the real system pam.d directory (required -
        // "include login" only resolves there, not in a relative/bundled dir),
        // so this doesn't depend on the hyprlock package being installed
        configDirectory: "/etc/pam.d"
        config: "quickshell-lock"

        onPamMessage: {
            if (this.responseRequired) this.respond(root.currentText)
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocking = true
                unlockFadeTimer.start()
            } else {
                root.currentText = ""
                root.showFailure = true
            }
            root.unlockInProgress = false
        }
    }
}
