pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.services
import qs.ds.icons as Icons
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.ds.animations
import qs.ds.text as DsText
import qs.ds.buttons as Buttons
import qs.ds.buttons.circularButtons as CircularButtons

Rectangle {
    id: root

    required property Notification notification
    required property int notificationWidth

    readonly property int borderRadius: Foundations.radius.s
    readonly property int margin: Foundations.spacing.s

    readonly property int imageDimension: 41
    readonly property int iconDimension: 20

    readonly property bool hasAppIcon: notification.appIcon !== ""
    readonly property bool hasImage: notification.image !== ""
    readonly property int nonAnimHeight: summaryView.implicitHeight + appNameRow.height + body.height + (replyLoader.active ? replyLoader.height + margin : 0) + inner.anchors.margins * 2

    // Safe properties with defaults
    readonly property string appIcon: notification.appIcon ?? ""
    readonly property string summary: notification.summary ?? ""
    readonly property string image: notification.image ?? ""
    readonly property string appName: notification.appName ?? ""
    readonly property string body: notification.body ?? ""

    readonly property bool isCritical: notification.urgency === NotificationUrgency.Critical
    readonly property bool isLow: notification.urgency === NotificationUrgency.Low

    // Click feedback state: "idle", "searching", "found", "notfound"
    property string clickState: "idle"

    color: {
        if (clickState === "searching") return Qt.lighter(Foundations.palette.base03, 1.1);
        if (clickState === "found") return Foundations.palette.base0B;
        if (clickState === "notfound") return Foundations.palette.base09;
        if (root.isCritical) return Foundations.palette.base04;
        return Foundations.palette.base02;
    }
    implicitHeight: inner.implicitHeight
    implicitWidth: notificationWidth
    radius: borderRadius

    Behavior on color {
        BasicColorAnimation {
            duration: Foundations.duration.fast
        }
    }

    // Reset click state after feedback
    Timer {
        id: feedbackTimer
        interval: 600
        onTriggered: root.clickState = "idle"
    }

    MouseArea {
        id: mouseArea

        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        onClicked: event => {
            if (event.button !== Qt.LeftButton)
                return;

            // Try to focus window by desktopEntry first, then appName
            const searchId = root.notification.desktopEntry || root.appName;
            let titleHint = root.appName || root.summary;
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

        Item {
            id: inner

            anchors.left: parent.left
            anchors.margins: margin
            anchors.right: parent.right
            anchors.top: parent.top
            implicitHeight: root.nonAnimHeight

            RowLayout {
                id: appNameRow

                anchors.left: parent.left
                anchors.top: parent.top
                spacing: Foundations.spacing.xs

                DsText.BodyM {
                    id: appName

                    Layout.fillWidth: false
                    maximumLineCount: 1
                    text: root.appName

                    Behavior on opacity {
                        BasicNumberAnimation {
                        }
                    }
                }

                Icons.MaterialFontIcon {
                    Layout.alignment: Qt.AlignVCenter
                    color: Foundations.palette.base0C
                    font.pointSize: Foundations.font.size.m
                    text: "reply"
                    visible: root.notification.hasInlineReply
                }
            }
            Loader {
                id: mainImage

                active: root.hasImage
                anchors.left: parent.left
                anchors.top: appNameRow.bottom
                anchors.topMargin: Foundations.spacing.xs
                asynchronous: true
                height: root.imageDimension
                visible: root.hasImage
                width: root.imageDimension

                sourceComponent: ClippingRectangle {
                    implicitHeight: root.imageDimension
                    implicitWidth: root.imageDimension
                    radius: Foundations.radius.all

                    Image {
                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        source: {
                            Qt.resolvedUrl(root.image)
                        }
                    }
                }
            }
            Loader {
                id: appIcon

                anchors.bottom: root.hasImage ? mainImage.bottom : undefined
                anchors.right: root.hasImage ? mainImage.right : undefined
                anchors.top: root.hasImage ? undefined : appNameRow.bottom
                anchors.topMargin: root.hasImage ? undefined : Foundations.spacing.xs
                asynchronous: true

                sourceComponent: Rectangle {
                    color: root.isCritical ? Foundations.palette.base07 : Foundations.palette.base04
                    implicitHeight: root.hasImage ? root.iconDimension : root.imageDimension
                    implicitWidth: root.hasImage ? root.iconDimension : root.imageDimension
                    radius: Foundations.radius.all

                    Loader {
                        id: icon

                        active: root.hasAppIcon
                        anchors.centerIn: parent
                        asynchronous: true
                        height: Math.round(parent.width * 0.6)
                        width: Math.round(parent.width * 0.6)

                        sourceComponent: IconImage {
                            anchors.fill: parent
                            asynchronous: true
                            source: Quickshell.iconPath(root.appIcon)
                        }
                    }
                    Loader {
                        active: !root.hasAppIcon
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -Foundations.font.size.l * 0.02
                        anchors.verticalCenterOffset: Foundations.font.size.l * 0.02
                        asynchronous: true

                        sourceComponent: Icons.MaterialFontIcon {
                            color: root.isCritical ? Foundations.palette.base08 : Foundations.palette.base07
                            font.pointSize: Foundations.font.size.xl
                            text: IconsService.getNotifIcon(root.isCritical ? "critical" : root.summary)
                        }
                    }
                }
            }

            DsText.BodyM {
                id: summaryView

                anchors.left: mainImage.right
                anchors.leftMargin: margin
                anchors.top: appNameRow.bottom
                height: implicitHeight
                maximumLineCount: 1
                text: summaryMetrics.elidedText
            }
            TextMetrics {
                id: summaryMetrics

                elide: Text.ElideRight
                elideWidth: notificationWidth - imageDimension - margin * 3
                font.family: summaryView.font.family
                font.pointSize: summaryView.font.pointSize
                text: root.summary
            }
            DsText.BodyS {
                id: body

                anchors.left: summaryView.left
                anchors.right: parent.right
                anchors.rightMargin: margin
                anchors.top: summaryView.bottom
                color: Foundations.palette.base05
                height: implicitHeight
                opacity: 1
                text: root.body
                textFormat: Text.MarkdownText
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Loader {
                id: replyLoader

                active: root.notification.hasInlineReply
                anchors.left: summaryView.left
                anchors.right: parent.right
                anchors.rightMargin: margin
                anchors.top: body.bottom
                anchors.topMargin: active ? margin : 0
                asynchronous: true
                visible: active

                sourceComponent: ReplyInput {
                    onReplySent: text => {
                        root.notification.sendInlineReply(text)
                    }
                }
            }
        }
    }

}
