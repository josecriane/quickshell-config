pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property list<Notification> notifications: server.trackedNotifications.values
    property list<Notification> popups: []
    property list<Notification> queuedPopups: []

    property int defaultExpireTimeout: 4000
    property int maxVisiblePopups: 3
    property bool doNotDisturb: false

    // Check if UI is blocking popups (launcher or notification center open on any screen)
    readonly property bool isUiBlocking: {
        for (const visibilities of Visibilities.screens.values()) {
            if (visibilities.launcher || visibilities.notifications) {
                return true;
            }
        }
        return false;
    }

    // Grouping: get unique app key for a notification
    function getAppKey(notification: Notification): string {
        return notification.desktopEntry || notification.appName || "unknown";
    }

    // Grouped notifications for notification center (most recent first per group)
    readonly property var groupedNotifications: {
        const groups = new Map();
        // Process in reverse order so newest are first
        for (let i = notifications.length - 1; i >= 0; i--) {
            const notification = notifications[i];
            const key = getAppKey(notification);
            if (!groups.has(key)) {
                groups.set(key, {
                    appKey: key,
                    appName: notification.appName || key,
                    appIcon: notification.appIcon || "",
                    notifications: [],
                    latestNotification: notification
                });
            }
            groups.get(key).notifications.push(notification);
        }
        return Array.from(groups.values());
    }

    // Get count of notifications for a specific app
    function getGroupCount(appKey: string): int {
        const group = groupedNotifications.find(g => g.appKey === appKey);
        return group ? group.notifications.length : 0;
    }

    // Dismiss all notifications from a specific app
    function dismissGroup(appKey: string): void {
        const toDismiss = notifications.filter(n => getAppKey(n) === appKey);
        for (const notification of toDismiss) {
            notification.dismiss();
        }
    }

    // Map of notification ID to persisted image path
    property var persistedImages: ({})

    function getPersistedImage(notificationId: int): string {
        return root.persistedImages[notificationId] || ""
    }

    function clearNotifications() {
        root.popups = []
        root.queuedPopups = []
        for (const notification of root.notifications)
            notification.dismiss()
    }

    // Process queued notifications when UI unblocks
    function processQueue() {
        while (root.queuedPopups.length > 0 && root.popups.length < root.maxVisiblePopups && !root.isUiBlocking) {
            const notification = root.queuedPopups.shift();
            // Check notification is still valid (not dismissed)
            if (root.notifications.includes(notification)) {
                root.popups.push(notification);
            }
        }
    }

    // Add notification to popups or queue
    function addPopup(notification: Notification) {
        if (root.isUiBlocking) {
            root.queuedPopups.push(notification);
        } else if (root.popups.length < root.maxVisiblePopups) {
            root.popups.push(notification);
        } else {
            root.queuedPopups.push(notification);
        }
    }

    onIsUiBlockingChanged: {
        if (!isUiBlocking) {
            processQueue();
        }
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;

            // Persist image if present
            try {
                if (notification.image && notification.image !== "") {
                    const persistedPath = NotificationPersistence.persistImage(
                        notification.image,
                        notification.id.toString()
                    );
                    if (persistedPath !== "") {
                        const newMap = Object.assign({}, root.persistedImages);
                        newMap[notification.id] = persistedPath;
                        root.persistedImages = newMap;
                    }
                }
            } catch (e) {
                console.log("Error persisting notification image:", e);
            }

            if (!ScreenShare.isSharing && !root.doNotDisturb) {
                root.addPopup(notification);
            }

            // Connect to notification closed signal to clean up
            notification.closed.connect(() => {
                const popupIndex = root.popups.indexOf(notification);
                if (popupIndex >= 0) {
                    root.popups.splice(popupIndex, 1);
                    // Try to show queued notification
                    root.processQueue();
                }
                const queueIndex = root.queuedPopups.indexOf(notification);
                if (queueIndex >= 0) {
                    root.queuedPopups.splice(queueIndex, 1);
                }
            });

            const timer = timerComponent.createObject(notification, {
                interval: notification.expireTimeout > 0 ? notification.expireTimeout : root.defaultExpireTimeout,
                notification: notification
            });
            timer.start()
        }
    }

    Component {
        id: timerComponent

        Timer {
            property var notification

            repeat: false
            onTriggered: {
                const index = root.popups.indexOf(notification);

                if (index >= 0) {
                    root.popups.splice(index, 1);
                    root.processQueue();
                }

                if (notification.transient) {
                    notification.dismiss();
                }
            }
        }
    }
}
