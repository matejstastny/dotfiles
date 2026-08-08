import Quickshell
import Quickshell.Wayland

ShellRoot {
    LockContext {
        id: lockContext

        onUnlocked: {
            lock.locked = false
            Qt.quit()
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            id: lockSurfaceRoot
            color: "#11111b"

            LockSurface {
                anchors.fill: parent
                context: lockContext
                screen: lockSurfaceRoot.screen
            }
        }
    }
}
