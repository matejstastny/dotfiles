import QtQuick
import Quickshell.Services.UPower
import "../"
import "../common"

Item {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device && device.isLaptopBattery && device.isPresent
    readonly property int pct: present ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: present && device.state === UPowerDeviceState.Charging
    readonly property bool low: pct <= 15 && !charging
    readonly property bool hovered: hoverArea.containsMouse || popoutArea.containsMouse
    readonly property real barBottom: Theme.barHeight - root.y
    property alias popoutItem: popout
    property real popoutProgress: hovered ? 1 : 0

    visible: present
    implicitWidth: visible ? rowContent.implicitWidth + 8 : 0
    implicitHeight: Theme.barModuleHeight

    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string icon: charging ? "󰂄" : icons[Math.min(9, Math.floor(pct / 10))]

    Row {
        id: rowContent
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.icon
            color: root.low ? Theme.rose : (root.hovered ? Theme.bright : Theme.purple)
            font.pixelSize: Theme.barFontSize
            font.family: Theme.fontMono
            font.weight: Font.Bold
        }
        Text {
            text: root.pct.toString().padStart(2, " ") + "%"
            color: root.low ? Theme.rose : Theme.dim
            font.pixelSize: Theme.barFontSize - 1
            font.family: Theme.fontMono
            font.weight: Font.Normal
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }

    MouseArea {
        id: popoutArea
        x: -70
        y: root.barBottom - Theme.blobOverlap
        width: 250
        height: popout.height
        hoverEnabled: true
    }

    Behavior on popoutProgress {
        NumberAnimation {
            duration: Theme.effectsDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.easingEffects
        }
    }

    BlobRect {
        id: popout

        visible: root.popoutProgress > 0.001
        x: -70
        y: root.barBottom - Theme.blobOverlap
        width: 250 * root.popoutProgress
        height: (batteryContent.implicitHeight + 20 + Theme.blobOverlap) * root.popoutProgress
        radius: Theme.radiusSmall
        clip: true

        Column {
            id: batteryContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            anchors.topMargin: Theme.blobOverlap + 10
            spacing: 10
            opacity: root.popoutProgress

            Text {
                text: root.charging ? "charging" : "battery"
                color: Theme.purple
                font.pixelSize: Theme.sizeLabel
                font.family: Theme.fontMono
                font.weight: Theme.weightHeading
            }

            Row {
                spacing: 12

                Text {
                    text: root.pct + "%"
                    color: root.low ? Theme.rose : Theme.bright
                    font.pixelSize: Theme.sizeTitle + 3
                    font.family: Theme.fontMono
                    font.weight: Theme.weightHeading
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.charging
                        ? (root.device.timeToFull > 0 ? root.duration(root.device.timeToFull) + " until full" : "plugged in")
                        : (root.device.timeToEmpty > 0 ? root.duration(root.device.timeToEmpty) + " remaining" : "on battery")
                    color: Theme.dim
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                }
            }

            Text {
                width: parent.width
                text: root.powerText
                color: Theme.text
                font.pixelSize: Theme.sizeLabel
                font.family: Theme.fontMono
            }

            Column {
                width: parent.width
                spacing: 5
                visible: PowerProfiles.hasPerformanceProfile

                Text {
                    text: "power profile"
                    color: Theme.dim
                    font.pixelSize: Theme.sizeMicro
                    font.family: Theme.fontMono
                }

                Row {
                    spacing: 5

                    Repeater {
                        model: [
                            { label: "save", value: PowerProfile.PowerSaver },
                            { label: "balanced", value: PowerProfile.Balanced },
                            { label: "boost", value: PowerProfile.Performance }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool selected: PowerProfiles.profile === modelData.value
                            width: modelData.label === "balanced" ? 74 : 54
                            height: 24
                            radius: Theme.radiusSmall
                            color: selected ? Theme.purple : Theme.overlay
                            border.width: Theme.borderWidth
                            border.color: selected ? Theme.purple : Theme.muted

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.label
                                color: parent.selected ? Theme.base : Theme.text
                                font.pixelSize: Theme.sizeMicro
                                font.family: Theme.fontMono
                                font.weight: Theme.weightMedium
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: PowerProfiles.profile = parent.modelData.value
                            }
                        }
                    }
                }
            }
        }
    }

    function duration(seconds: real): string {
        const total = Math.max(0, Math.round(seconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }

    readonly property string powerText: {
        if (!root.device || Math.abs(root.device.changeRate) < 0.01)
            return "power draw unavailable";
        const watts = Math.abs(root.device.changeRate).toFixed(1);
        return root.charging ? `${watts} W charging` : `${watts} W draw`;
    }
}
