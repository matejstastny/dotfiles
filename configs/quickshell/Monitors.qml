pragma Singleton

import QtQuick

QtObject {
    readonly property var overrides: ({
        "eDP-1": { laptop: true }
    })

    function configFor(screen: var): var {
        return screen && overrides[screen.name] ? overrides[screen.name] : {};
    }

    function isLaptop(screen: var): bool {
        return configFor(screen).laptop === true;
    }
}
