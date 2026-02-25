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

FocusScope {
    id: root

    readonly property int notificationWidth: 600

    property bool isAutoMode: false
    property int selectedIndex: 0
    readonly property int groupCount: NotificationService.groupedNotifications.length

    readonly property real contentHeight: {
        if (isAutoMode) {
            return flickable.contentHeight + root.padding * 2;
        } else {
            return flickable.contentHeight + buttonRow.height + columnLayout.spacing + root.padding;
        }
    }
    required property int padding
    required property var panels
    required property PersistentProperties visibilities
    required property var wrapper

    anchors.fill: parent
    width: notificationWidth + padding
    focus: !isAutoMode && visibilities.notifications

    // Reset selection when opening
    onVisibleChanged: {
        if (visible && !isAutoMode) {
            selectedIndex = 0;
        }
    }

    Keys.onUpPressed: {
        if (!isAutoMode && groupCount > 0) {
            selectedIndex = Math.max(0, selectedIndex - 1);
            ensureVisible(selectedIndex);
        }
    }
    Keys.onDownPressed: {
        if (!isAutoMode && groupCount > 0) {
            selectedIndex = Math.min(groupCount - 1, selectedIndex + 1);
            ensureVisible(selectedIndex);
        }
    }
    Keys.onReturnPressed: {
        if (!isAutoMode && groupCount > 0) {
            const group = NotificationService.groupedNotifications[selectedIndex];
            if (group && group.latestNotification) {
                const notification = group.latestNotification;
                const searchId = notification.desktopEntry || notification.appName;
                if (searchId) {
                    Niri.getWindowByAppId(searchId, (window) => {
                        if (window && window.id) {
                            Niri.focusWindowById(window.id);
                        }
                    }, notification.summary || "");
                }
            }
        }
    }
    Keys.onDeletePressed: {
        if (!isAutoMode && groupCount > 0) {
            const group = NotificationService.groupedNotifications[selectedIndex];
            if (group) {
                NotificationService.dismissGroup(group.appKey);
                selectedIndex = Math.min(selectedIndex, groupCount - 2);
            }
        }
    }
    Keys.onEscapePressed: {
        visibilities.notifications = false;
    }

    function ensureVisible(index: int): void {
        const item = groupRepeater.itemAt(index);
        if (item) {
            const itemY = item.y;
            const itemBottom = itemY + item.height;
            if (itemY < flickable.contentY) {
                flickable.contentY = itemY;
            } else if (itemBottom > flickable.contentY + flickable.height) {
                flickable.contentY = itemBottom - flickable.height;
            }
        }
    }

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

                // Auto mode (popups): show flat list of individual notifications
                Repeater {
                    model: root.isAutoMode ? NotificationService.popups.length : 0

                    delegate: NotificationItem {
                        required property int index

                        notification: {
                            const list = NotificationService.popups;
                            const reverseIndex = list.length - 1 - index;
                            return reverseIndex >= 0 && reverseIndex < list.length ? list[reverseIndex] : null;
                        }

                        notificationWidth: root.notificationWidth
                    }
                }

                // Manual mode (notification center): show grouped notifications
                Repeater {
                    id: groupRepeater

                    model: root.isAutoMode ? 0 : NotificationService.groupedNotifications.length

                    delegate: NotificationGroup {
                        required property int index

                        group: NotificationService.groupedNotifications[index]
                        notificationWidth: root.notificationWidth
                        isSelected: !root.isAutoMode && root.selectedIndex === index
                    }
                }
            }
        }
    }
}
