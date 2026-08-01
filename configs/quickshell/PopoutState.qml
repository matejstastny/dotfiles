pragma Singleton
import QtQuick

QtObject {
    // shared across every popout (tray menus, control centre) so opening one
    // automatically closes any other - only one name can match at a time
    property string current: ""
}
