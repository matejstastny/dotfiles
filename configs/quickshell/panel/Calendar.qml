import QtQuick
import "../"

Rectangle {
    id: root

    property date viewDate: new Date()
    readonly property date today: new Date()

    readonly property var monthNames: ["january", "february", "march", "april", "may", "june",
        "july", "august", "september", "october", "november", "december"]
    readonly property var dayNames: ["mo", "tu", "we", "th", "fr", "sa", "su"]

    function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
    function firstWeekday(y, m) { return (new Date(y, m, 1).getDay() + 6) % 7 }
    function shiftMonth(delta) { root.viewDate = new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + delta, 1) }

    implicitHeight: 264
    radius: theme.radius
    color: theme.surface
    border.width: theme.borderWidth
    border.color: theme.muted

    Item {
        id: navRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 18

        Text {
            id: prevBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰅁"
            color: prevArea.containsMouse ? theme.purple : theme.dim
            font.pixelSize: 14
            font.family: theme.fontFamily
            Behavior on color { ColorAnimation { duration: 100 } }
            MouseArea {
                id: prevArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shiftMonth(-1)
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.monthNames[root.viewDate.getMonth()] + " " + root.viewDate.getFullYear()
            color: theme.bright
            font.pixelSize: 13
            font.bold: true
            font.family: theme.fontFamily
            font.weight: Font.Normal
        }

        Text {
            id: nextBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "󰅂"
            color: nextArea.containsMouse ? theme.purple : theme.dim
            font.pixelSize: 14
            font.family: theme.fontFamily
            Behavior on color { ColorAnimation { duration: 100 } }
            MouseArea {
                id: nextArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shiftMonth(1)
            }
        }
    }

    Row {
        id: weekdayRow
        anchors.top: navRow.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        Repeater {
            model: root.dayNames
            delegate: Text {
                required property string modelData
                width: weekdayRow.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: theme.dim
                font.pixelSize: 10
                font.family: theme.fontFamily
            }
        }
    }

    Grid {
        id: daysGrid
        anchors.top: weekdayRow.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        columns: 7

        Repeater {
            model: 42
            delegate: Item {
                id: cell
                required property int index
                readonly property int dayNum: index - root.firstWeekday(root.viewDate.getFullYear(), root.viewDate.getMonth()) + 1
                readonly property int monthLen: root.daysInMonth(root.viewDate.getFullYear(), root.viewDate.getMonth())
                readonly property bool inMonth: dayNum >= 1 && dayNum <= monthLen
                readonly property bool isToday: inMonth
                    && root.viewDate.getFullYear() === root.today.getFullYear()
                    && root.viewDate.getMonth() === root.today.getMonth()
                    && dayNum === root.today.getDate()

                width: daysGrid.width / 7
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    radius: 12
                    visible: cell.isToday
                    color: theme.purple
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.inMonth ? cell.dayNum : ""
                    color: cell.isToday ? theme.bright : theme.text
                    font.pixelSize: 11
                    font.family: theme.fontFamily
                    font.weight: Font.Normal
                }
            }
        }
    }
}
