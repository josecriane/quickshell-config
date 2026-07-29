pragma Singleton

import qs.services
import Quickshell

Singleton {
    property var bars: new Map()
    property var screens: new Map()

    function getForActive(): PersistentProperties {
        const focusedOutput = Mango.focusedOutput;

        for (const [screen, visibilities] of screens) {
            if (screen.name === focusedOutput) {
                return visibilities;
            }
        }

        return screens.values().next().value;
    }
    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(screen, visibilities);
    }
}
