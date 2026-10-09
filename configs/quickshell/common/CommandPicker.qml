import QtQuick
import Quickshell
import "../"

// a command surface's data, and nothing else. it owns no window and no
// geometry: `body` is instantiated by whichever Surface is showing the command
// drawer, so the models and processes declared in a picker stay single-instance
// up in shell.qml while only the visual tree gets built, once, on the monitor
// the surface opened on
Scope {
    id: root

    property bool open: false
    signal closeRequested()

    required property string popoutName

    // forwarded to the CommandList inside `body`
    property var rows: []
    property var pinned: []
    property var actions: []
    property string mode: "list"
    property string placeholder: "search..."
    property string emptyText: "nothing here"
    property string notice: ""
    property bool quietSubtitles: true
    property bool password: false
    property Component rowDelegate: null
    property var boost: null
    property int maxRows: Theme.commandMaxRows
    property int rowHeight: Theme.rowHeight
    property int iconColumnWidth: 0

    // how wide the drawer should open for this surface
    property int surfaceWidth: Theme.commandWidth

    // a picker with a shape of its own - a grid, a second prompt - replaces
    // this wholesale rather than bending the list into the wrong job
    property Component body: defaultBody

    // the mounted CommandList, or null while the surface is closed. a picker
    // reads its own prompt through here rather than holding a copy
    property var view: null
    readonly property string query: root.view ? root.view.query : ""
    readonly property var current: root.view ? root.view.current : null

    signal selected(var item, string action)
    signal freeTextSubmitted(string text, string action)

    function refilter(): void {
        if (root.view)
            root.view.refilter();
    }

    // called once the drawer has actually mounted the body. a picker whose body
    // nests the list inside a wrapper (a grid with a footer, a prompt that
    // swaps) reaches forceActiveFocus before that tree is parented into a
    // window, where it silently does nothing - so the focus has to be taken
    // again from outside, after the mount
    function focusView(): void {
        if (root.view)
            root.view.focusInput();
    }

    Component {
        id: defaultBody

        CommandList {
            id: list

            implicitWidth: root.surfaceWidth
            active: root.open

            rows: root.rows
            pinned: root.pinned
            actions: root.actions
            mode: root.mode
            placeholder: root.placeholder
            emptyText: root.emptyText
            notice: root.notice
            quietSubtitles: root.quietSubtitles
            password: root.password
            rowDelegate: root.rowDelegate
            boost: root.boost
            maxRows: root.maxRows
            rowHeight: root.rowHeight
            iconColumnWidth: root.iconColumnWidth

            Component.onCompleted: root.view = list
            Component.onDestruction: if (root.view === list)
                root.view = null

            onSelected: (item, action) => root.selected(item, action)
            onFreeTextSubmitted: (text, action) => root.freeTextSubmitted(text, action)
            onCloseRequested: root.closeRequested()
        }
    }
}
