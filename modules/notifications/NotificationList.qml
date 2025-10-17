pragma ComponentBehavior: Bound

import qs.services
import qs.ds.list as List
import qs.ds.animations
import qs.ds
import qs.ds.buttons as Buttons
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    readonly property int notificationWidth: 600

    property bool isAutoMode: false
    readonly property real contentHeight: {
        if (isAutoMode) {
            return flickable.contentHeight + root.padding * 2;
        } else {
            return flickable.contentHeight + clearButton.height + columnLayout.spacing + root.padding;
        }
    }
    required property int padding
    required property var panels
    required property PersistentProperties visibilities
    required property var wrapper

    anchors.fill: parent
    width: notificationWidth + padding

    ColumnLayout {
        id: columnLayout

        anchors.fill: parent
        spacing: Foundations.spacing.s

        RowLayout {
            id: buttonRow

            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: root.padding
            Layout.topMargin: root.padding
            spacing: Foundations.spacing.s
            visible: !root.isAutoMode

            Buttons.HintButton {
                id: dndButton

                hint: NotificationService.doNotDisturb ? "Disable Do Not Disturb" : "Enable Do Not Disturb"
                icon: NotificationService.doNotDisturb ? "do_not_disturb_on" : "notifications"

                onClicked: {
                    NotificationService.doNotDisturb = !NotificationService.doNotDisturb
                }
            }

            Buttons.HintButton {
                id: clearButton

                hint: "Clear all notifications"
                icon: "delete"

                onClicked: {
                    NotificationService.clearNotifications()
                }
            }
        }

        Flickable {
            id: flickable

            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            contentHeight: column.implicitHeight + root.padding
            contentWidth: width

            ScrollBar.vertical: List.ScrollBar {
            }

            Column {
                id: column

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Foundations.spacing.s

                Repeater {
                    model: root.isAutoMode ? NotificationService.popups.length : NotificationService.notifications.length

                    delegate: NotificationItem {
                        required property int index

                        notification: {
                            const list = root.isAutoMode ? NotificationService.popups : NotificationService.notifications;
                            const reverseIndex = list.length - 1 - index;
                            return reverseIndex >= 0 && reverseIndex < list.length ? list[reverseIndex] : null;
                        }

                        notificationWidth: root.notificationWidth
                    }
                }
            }
        }
    }
}
