pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Polkit as Polkit
import "../"
import "../common"

Scope {
    id: root

    readonly property var flow: agent.flow
    readonly property var identities: root.flow ? root.flow.identities : []
    readonly property bool active: agent.isActive
    property string promptScreenName: ""
    property bool failedAttempt: false
    property int failureSerial: 0

    signal authenticationRequested

    function chooseScreen(): void {
        const focusedName = Hyprland.focusedMonitor?.name ?? "";
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === focusedName) {
                root.promptScreenName = focusedName;
                return;
            }
        }
        root.promptScreenName = Quickshell.screens[0]?.name ?? "";
    }

    function identityLabel(identity: var): string {
        if (!identity)
            return "your account";
        const name = identity.string || "";
        const displayName = identity.displayName || name;
        return displayName !== name && name.length > 0 ? `${displayName}  ·  ${name}` : displayName;
    }

    function promptText(): string {
        const prompt = root.flow?.inputPrompt?.trim() ?? "";
        return prompt.length > 0 ? prompt.replace(/:\s*$/, "") : "Password";
    }

    function submit(value: string): void {
        if (!root.flow?.isResponseRequired)
            return;
        root.failedAttempt = false;
        root.flow.submit(value);
    }

    function cancel(): void {
        if (root.flow)
            root.flow.cancelAuthenticationRequest();
    }

    onActiveChanged: if (!root.active)
        root.failedAttempt = false

    Polkit.PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.chooseScreen();
            root.failedAttempt = false;
            root.authenticationRequested();
        }
    }

    Connections {
        target: root.flow

        function onAuthenticationFailed(): void {
            root.failedAttempt = true;
            root.failureSerial++;
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property var modelData
            readonly property bool isTarget: modelData.name === root.promptScreenName

            PanelWindow {
                id: overlay

                property bool revealed: false

                screen: screenScope.modelData
                visible: root.active
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                focusable: screenScope.isTarget

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:polkit"
                WlrLayershell.keyboardFocus: screenScope.isTarget ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                onVisibleChanged: {
                    overlay.revealed = false;
                    if (overlay.visible)
                        Qt.callLater(() => overlay.revealed = true);
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.76)
                    opacity: overlay.revealed ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.effectsDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.easingEffects
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                }

                FocusScope {
                    id: keyboardScope

                    anchors.fill: parent
                    focus: screenScope.isTarget && root.active
                    Keys.onEscapePressed: root.cancel()

                    Item {
                        id: card

                        anchors.centerIn: parent
                        width: Math.min(560, parent.width - Theme.paddingLarge * 2)
                        height: cardContent.implicitHeight + Theme.paddingLarge * 2
                        visible: screenScope.isTarget
                        opacity: overlay.revealed ? 1 : 0
                        scale: overlay.revealed ? 1 : 0.96
                        transform: Translate {
                            id: cardShift
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.effectsDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.easingEffects
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.spatialDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.easingSpatial
                            }
                        }

                        SequentialAnimation {
                            id: failureShake

                            NumberAnimation { target: cardShift; property: "x"; to: -9; duration: 45; easing.type: Easing.OutCubic }
                            NumberAnimation { target: cardShift; property: "x"; to: 7; duration: 60; easing.type: Easing.InOutCubic }
                            NumberAnimation { target: cardShift; property: "x"; to: -4; duration: 55; easing.type: Easing.InOutCubic }
                            NumberAnimation { target: cardShift; property: "x"; to: 0; duration: 70; easing.type: Easing.OutCubic }
                        }

                        Connections {
                            target: root

                            function onFailureSerialChanged(): void {
                                if (screenScope.isTarget)
                                    failureShake.restart();
                            }
                        }

                        SquircleRect {
                            x: 8
                            y: 8
                            width: parent.width
                            height: parent.height
                            radius: Theme.radiusActive
                            color: Qt.rgba(0, 0, 0, 0.28)
                        }

                        SquircleRect {
                            anchors.fill: parent
                            radius: Theme.radiusActive
                            color: Theme.surface
                            borderWidth: Theme.borderWidth
                            borderColor: root.failedAttempt ? Theme.rose : Theme.muted
                        }

                        Rectangle {
                            width: Theme.markerWidth
                            height: parent.height - Theme.paddingLarge * 2
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.padding
                            anchors.verticalCenter: parent.verticalCenter
                            radius: width / 2
                            color: root.failedAttempt ? Theme.rose : Theme.purple

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.effectsDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.easingEffects
                                }
                            }
                        }

                        Column {
                            id: cardContent

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: Theme.paddingLarge
                            anchors.leftMargin: Theme.paddingLarge + Theme.gap
                            spacing: Theme.gapLarge

                            Row {
                                width: parent.width
                                height: 54
                                spacing: Theme.gapLarge

                                Item {
                                    width: 54
                                    height: 54

                                    SquircleRect {
                                        anchors.fill: parent
                                        radius: Theme.radiusActive
                                        color: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.16)
                                        borderWidth: Theme.borderWidth
                                        borderColor: Theme.purple
                                    }

                                    Image {
                                        id: actionIcon

                                        anchors.fill: parent
                                        anchors.margins: 13
                                        source: root.flow?.iconName ? Quickshell.iconPath(root.flow.iconName, true) : ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !actionIcon.visible
                                        text: "󰌾"
                                        color: Theme.purple
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.iconLarge
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        anchors.rightMargin: -2
                                        anchors.bottomMargin: -4
                                        text: "✦"
                                        color: root.failedAttempt ? Theme.rose : Theme.bright
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.iconSmall
                                    }
                                }

                                Column {
                                    width: parent.width - 54 - parent.spacing
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: "Authentication required"
                                        color: Theme.bright
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.sizeTitle
                                        font.weight: Theme.weightHeading
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: `as ${root.identityLabel(root.flow?.selectedIdentity)}`
                                        color: Theme.dim
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.sizeLabel
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: root.flow?.message || "A privileged action needs your approval."
                                textFormat: Text.PlainText
                                color: Theme.text
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.sizeBody
                                lineHeight: 1.25
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                width: parent.width
                                visible: text.length > 0
                                text: root.flow?.actionId || ""
                                textFormat: Text.PlainText
                                color: Theme.dim
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.sizeMicro
                                elide: Text.ElideMiddle
                            }

                            Column {
                                width: parent.width
                                visible: root.identities.length > 1
                                spacing: Theme.gapSmall

                                Text {
                                    text: "authenticate as"
                                    color: Theme.dim
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.sizeMicro
                                }

                                Flow {
                                    width: parent.width
                                    spacing: Theme.gapSmall

                                    Repeater {
                                        model: root.identities

                                        delegate: AuthButton {
                                            required property var modelData

                                            label: root.identityLabel(modelData)
                                            selected: root.flow?.selectedIdentity === modelData
                                            onClicked: root.flow.selectedIdentity = modelData
                                        }
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: statusText.visible ? statusText.implicitHeight : 0
                                visible: height > 0

                                Text {
                                    id: statusText

                                    width: parent.width
                                    visible: text.length > 0
                                    text: {
                                        if (root.failedAttempt)
                                            return "✦ Authentication failed, try again";
                                        return root.flow?.supplementaryMessage || "";
                                    }
                                    textFormat: Text.PlainText
                                    color: root.failedAttempt || root.flow?.supplementaryIsError ? Theme.rose : Theme.dim
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.sizeLabel
                                    wrapMode: Text.WordWrap
                                }
                            }

                            FocusScope {
                                id: credentialField

                                width: parent.width
                                height: 44

                                SquircleRect {
                                    anchors.fill: parent
                                    radius: credentialInput.activeFocus ? Theme.radiusActive : Theme.radiusRest
                                    color: Theme.overlay
                                    borderWidth: Theme.borderWidth
                                    borderColor: root.failedAttempt || root.flow?.supplementaryIsError ? Theme.rose : (credentialInput.activeFocus ? Theme.purple : Theme.muted)
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.gapLarge
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.flow?.responseVisible ? "󰦝" : "󰌾"
                                    color: root.flow?.isResponseRequired ? Theme.purple : Theme.dim
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.iconBody
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 42
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.gapLarge
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: credentialInput.text.length === 0
                                    text: root.flow?.isResponseRequired ? root.promptText() : "checking credentials…"
                                    color: Theme.dim
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.sizeBody
                                    elide: Text.ElideRight
                                }

                                TextInput {
                                    id: credentialInput

                                    anchors.left: parent.left
                                    anchors.leftMargin: 42
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.gapLarge
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: parent.height
                                    enabled: root.flow?.isResponseRequired ?? false
                                    focus: true
                                    activeFocusOnTab: enabled
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.bright
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.sizeInput
                                    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                                    selectByMouse: true
                                    selectionColor: Qt.rgba(Theme.purple.r, Theme.purple.g, Theme.purple.b, 0.45)
                                    clip: true

                                    onTextChanged: if (text.length > 0)
                                        root.failedAttempt = false
                                    onAccepted: {
                                        root.submit(text);
                                        text = "";
                                    }

                                    Keys.onEscapePressed: root.cancel()
                                }

                            }

                            Item {
                                width: parent.width
                                height: 38

                                Row {
                                    anchors.right: parent.right
                                    spacing: Theme.gap

                                    AuthButton {
                                        label: "Cancel"
                                        danger: true
                                        onClicked: root.cancel()
                                    }

                                    AuthButton {
                                        label: root.flow?.isResponseRequired ? "Authenticate" : "Checking…"
                                        primary: true
                                        enabled: root.flow?.isResponseRequired ?? false
                                        onClicked: {
                                            root.submit(credentialInput.text);
                                            credentialInput.text = "";
                                        }
                                    }
                                }
                            }
                        }

                        Connections {
                            target: root.flow

                            function onIsResponseRequiredChanged(): void {
                                credentialInput.text = "";
                                if (screenScope.isTarget && root.flow?.isResponseRequired)
                                    Qt.callLater(() => credentialInput.forceActiveFocus());
                            }
                        }

                        Connections {
                            target: overlay

                            function onRevealedChanged(): void {
                                if (overlay.revealed && screenScope.isTarget && root.flow?.isResponseRequired)
                                    Qt.callLater(() => credentialInput.forceActiveFocus());
                            }
                        }
                    }
                }

                ShortcutInhibitor {
                    window: overlay
                    enabled: overlay.visible && screenScope.isTarget
                }
            }
        }
    }
}
