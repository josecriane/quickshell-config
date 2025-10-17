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

    // ToDo Harcoded?
    readonly property int borderRadius: Foundations.radius.s
    readonly property int margin: Foundations.spacing.s

    readonly property int imageDimension: 41
    readonly property int iconDimension: 20

    readonly property bool hasAppIcon: notification.appIcon !== ""
    readonly property bool hasImage: notification.image !== ""
    readonly property int nonAnimHeight: summaryView.implicitHeight + appName.height + body.height + actionsView.height + actionsView.anchors.topMargin + inner.anchors.margins * 2
    
    // Safe properties with defaults
    readonly property string appIcon: notification.appIcon ?? ""
    readonly property string summary: notification.summary ?? ""
    readonly property string image: notification.image ?? ""
    readonly property string appName: notification.appName ?? ""
    readonly property string body: notification.body ?? ""

    readonly property bool isCritical: notification.urgency === NotificationUrgency.Critical
    readonly property bool isLow: notification.urgency === NotificationUrgency.Low

    // anchors.horizontalCenter: pa?ent.horizontalCenter
    color: root.isCritical ? Foundations.palette.base04 : Foundations.palette.base02
    implicitHeight: inner.implicitHeight
    implicitWidth: notificationWidth
    radius: borderRadius

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        preventStealing: true

        onClicked: event => {
            if (event.button !== Qt.LeftButton)
                return;

            const searchId = root.notification.desktopEntry || root.appName;
            const titleHint = root.summary;

            if (searchId) {
                Niri.getWindowByAppId(searchId, (window) => {
                    if (window && window.id) {
                        Niri.focusWindowById(window.id);
                    } else {
                        console.log("No matching window found for:", searchId);
                    }
                }, titleHint);
            }

            switch (root.notification.actions.length) {
                case 0:
                    root.notification.dismiss()
                    return
                case 1:
                    root.notification.actions[0].invoke()
                    return
                default:
                    return
            }
        }

        Item {
            id: inner

            anchors.left: parent.left
            anchors.margins: margin
            anchors.right: parent.right
            anchors.top: parent.top
            implicitHeight: root.nonAnimHeight

            DsText.BodyS {
                id: appName

                anchors.left: parent.left
                anchors.top: parent.top
                maximumLineCount: 1
                text: root.appName

                Behavior on opacity {
                    BasicNumberAnimation {
                    }
                }
            }
            CircularButtons.S {
                id: closeButton

                anchors.right: parent.right
                anchors.top: parent.top

                icon: "close"
                visible: root.notification.actions.length > 0

                onClicked: {
                    root.notification.dismiss()
                }
            }
            Loader {
                id: mainImage

                active: root.hasImage
                anchors.left: parent.left
                anchors.top: appName.bottom
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
                anchors.top: root.hasImage ? undefined : appName.bottom
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
                            font.pointSize: Foundations.font.size.l
                            text: IconsService.getNotifIcon(root.isCritical ? "critical" : root.summary)
                        }
                    }
                }
            }

            DsText.BodyM {
                id: summaryView

                anchors.left: mainImage.right
                anchors.leftMargin: margin
                anchors.top: appName.bottom
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
                color: Foundations.palette.base04
                height: implicitHeight
                opacity: 1
                text: root.body
                textFormat: Text.MarkdownText
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
            RowLayout {
                id: actionsView

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: body.bottom
                anchors.topMargin: margin
                opacity: 1
                spacing: margin

                Repeater {
                    model: root.notification.actions

                    ActionButton {
                        required property NotificationAction modelData

                        text: qsTr(modelData?.text ?? "")
                        leftIcon: ""
                        visible: root.notification?.actions?.length > 1

                        onClicked: {
                            modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    component ActionButton: Buttons.PrimaryButton {
        id: actionButton

        margin: Foundations.spacing.xs

        property color backgroundColor: root.isCritical ? Foundations.palette.base09 : Foundations.palette.base07
        property color foregroundColor: root.isCritical ? Foundations.palette.base01 : Foundations.palette.base04
    }
}
