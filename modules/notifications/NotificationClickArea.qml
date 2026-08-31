pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import QtQuick

MouseArea {
    id: root

    required property var notification

    property string clickState: "idle"

    readonly property bool hasFeedback: clickState !== "idle"
    readonly property color feedbackColor: {
        if (clickState === "searching")
            return Qt.lighter(Foundations.palette.base03, 1.1);
        if (clickState === "found")
            return Foundations.palette.base0B;
        if (clickState === "notfound")
            return Foundations.palette.base09;
        return "transparent";
    }

    acceptedButtons: Qt.LeftButton
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true

    onClicked: {
        const appName = root.notification.appName ?? "";
        const summary = root.notification.summary ?? "";
        const body = root.notification.body ?? "";
        const actions = root.notification.actions;

        const searchId = root.notification.desktopEntry || appName;
        let titleHint = appName || summary;
        const urlMatch = body.match(/https?:\/\/([^/">\s]+)/);
        if (urlMatch)
            titleHint = urlMatch[1];

        if (searchId) {
            let defaultAction = null;
            for (let i = 0; i < actions.length; i++) {
                if (actions[i].identifier === "default") {
                    defaultAction = actions[i];
                    break;
                }
            }

            root.clickState = "searching";

            Niri.getWindowByAppId(searchId, window => {
                if (window && window.id) {
                    root.clickState = "found";
                    Niri.focusWindowById(window.id);
                } else {
                    root.clickState = "notfound";
                }
                feedbackTimer.restart();
                if (defaultAction)
                    defaultAction.invoke();
            }, titleHint);
        } else {
            for (let i = 0; i < actions.length; i++) {
                if (actions[i].identifier === "default") {
                    actions[i].invoke();
                    return;
                }
            }
            if (actions.length === 0) {
                root.notification.dismiss();
            }
        }
    }

    Timer {
        id: feedbackTimer

        interval: 600

        onTriggered: root.clickState = "idle"
    }
}
