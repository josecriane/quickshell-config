pragma Singleton

import ".."
import qs.services
import qs.services.search
import Quickshell
import QtQuick

Search {
    id: root

    function launch(entry: DesktopEntry): void {
        LauncherHistory.recordLaunch(entry.id)

        if (entry.runInTerminal) {
            const terminal = "alacritty";
            const terminalCommand = `${terminal} -e ${entry.command.join(" ")}`;
            Niri.spawn(terminalCommand);
        } else {
            Niri.spawn(entry.command.join(" "));
        }
    }
    function search(searchText: string): list<var> {
        const results = query(searchText);

        // Only sort by launch count when there's no search query
        // When searching, preserve fuzzy match order
        if (!searchText) {
            const counts = historyData;
            return results.sort((a, b) => {
                const countA = counts[a.originalData?.id] || 0;
                const countB = counts[b.originalData?.id] || 0;
                if (countA !== countB) {
                    return countB - countA;  // Higher count first
                }
                return a.name.localeCompare(b.name);
            });
        }

        return results;
    }

    list: variants.instances

    property var historyData: LauncherHistory.launchCounts

    Variants {
        id: variants

        model: [...DesktopEntries.applications.values]
            .filter(app => !ConfigsJson.excludedDesktops.includes(app.id))

        delegate: LauncherItemModel {
            required property DesktopEntry modelData

            appIcon: modelData?.icon ?? ""
            isApp: true
            name: modelData?.name ?? ""
            originalData: modelData
            subtitle: modelData?.comment || modelData?.genericName || modelData?.name || ""

            onActivate: function () {
                root.launch(originalData);
            }
        }
    }
}
