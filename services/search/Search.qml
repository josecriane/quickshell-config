import Quickshell

import "./fzf.js" as Fzf
import QtQuick

Singleton {
    readonly property var fzf: new Fzf.Finder(list, Object.assign({selector}, ({})))
    property string key: "name"

    required property list<QtObject> list

    function query(search: string): list<var> {
        return queryScored(search).map(r => r.item);
    }
    function queryScored(search: string): list<var> {
        search = transformSearch(search);
        if (!search)
            return [...list].map(item => ({item, score: 0}));

        return fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return selector(a.item).trim().length - selector(b.item).trim().length;
            return b.score - a.score;
        });
    }
    function selector(item: var): string {
        // Only for fzf
        return item[key];
    }
    function transformSearch(search: string): string {
        return search;
    }
}
