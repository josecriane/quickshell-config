import qs.ds
import qs.services
import qs.ds.buttons.circularButtons as CircularButtons
import Quickshell
import QtQuick

CircularButtons.S {
    id: root

    required property var visibilities
    readonly property bool enabled: root.visibilities.notifications

    icon: NotificationService.doNotDisturb ? "do_not_disturb_on" : "notifications"

    backgroundColor: enabled ? Foundations.palette.base00 : "transparent"
    foregroundColor: enabled ? Foundations.palette.base00 : Foundations.palette.base0D

    active: enabled

    onClicked: {
        root.visibilities.notifications = !root.visibilities.notifications;
    }
}
