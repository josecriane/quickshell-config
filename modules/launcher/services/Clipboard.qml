import qs.modules.launcher
import qs.services.search
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Search {
    id: root

    required property string prefix
    property var entries: []

    function reload(): void {
        listProcess.running = false;
        listProcess.running = true;
    }

    function search(search: string): list<var> {
        if (search === root.prefix) {
            return [...query(search)].sort((a, b) => b.entryId - a.entryId);
        }
        return query(search);
    }

    function transformSearch(search: string): string {
        return search.slice(prefix.length);
    }

    list: variants.instances

    Process {
        id: listProcess

        command: ["cliphist", "list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(line => line.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    return {
                        id: line.slice(0, tab),
                        preview: line.slice(tab + 1)
                    };
                });
            }
        }
    }

    Process {
        id: deleteProcess

        running: false

        onExited: root.reload()
    }

    Variants {
        id: variants

        model: root.entries

        delegate: LauncherItemModel {
            required property var modelData

            readonly property bool isImage: /^\[\[ binary data .* \]\]$/.test(modelData.preview)
            readonly property int entryId: parseInt(modelData.id)

            fontIcon: isImage ? "image" : "content_paste"
            isAction: true
            name: isImage ? qsTr("Image") : modelData.preview
            subtitle: isImage ? modelData.preview : ""

            onActivate: function () {
                Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", modelData.id]);
                return true;
            }
            onDelete: function () {
                deleteProcess.command = ["sh", "-c", 'echo "$1" | cliphist delete', "sh", modelData.id];
                deleteProcess.running = true;
            }
        }
    }
}
