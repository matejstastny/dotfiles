import QtQuick
import "../"

Text {
    readonly property Theme theme: Theme {}
    text: "✧"
    color: theme.muted
    font.pixelSize: theme.barFontSize - 1
    font.family: theme.fontFamily
    font.weight: Font.Normal
    verticalAlignment: Text.AlignVCenter
}
