import QtQuick

Text {
    readonly property Theme theme: Theme {}
    text: "✧"
    color: theme.muted
    font.pixelSize: 12
    font.family: theme.fontFamily
    verticalAlignment: Text.AlignVCenter
}
