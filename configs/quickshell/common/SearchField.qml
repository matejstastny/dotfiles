import QtQuick
import "../"

Item {
    id: root

    property alias text: input.text
    property string placeholder: "search..."
    property bool password: false
    property int fontSize: 13

    signal accepted()
    signal upPressed()
    signal downPressed()
    signal escapePressed()
    signal altBackspace()
    signal altD()

    readonly property Theme theme: Theme {}

    implicitHeight: 40

    function focusInput() { input.forceActiveFocus() }
    function clear() { input.text = "" }

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusSmall
        color: theme.surface
        border.width: theme.borderWidth
        border.color: input.activeFocus ? theme.purple : theme.muted
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    Text {
        visible: input.text.length === 0
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.placeholder
        color: theme.dim
        font.pixelSize: root.fontSize
        font.family: theme.fontFamily
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: theme.text
        font.pixelSize: root.fontSize
        font.family: theme.fontFamily
        selectByMouse: true
        clip: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal

        onAccepted: root.accepted()

        Keys.onUpPressed: root.upPressed()
        Keys.onDownPressed: root.downPressed()
        Keys.onEscapePressed: root.escapePressed()
        Keys.onPressed: event => {
            if (event.modifiers & Qt.AltModifier) {
                if (event.key === Qt.Key_Backspace) {
                    root.altBackspace()
                    event.accepted = true
                } else if (event.key === Qt.Key_D) {
                    root.altD()
                    event.accepted = true
                }
            }
        }
    }
}
