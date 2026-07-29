pragma Singleton

import ".."
import qs.services
import qs.services.search
import Quickshell
import QtQuick

Search {
    id: root

    function launch(entry: DesktopEntry): void {
        // Record launch for history
        LauncherHistory.recordLaunch(entry.id)

        if (entry.runInTerminal) {
            const terminal = "alacritty";
            const terminalCommand = `${terminal} -e ${entry.command.join(" ")}`;
            Mango.spawn(terminalCommand);
        } else {
            Mango.spawn(entry.command.join(" "));
        }
    }
    function search(searchText: string): list<var> {
        const counts = historyData;
        const boost = id => {
            const count = counts[id] || 0;
            return count > 0 ? frequencyWeight * Math.log2(1 + count) : 0;
        };

        return queryScored(searchText).map(r => ({
            item: r.item,
            score: r.score + boost(r.item.originalData?.id)
        })).sort((a, b) => {
            if (a.score !== b.score)
                return b.score - a.score;
            return a.item.name.localeCompare(b.item.name);
        }).map(r => r.item);
    }

    list: variants.instances

    // Frequency boost weight, log-scaled, comparable to fzf's per-char match score
    property real frequencyWeight: 8.0

    // Reference to trigger re-sort when history changes
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
