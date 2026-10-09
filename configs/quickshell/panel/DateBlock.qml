import QtQuick
import "../"

// the date, as the thing the panel opens with. a whole month grid was 264px
// tall to tell you something you already half know, so this is the day itself
// set large, with just the week it sits in underneath for context
Item {
    id: root

    property date now: new Date()

    readonly property var dayNames: ["mo", "tu", "we", "th", "fr", "sa", "su"]

    // monday-first week containing today
    readonly property date weekStart: {
        const d = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate());
        d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
        return d;
    }

    readonly property int cellHeight: 24

    implicitHeight: dayRow.height + Theme.gapLarge + weekdayRow.height + weekGrid.height

    // only while the panel is up, and only often enough to roll over midnight
    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    onVisibleChanged: if (root.visible)
        root.now = new Date()

    Item {
        id: dayRow

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: dayNumber.implicitHeight

        Row {
            id: dayNumber

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Figure {
                text: Qt.formatDateTime(root.now, "MM")
            }
            Figure {
                text: "/"
                separator: true
            }
            Figure {
                text: Qt.formatDateTime(root.now, "dd")
            }
        }

        Column {
            anchors.left: dayNumber.right
            anchors.leftMargin: Theme.gapLarge
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: "✦ " + Qt.formatDateTime(root.now, "dddd").toLowerCase()
                color: Theme.purple
                font.pixelSize: Theme.sizeBody
                font.family: Theme.fontMono
                font.weight: Theme.weightHeading
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: Qt.formatDateTime(root.now, "MMMM yyyy").toLowerCase()
                color: Theme.dim
                font.pixelSize: Theme.sizeLabel
                font.family: Theme.fontMono
                elide: Text.ElideRight
            }
        }
    }

    Row {
        id: weekdayRow

        anchors.top: dayRow.bottom
        anchors.topMargin: Theme.gapLarge
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.sizeMicro + 6

        Repeater {
            model: root.dayNames

            delegate: Text {
                required property string modelData
                width: weekdayRow.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.muted
                font.pixelSize: Theme.sizeMicro
                font.family: Theme.fontMono
            }
        }
    }

    // the separator sits back so the two numbers read as the date and the slash
    // reads as punctuation rather than a third digit
    component Figure: Text {
        property bool separator: false
        color: separator ? Theme.muted : Theme.bright
        font.pixelSize: 40
        font.family: Theme.fontMono
        font.weight: separator ? Theme.weightBody : Theme.weightHeading
    }

    Row {
        id: weekGrid

        anchors.top: weekdayRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.cellHeight

        Repeater {
            model: 7

            delegate: Item {
                id: cell

                required property int index

                readonly property date cellDate: {
                    const d = new Date(root.weekStart.getFullYear(), root.weekStart.getMonth(), root.weekStart.getDate());
                    d.setDate(d.getDate() + cell.index);
                    return d;
                }
                readonly property bool isToday: cellDate.getDate() === root.now.getDate() && cellDate.getMonth() === root.now.getMonth() && cellDate.getFullYear() === root.now.getFullYear()
                readonly property bool thisMonth: cellDate.getMonth() === root.now.getMonth()

                width: weekGrid.width / 7
                height: root.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: root.cellHeight - 2
                    height: width
                    radius: width / 2
                    visible: cell.isToday
                    color: Theme.purple
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.cellDate.getDate()
                    color: cell.isToday ? Theme.bright : (cell.thisMonth ? Theme.text : Theme.muted)
                    font.pixelSize: Theme.sizeLabel
                    font.family: Theme.fontMono
                    font.weight: cell.isToday ? Theme.weightHeading : Theme.weightBody
                }
            }
        }
    }
}
