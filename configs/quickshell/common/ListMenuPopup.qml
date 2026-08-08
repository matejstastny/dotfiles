import QtQuick
import "../"

Item {
    id: root

    property string mode: "list" // "list" | "freeText" | "listOrFreeText"
    property ListModel items: ListModel {}
    property string emptyText: "nothing here ✧"
    property string placeholder: "search..."
    property Component rowDelegate: null

    property string secondaryActionKey: ""
    property string secondaryActionHint: ""
    property string tertiaryActionKey: ""
    property string tertiaryActionHint: ""

    property bool active: false

    signal selected(var item, string action)
    signal freeTextSubmitted(string text, string action)
    signal closeRequested()

    readonly property Theme theme: Theme {}
    property var filteredRows: []

    function refilter() {
        const query = searchField.text.toLowerCase()
        const rows = []
        for (let i = 0; i < items.count; i++) {
            const it = items.get(i)
            const hay = ((it.label || "") + " " + (it.subtitle || "") + " " + (it.keywords || "")).toLowerCase()
            if (query.length === 0 || hay.includes(query)) rows.push(it)
        }
        root.filteredRows = rows
        list.currentIndex = rows.length > 0 ? 0 : -1
    }

    function activateCurrent(action) {
        action = action || "default"
        if (root.mode !== "freeText" && list.currentIndex >= 0 && list.currentIndex < root.filteredRows.length) {
            root.selected(root.filteredRows[list.currentIndex], action)
        } else if (root.mode !== "list") {
            root.freeTextSubmitted(searchField.text, action)
        }
    }

    onActiveChanged: {
        if (active) {
            searchField.clear()
            refilter()
            searchField.focusInput()
        }
    }

    Connections {
        target: root.items
        function onCountChanged() { refilterDebounce.restart() }
    }

    Timer {
        id: refilterDebounce
        interval: 30
        onTriggered: root.refilter()
    }

    Component.onCompleted: refilter()

    SearchField {
        id: searchField
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        placeholder: root.placeholder

        onTextChanged: root.refilter()
        onUpPressed: list.decrementCurrentIndex()
        onDownPressed: list.incrementCurrentIndex()
        onEscapePressed: root.closeRequested()
        onAccepted: root.activateCurrent()
        onAltBackspace: if (root.secondaryActionKey.length > 0) root.activateCurrent(root.secondaryActionKey)
        onAltD: if (root.tertiaryActionKey.length > 0) root.activateCurrent(root.tertiaryActionKey)
    }

    Text {
        id: hintText
        visible: root.secondaryActionHint.length > 0 || root.tertiaryActionHint.length > 0
        anchors.top: searchField.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        text: [root.secondaryActionHint, root.tertiaryActionHint].filter(h => h.length > 0).join("   ·   ")
        color: theme.dim
        font.pixelSize: 10
        font.family: theme.fontFamily
    }

    ListView {
        id: list
        visible: root.mode !== "freeText"
        anchors.top: hintText.visible ? hintText.bottom : searchField.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 2
        model: root.filteredRows
        boundsBehavior: Flickable.StopAtBounds
        delegate: root.rowDelegate ? root.rowDelegate : defaultDelegate
        keyNavigationWraps: true
        highlightMoveDuration: 60
        highlightMoveVelocity: -1
    }

    Text {
        anchors.centerIn: list
        visible: root.mode !== "freeText" && root.filteredRows.length === 0
        text: root.emptyText
        color: theme.dim
        font.pixelSize: 12
        font.family: theme.fontFamily
    }

    Component {
        id: defaultDelegate
        ListMenuRow {
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { list.currentIndex = index; root.activateCurrent() }
            }
        }
    }
}
