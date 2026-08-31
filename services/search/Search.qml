import Quickshell

import "./fzf.js" as Fzf
import QtQuick

Scope {
    readonly property var fzf: new Fzf.Finder(list, Object.assign({selector}, ({})))
    property string key: "name"

    required property list<QtObject> list

    function query(search: string): list<var> {
        search = transformSearch(search);
        if (!search)
            return [...list];

        return fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return selector(a.item).trim().length - selector(b.item).trim().length;
            return b.score - a.score;
        }).map(r => r.item);
    }
    function selector(item: var): string {
        // Only for fzf
        return item[key];
    }
    function transformSearch(search: string): string {
        return search;
    }
}
