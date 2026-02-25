pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string historyPath: `${Quickshell.workingDirectory}/.cache/launcher-history.json`
    property var launchCounts: ({})
    property bool loaded: false

    // Save debounce timer
    property Timer saveTimer: Timer {
        interval: 1000
        onTriggered: root.saveHistory()
    }

    Component.onCompleted: {
        loadHistory()
    }

    function recordLaunch(appId: string): void {
        if (!appId) return

        // Create new object to trigger QML change detection
        const counts = Object.assign({}, launchCounts)
        counts[appId] = (counts[appId] || 0) + 1
        launchCounts = counts

        // Debounce save
        saveTimer.restart()
    }

    function getLaunchCount(appId: string): int {
        return launchCounts[appId] || 0
    }

    function loadHistory(): void {
        historyLoader.running = true
    }

    function saveHistory(): void {
        const json = JSON.stringify(launchCounts)
        // Escape for shell: replace single quotes with '"'"'
        const escaped = json.replace(/'/g, "'\"'\"'")
        saveComponent.createObject(root, { jsonData: escaped })
    }

    Process {
        id: historyLoader

        command: ["sh", "-c", `test -f '${root.historyPath}' && cat '${root.historyPath}' || echo '{}'`]

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.launchCounts = JSON.parse(data)
                } catch (e) {
                    console.warn("[LauncherHistory] Failed to parse history:", e)
                    root.launchCounts = {}
                }
                root.loaded = true
            }
        }
    }

    Component {
        id: saveComponent

        Process {
            property string jsonData

            command: ["sh", "-c", `mkdir -p "$(dirname '${root.historyPath}')" && printf '%s' '${jsonData}' > '${root.historyPath}'`]
            running: true

            onRunningChanged: {
                if (!running) {
                    destroy()
                }
            }
        }
    }
}
