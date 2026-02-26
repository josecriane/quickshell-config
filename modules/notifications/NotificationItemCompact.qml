pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.ds.icons as Icons
import qs.ds.text as DsText
import qs.ds.animations
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var notification
    required property int notificationWidth
    property bool showDismiss: false

    readonly property int margin: Foundations.spacing.xs
    readonly property int imageDimension: 32

    readonly property bool hasImage: notification.image !== ""
    readonly property string summary: notification.summary ?? ""
    readonly property string body: notification.body ?? ""
    readonly property bool isCritical: notification.urgency === NotificationUrgency.Critical

    // Click feedback state: "idle", "searching", "found", "notfound"
    property string clickState: "idle"

    color: {
        if (clickState === "searching") return Qt.lighter(Foundations.palette.base03, 1.1);
        if (clickState === "found") return Foundations.palette.base0B;
        if (clickState === "notfound") return Foundations.palette.base09;
        if (mouseArea.containsMouse) return Foundations.palette.base03;
        return "transparent";
    }
    radius: Foundations.radius.xs
    implicitWidth: notificationWidth
    implicitHeight: contentRow.implicitHeight + margin * 2

    Behavior on color {
        BasicColorAnimation {
            duration: Foundations.duration.fast
        }
    }

    Timer {
        id: feedbackTimer
        interval: 600
        onTriggered: root.clickState = "idle"
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            const searchId = root.notification.desktopEntry || root.notification.appName;
            let titleHint = root.notification.appName || root.summary;
            const urlMatch = root.body.match(/https?:\/\/([^/">\s]+)/);
            if (urlMatch) titleHint = urlMatch[1];

            if (searchId) {
                let defaultAction = null;
                for (let i = 0; i < root.notification.actions.length; i++) {
                    if (root.notification.actions[i].identifier === "default") {
                        defaultAction = root.notification.actions[i];
                        break;
                    }
                }

                root.clickState = "searching";

                Niri.getWindowByAppId(searchId, (window) => {
                    if (window && window.id) {
                        root.clickState = "found";
                        Niri.focusWindowById(window.id);
                    } else {
                        root.clickState = "notfound";
                    }
                    feedbackTimer.restart();
                    if (defaultAction) defaultAction.invoke();
                }, titleHint);
            } else {
                for (let i = 0; i < root.notification.actions.length; i++) {
                    if (root.notification.actions[i].identifier === "default") {
                        root.notification.actions[i].invoke();
                        return;
                    }
                }
                if (root.notification.actions.length === 0) {
                    root.notification.dismiss();
                }
            }
        }
    }

    RowLayout {
        id: contentRow

        anchors.fill: parent
        anchors.margins: margin
        spacing: Foundations.spacing.s

        // Image/icon
        Loader {
            active: root.hasImage
            Layout.preferredWidth: root.imageDimension
            Layout.preferredHeight: root.imageDimension
            Layout.alignment: Qt.AlignTop

            sourceComponent: ClippingRectangle {
                radius: Foundations.radius.xs

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    source: Qt.resolvedUrl(root.notification.image)
                }
            }
        }

        // Text content
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            DsText.BodyM {
                Layout.fillWidth: true
                text: summaryMetrics.elidedText
                maximumLineCount: 1
                color: root.isCritical ? Foundations.palette.base08 : Foundations.palette.base06
            }

            TextMetrics {
                id: summaryMetrics
                elide: Text.ElideRight
                elideWidth: root.notificationWidth - root.imageDimension - root.margin * 4 - (root.showDismiss ? 24 : 0)
                font.family: Foundations.font.family.sans
                font.pointSize: Foundations.font.size.m
                text: root.summary
            }

            DsText.BodyS {
                Layout.fillWidth: true
                text: bodyMetrics.elidedText
                maximumLineCount: 2
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Foundations.palette.base05
                visible: root.body !== ""
            }

            TextMetrics {
                id: bodyMetrics
                elide: Text.ElideRight
                elideWidth: root.notificationWidth - root.imageDimension - root.margin * 4 - (root.showDismiss ? 24 : 0)
                font.family: Foundations.font.family.sans
                font.pointSize: Foundations.font.size.s
                text: root.body.replace(/\n/g, " ")
            }
        }

        // Dismiss button (shows on row hover)
        Rectangle {
            id: dismissButton

            visible: root.showDismiss
            opacity: mouseArea.containsMouse ? 1 : 0
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            radius: 10
            color: dismissArea.containsMouse ? Foundations.palette.base08 : Foundations.palette.base03

            Behavior on opacity {
                BasicNumberAnimation {
                    duration: Foundations.duration.fast
                }
            }

            Icons.MaterialFontIcon {
                anchors.centerIn: parent
                text: "close"
                color: dismissArea.containsMouse ? Foundations.palette.base07 : Foundations.palette.base05
                font.pointSize: Foundations.font.size.xs
            }

            MouseArea {
                id: dismissArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.notification.dismiss()
            }
        }
    }
}
