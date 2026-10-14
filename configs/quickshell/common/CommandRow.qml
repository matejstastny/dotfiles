import QtQuick
import "../"

// one row, everywhere. the shell used to have five of these - five row
// heights, five gutters, three different ways of showing which one you were on
// - and that is most of why a picker never felt like the launcher.
//
// nothing here paints a selection background. the marker that says where you
// are lives in CommandList's gutter and glides, so arrowing down a list does
// not repaint a block of colour per keypress
Item {
    id: root

    property bool current: false

    // three ways to mark a row, in priority order: a picture (a cursor theme's
    // preview), a colour chip (a hex code sitting in the clipboard), or a glyph.
    // all three land in the same column so the labels stay on one x
    property string icon: ""
    property url iconImage: ""
    property color swatch: "transparent"

    readonly property bool hasImage: String(root.iconImage).length > 0
    readonly property bool hasSwatch: root.swatch.a > 0

    // StyledText, so CommandList can hand it a fuzzy-highlighted label. plain
    // text has to be escaped by whoever sets it
    property string label: ""
    property string subtitle: ""

    // a subtitle that is only there to explain the row you are on fades out on
    // every other row - the launcher's trick, and the reason a long result list
    // stays quiet. a subtitle carrying live state (a wifi network's "connected")
    // sets this false and stays put
    property bool quietSubtitle: true

    // set by CommandList: the width reserved for the icon column, 0 when no row
    // in the list has an icon. rows keep their text on the same x either way
    property int iconColumn: 0

    property color accent: Theme.purple
    property bool highlighted: false
    property bool strong: false

    // trailing content (a status pill, a hover-revealed button) goes here and
    // the label elides against it
    default property alias trailing: trailingArea.data
    property int trailingWidth: 0

    implicitHeight: Theme.rowHeight

    Item {
        id: iconSlot

        visible: root.iconColumn > 0
        anchors.left: parent.left
        anchors.leftMargin: Theme.rowGutter
        anchors.verticalCenter: parent.verticalCenter
        width: root.iconColumn
        height: parent.height

        Image {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasImage
            width: Math.min(parent.width - 6, parent.height - 6)
            height: width
            source: root.iconImage
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            cache: true
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            opacity: root.current ? 1 : 0.75

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.snapDuration
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.hasImage && root.hasSwatch
            width: Theme.iconSmall
            height: Theme.iconSmall
            radius: 4
            color: root.swatch
            border.width: Theme.borderWidth
            border.color: Qt.rgba(1, 1, 1, 0.18)
        }

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.hasImage && !root.hasSwatch && root.icon.length > 0
            text: root.icon
            color: root.highlighted || root.current ? root.accent : Theme.dim
            font.pixelSize: Theme.iconSmall
            font.family: Theme.fontMono

            Behavior on color {
                ColorAnimation {
                    duration: Theme.snapDuration
                }
            }
        }
    }

    Text {
        id: subtitleText

        visible: root.subtitle.length > 0
        anchors.right: trailingArea.left
        anchors.rightMargin: root.trailingWidth > 0 ? Theme.gap : 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.subtitle
        color: root.highlighted ? root.accent : Theme.muted
        font.pixelSize: Theme.sizeMicro
        font.family: Theme.fontMono
        elide: Text.ElideRight

        opacity: root.quietSubtitle ? (root.current ? 1 : 0) : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.snapDuration
            }
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Theme.rowGutter + root.iconColumn
        anchors.right: subtitleText.visible ? subtitleText.left : trailingArea.left
        anchors.rightMargin: Theme.gapLarge
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.StyledText
        text: root.label
        color: root.highlighted ? root.accent : (root.current ? Theme.bright : Theme.dim)
        font.pixelSize: Theme.sizeBody
        font.family: Theme.fontMono
        font.weight: root.strong || root.highlighted ? Theme.weightHeading : Theme.weightBody
        elide: Text.ElideRight

        Behavior on color {
            ColorAnimation {
                duration: Theme.snapDuration
            }
        }
    }

    Item {
        id: trailingArea

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.trailingWidth
        height: parent.height
    }
}
