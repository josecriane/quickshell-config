pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string persistDir: "/tmp/quickshell-notifications"

    Component.onCompleted: {
        ensureDirectoryExists()
        cleanupOldFiles()
    }

    function ensureDirectoryExists() {
        dirCreateComponent.createObject(root)
    }

    function cleanupOldFiles() {
        // Remove files older than 24 hours
        cleanupComponent.createObject(root)
    }

    function persistImage(imagePath: string, notificationId: string): string {
        if (!imagePath || imagePath === "") {
            return ""
        }

        // Extract file extension
        const lastDot = imagePath.lastIndexOf('.')
        const extension = lastDot >= 0 ? imagePath.substring(lastDot) : ".png"

        const persistedPath = `${root.persistDir}/notif-${notificationId}${extension}`

        // Copy the image file
        copyComponent.createObject(root, {
            sourcePath: imagePath,
            destPath: persistedPath
        })

        return persistedPath
    }

    Component {
        id: dirCreateComponent

        Process {
            command: ["mkdir", "-p", root.persistDir]
            running: true
        }
    }

    Component {
        id: cleanupComponent

        Process {
            command: ["sh", "-c", `test -d "${root.persistDir}" && find "${root.persistDir}" -type f -mtime +1 -delete || true`]
            running: true
        }
    }

    Component {
        id: copyComponent

        Process {
            property string sourcePath
            property string destPath

            command: ["cp", sourcePath, destPath]
            running: true
        }
    }

    // Timer to periodically cleanup old files
    Timer {
        interval: 3600000 // 1 hour
        repeat: true
        running: true
        onTriggered: root.cleanupOldFiles()
    }
}
