pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias commands: commandsAdapter.commands
    property alias sessionCommands: sessionCommandsAdapter.commands
    property alias interactiveCommands: interactiveCommandsAdapter.commands
    property alias excludedDesktops: excludedDesktopsAdapter.excludedApps
    property alias keepass: keepassAdapter

    property FileView commandsFile: FileView {
        path: `${Quickshell.shellDir}/commands.json`
        watchChanges: true

        JsonAdapter {
            id: commandsAdapter
            
            property var commands: []
        }
    }
    
    property FileView sessionCommandsFile: FileView {
        path: `${Quickshell.shellDir}/session-commands.json`
        watchChanges: true

        JsonAdapter {
            id: sessionCommandsAdapter

            property var commands: []
        }
    }

    property FileView interactiveCommandsFile: FileView {
        path: `${Quickshell.shellDir}/interactive-commands.json`
        watchChanges: true

        JsonAdapter {
            id: interactiveCommandsAdapter

            property var commands: []
        }
    }

    property FileView excludedDesktopsFile: FileView {
        path: `${Quickshell.shellDir}/excluded-apps.json`
        watchChanges: true


        JsonAdapter {
            id: excludedDesktopsAdapter

            property var excludedApps: []
        }
    }

    property FileView keepassFile: FileView {
        path: `${Quickshell.shellDir}/keepass.json`
        watchChanges: true

        JsonAdapter {
            id: keepassAdapter

            property string encryptedPasswordPath: ""
            property string ageIdentityPath: ""
            property string databasePath: ""
        }
    }
}
