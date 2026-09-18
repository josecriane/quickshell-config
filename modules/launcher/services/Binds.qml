import qs.modules.launcher
import qs.services.search
import Quickshell
import QtQuick

Search {
    id: root

    required property string prefix
    required property var bindList

    function search(search: string): list<var> {
        if (search === root.prefix) {
            return [...query(search)].sort((a, b) => a.order - b.order);
        }
        return query(search);
    }

    function transformSearch(search: string): string {
        return search.slice(prefix.length);
    }

    key: "matchText"
    list: variants.instances

    Variants {
        id: variants

        model: root.bindList

        delegate: LauncherItemModel {
            required property var modelData

            readonly property string action: modelData.action ?? ""
            readonly property string args: modelData.args ?? ""
            readonly property int order: modelData.order ?? 0

            readonly property string matchText: `${modelData.key} ${action} ${args}`

            fontIcon: {
                if (modelData.key.startsWith("XF86Audio"))
                    return "volume_up";
                if (modelData.key.startsWith("XF86MonBrightness"))
                    return "brightness_medium";
                if (action.startsWith("screenshot"))
                    return "photo_camera";
                if (action === "spawn")
                    return "terminal";
                return "keyboard";
            }
            isAction: true
            name: modelData.key
            subtitle: [action, args].filter(part => part).join(" ")

            onActivate: function () {
                return true;
            }
        }
    }
}
