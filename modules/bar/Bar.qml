pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.modules.popups as BarPopouts
import qs.modules.bar.components
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property int hPadding: Foundations.spacing.l
    required property int innerHeight
    required property BarPopouts.Wrapper popouts
    required property ShellScreen screen
    required property PersistentProperties visibilities

    function checkPopout(x: real): void {
        const ch = mainLayout.childAt(x, height / 2) as WrappedLoader;
        if (!ch) {
            return;
        }

        const id = ch.id;
        const left = ch.x;
        const item = ch.item;
        const itemWidth = item.implicitWidth;

        if (id === "statusIcons") {
            const items = item.items;
            const icon = items.childAt(mapToItem(items, x, 0).x, items.height / 2);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, icon.implicitWidth / 2, 0).x);
                popouts.hasCurrent = true;
            }
        } else if (id === "tray") {
            const index = Math.floor(((x - left) / itemWidth) * item.items.count);
            const trayItem = item.items.itemAt(index);
            if (trayItem) {
                popouts.currentName = `traymenu${index}`;
                popouts.currentCenter = Qt.binding(() => trayItem.mapToItem(root, trayItem.implicitWidth / 2, 0).x);
                popouts.hasCurrent = true;
            }
        } else if (id === "resources") {
            popouts.currentName = "systemtray";
            popouts.currentCenter = Qt.binding(() => item.mapToItem(root, item.implicitWidth / 2, 0).x);
            popouts.hasCurrent = true;
        } else if (id === "date") {
            popouts.currentName = "calendar";
            popouts.currentCenter = Qt.binding(() => item.mapToItem(root, item.implicitWidth / 2, 0).x);
            popouts.hasCurrent = true;
        } else {
            popouts.hasCurrent = false;
        }
    }

    RowLayout {
        id: mainLayout

        anchors.fill: parent
        spacing: Foundations.spacing.m

        // Left side
        WrappedLoader {
            id: workspaces

            Layout.leftMargin: root.hPadding

            sourceComponent: Workspaces {
                screen: root.screen
            }
        }
        WrappedLoader {
            id: activeWindow

            sourceComponent: ActiveWindow {
                height: root.innerHeight
                screen: root.screen
            }
        }

        // Center spacer
        WrappedLoader {
            id: spacer

            Layout.fillWidth: true
        }

        // Right side items
        WrappedLoader {
            id: tray

            sourceComponent: Tray {
                height: root.innerHeight
            }
        }
        WrappedLoader {
            id: resources

            sourceComponent: SystemTray {
                height: root.innerHeight
            }
        }
        WrappedLoader {
            id: statusIcons

            sourceComponent: StatusIcons {
                height: root.innerHeight
            }
        }
        WrappedLoader {
            id: date

            sourceComponent: Date {
                height: root.innerHeight

                onClicked: {
                    if (popouts.currentName === "calendar" && popouts.hasCurrent) {
                        popouts.hasCurrent = false;
                        popouts.currentName = "";
                    } else {
                        popouts.currentName = "calendar";
                        popouts.currentCenter = Qt.binding(() => date.mapToItem(root, date.width / 2, 0).x);
                        popouts.hasCurrent = true;
                    }
                }
            }
        }
        WrappedLoader {
            id: idleInhibitor

            sourceComponent: IdleInhibitor {
            }
        }
        WrappedLoader {
            id: notificationToggle

            Layout.rightMargin: root.hPadding

            sourceComponent: NotificationListToggle {
                visibilities: root.visibilities
            }
        }
    }

    // Absolutely positioned launcher toggle, centered on screen
    LauncherToggle {
        id: launcherToggle

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        innerHeight: root.innerHeight
        visibilities: root.visibilities
    }

    component WrappedLoader: Loader {
        property string id

        Layout.alignment: Qt.AlignVCenter
        active: true
        visible: true
    }
}
