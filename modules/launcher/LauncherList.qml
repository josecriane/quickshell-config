pragma ComponentBehavior: Bound

import qs.services
import qs.ds.list as List
import qs.ds.animations
import qs.ds
import qs.modules.launcher.services as LauncherServices
import Quickshell
import QtQuick
import QtQuick.Controls

ListView {
    id: root
    
    property LauncherServices.CommandLauncher commandsLauncher: LauncherServices.CommandLauncher {
        commandPrefix: "!"
        commandList: ConfigsJson.commands
    }
    
    property LauncherServices.CommandLauncher sessionCommandsLauncher: LauncherServices.CommandLauncher {
        commandPrefix: "#"
        commandList: ConfigsJson.sessionCommands
    }

    property LauncherServices.Actions actionsLauncher: LauncherServices.Actions {
        prefix: ">"
        commandList: ConfigsJson.interactiveCommands
    }

    property LauncherServices.KeePassXC keepassxcLauncher: LauncherServices.KeePassXC {
        prefix: "?"
    }
    required property string searchText
    required property PersistentProperties visibilities

    property int itemHeight: 57
    property int maxShown: 8
    property int margin: Foundations.spacing.s
    property var selectedAction: null

    bottomMargin: margin
    highlightMoveDuration: Foundations.duration.standard
    highlightResizeDuration: Foundations.duration.zero
    implicitHeight: {
        if (state === "interactive") {
            return Math.min(contentHeight + margin, (itemHeight + margin) * maxShown);
        }
        return (itemHeight + margin) * Math.min(maxShown, count);
    }
    orientation: Qt.Vertical

    state: {
        const text = searchText;
        const actionsPrefix = ">";
        const commandsPrefix = "!";
        const sessionCommandsPrefix = "#";

        if (text.startsWith(actionsPrefix)) {
            const interactiveCommands = ConfigsJson.interactiveCommands;
            for (const cmd of interactiveCommands) {
                if (text.startsWith(`${actionsPrefix}${cmd.key} `)) {
                    root.selectedAction = cmd;
                    return "interactive";
                }
            }

            return "actions";
        }

        if (text.startsWith(commandsPrefix)) {
            return "commands";
        }

        if (text.startsWith(sessionCommandsPrefix)) {
            return "sessionCommands";
        }

        const keepassxcPrefix = "?";
        if (text.startsWith(keepassxcPrefix)) {
            return "keepassxc";
        }

        return "apps";
    }

    ScrollBar.vertical: List.ScrollBar {
    }
    add: Transition {
        enabled: !root.state

        BasicNumberAnimation {
            from: 0
            properties: "opacity,scale"
            to: 1
        }
    }
    addDisplaced: ItemTransition {
    }
    displaced: ItemTransition {
    }
    highlight: Rectangle {
        color: Foundations.palette.base07
        opacity: 0.08
        radius: Foundations.radius.xs
    }
    model: ScriptModel {
        id: model

        onValuesChanged: root.currentIndex = count > 0 ? 0 : -1
    }
    move: ItemTransition {
    }
    rebound: Transition {
        BasicNumberAnimation {
            properties: "x,y"
        }
    }
    remove: Transition {
        enabled: !root.state

        BasicNumberAnimation {
            from: 1
            properties: "opacity,scale"
            to: 0
        }
    }
    states: [
        State {
            name: "apps"

            PropertyChanges {
                model.values: LauncherServices.Apps.search(root.searchText)
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                model.values: root.actionsLauncher.search(root.searchText)
                root.delegate: actionItem
            }
        },
        State {
            name: "commands"

            PropertyChanges {
                model.values: root.commandsLauncher.search(root.searchText)
                root.delegate: actionItem
            }
        },
        State {
            name: "sessionCommands"

            PropertyChanges {
                model.values: root.sessionCommandsLauncher.search(root.searchText)
                root.delegate: actionItem
            }
        },
        State {
            name: "keepassxc"

            PropertyChanges {
                model.values: root.keepassxcLauncher.search(root.searchText)
                root.delegate: actionItem
            }
        },
        State {
            name: "interactive"

            PropertyChanges {
                model.values: [0]
                root.delegate: interactiveItem
            }
        }
    ]
    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                BasicNumberAnimation {
                    duration: Foundations.duration.fast
                    from: 1
                    property: "opacity"
                    target: root
                    to: 0
                }
                BasicNumberAnimation {
                    duration: Foundations.duration.fast
                    from: 1
                    property: "scale"
                    target: root
                    to: 0.9
                }
            }
            PropertyAction {
                properties: "values,delegate"
                targets: [model, root]
            }
            ParallelAnimation {
                BasicNumberAnimation {
                    duration: Foundations.duration.fast
                    from: 0
                    property: "opacity"
                    target: root
                    to: 1
                }
                BasicNumberAnimation {
                    duration: Foundations.duration.fast
                    from: 0.9
                    property: "scale"
                    target: root
                    to: 1
                }
            }
            PropertyAction {
                property: "enabled"
                target: root
                value: true
            }
        }
    }

    Component {
        id: appItem

        LauncherItem {
            visibilities: root.visibilities
        }
    }
    Component {
        id: actionItem

        LauncherItem {
            list: root
            visibilities: root.visibilities
        }
    }
    Component {
        id: interactiveItem

        GenericInteractiveItem {
            list: root
            config: root.selectedAction
        }
    }

    component ItemTransition: Transition {
        BasicNumberAnimation {
            duration: Foundations.duration.fast
            property: "y"
        }
        BasicNumberAnimation {
            properties: "opacity,scale"
            to: 1
        }
    }
}
