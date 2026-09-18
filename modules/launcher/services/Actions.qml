import qs.modules.launcher
import qs.services.search
import qs.services
import Quickshell
import QtQuick

Search {
    id: root

    required property string prefix
    required property var commandList
    required property var interactiveCommandList

    function search(search: string): list<var> {
        return query(search);
    }

    function transformSearch(search: string): string {
        return search.slice(prefix.length);
    }

    list: Array.from(interactiveVariants.instances).concat(Array.from(commandVariants.instances))

    Variants {
        id: interactiveVariants

        model: root.interactiveCommandList

        delegate: LauncherItemModel {
            required property var modelData

            autocompleteText: modelData.commandPrefix
            fontIcon: modelData.fontIcon
            isAction: true
            name: modelData.name
            subtitle: modelData.subtitle
        }
    }

    Variants {
        id: commandVariants

        model: root.commandList

        delegate: LauncherItemModel {
            required property var modelData

            fontIcon: modelData.icon
            isAction: true
            name: modelData.name
            originalData: modelData
            subtitle: modelData.description || modelData.command

            onActivate: function () {
                if (modelData.delayed) {
                    delayedExecutionTimer.createObject(root, {
                        command: modelData.command
                    }).start();
                } else {
                    Quickshell.execDetached(["sh", "-c", modelData.command]);
                }
                return true;
            }
        }
    }

    Component {
        id: delayedExecutionTimer

        Timer {
            property string command

            interval: 200
            repeat: false

            onTriggered: {
                Quickshell.execDetached(["sh", "-c", command]);
                destroy();
            }
        }
    }
}
