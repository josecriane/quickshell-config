import qs.modules.launcher
import qs.services.search
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Search {
    id: root

    required property string prefix

    readonly property string passwordPath: ConfigsJson.keepass.masterPasswordPath
    readonly property string dbPath: ConfigsJson.keepass.databasePath

    function search(search: string): list<var> {
        if (search === prefix && passwordPath && dbPath) {
            loadEntries();
        }
        return query(search);
    }

    function transformSearch(search: string): string {
        return search.slice(prefix.length);
    }

    list: variants.instances

    onPasswordPathChanged: {
        if (passwordPath && dbPath) {
            loadEntries();
        }
    }

    onDbPathChanged: {
        if (passwordPath && dbPath) {
            loadEntries();
        }
    }

    function loadEntries() {
        entriesProcess.command = ["sh", "-c", `cat "${passwordPath}" | keepassxc-cli ls --flatten -q "${dbPath}"`];
        entriesProcess.running = true;
    }

    property var entryList: []

    Process {
        id: entriesProcess

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(line => line.length > 0 && !line.endsWith('/'));
                root.entryList = lines;
            }
        }
    }

    Variants {
        id: variants

        model: entryList

        delegate: LauncherItemModel {
            required property var modelData

            readonly property string entryName: modelData

            function onActivate() {
                Quickshell.execDetached(["sh", "-c", `cat "${root.passwordPath}" | keepassxc-cli show -q -a password "${root.dbPath}" "${entryName}" | tr -d '\\n' | wl-copy -o`]);
                return true;
            }

            autocompleteText: ""
            fontIcon: "key"
            isAction: true
            name: entryName
            subtitle: "Password entry"
        }
    }
}
