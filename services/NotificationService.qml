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

    property int defaultExpireTimeout: 5000
    property bool doNotDisturb: false

    function clearNotifications() {
        root.popups = []
        for (const notification  of root.notifications)
            notification.dismiss()
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

            if (!ScreenShare.isSharing && !root.doNotDisturd) {
                root.popups.push(notification)
            }

            // Connect to notification closed signal to clean up
            notification.closed.connect(() => {
                const index = root.popups.indexOf(notification);
                if (index >= 0) {
                    root.popups.splice(index, 1);
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
                }

                if (notification.transient) {
                    notification.dismiss()
                }
            }
        }
    }
}