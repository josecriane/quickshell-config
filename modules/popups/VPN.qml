pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.ds.buttons as Buttons
import qs.ds.list
import qs.ds.text as Text
import qs.ds.icons as Icons
import qs.ds.animations
import Quickshell
import QtQuick
import QtQuick as QQ
import QtQuick.Layouts

ColumnLayout {
    id: root

    property int margin: Foundations.spacing.xxs

    spacing: margin
    width: Math.max(320, implicitWidth)

    // Refresh both services when popup becomes visible
    Component.onCompleted: {
        OpenVPN.refreshStatus();
        Tailscale.refreshStatus();
    }

    Text.HeadingS {
        Layout.rightMargin: root.margin
        Layout.topMargin: root.margin
        text: qsTr("VPN")
    }

    // OpenVPN connection details (shown when connected)
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: openvpnDetailsLayout.implicitHeight + Foundations.spacing.m * 2
        Layout.rightMargin: root.margin

        color: Foundations.palette.base01
        radius: Foundations.radius.m
        border.color: Foundations.palette.base03
        border.width: 1
        visible: OpenVPN.connected
        opacity: OpenVPN.connected ? 1.0 : 0.0

        Behavior on opacity {
            BasicNumberAnimation {
            }
        }

        ColumnLayout {
            id: openvpnDetailsLayout

            anchors.fill: parent
            anchors.margins: Foundations.spacing.m
            spacing: Foundations.spacing.s

            DetailRow {
                icon: "vpn_key"
                label: qsTr("Profile")
                value: OpenVPN.connectionName
            }

            DetailRow {
                icon: "public"
                label: qsTr("External IP")
                value: OpenVPN.ipAddress || qsTr("Fetching...")
                loading: OpenVPN.connected && !OpenVPN.ipAddress
            }
        }
    }

    // Tailscale connection details (shown when connected)
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: tailscaleDetailsLayout.implicitHeight + Foundations.spacing.m * 2
        Layout.rightMargin: root.margin

        color: Foundations.palette.base01
        radius: Foundations.radius.m
        border.color: Foundations.palette.base03
        border.width: 1
        visible: Tailscale.connected
        opacity: Tailscale.connected ? 1.0 : 0.0

        Behavior on opacity {
            BasicNumberAnimation {
            }
        }

        ColumnLayout {
            id: tailscaleDetailsLayout

            anchors.fill: parent
            anchors.margins: Foundations.spacing.m
            spacing: Foundations.spacing.s

            DetailRow {
                icon: "computer"
                label: qsTr("Hostname")
                value: Tailscale.hostname
            }

            DetailRow {
                icon: "lan"
                label: qsTr("Tailscale IP")
                value: Tailscale.tailscaleIp || qsTr("Fetching...")
                loading: Tailscale.connected && !Tailscale.tailscaleIp
            }

            DetailRow {
                icon: "cell_tower"
                label: qsTr("Relay")
                value: Tailscale.relay || qsTr("Direct")
            }
        }
    }

    // VPN connections list
    ColumnLayout {
        Layout.fillWidth: true
        Layout.rightMargin: root.margin
        spacing: Foundations.spacing.s

        Repeater {
            model: OpenVPN.connections

            ListItem {
                required property var modelData

                readonly property bool isActive: OpenVPN.serviceName === modelData.serviceName && OpenVPN.connected
                readonly property bool isConnecting: OpenVPN.serviceName === modelData.serviceName && OpenVPN.connecting

                Layout.fillWidth: true
                text: modelData.displayName
                leftIcon: "vpn_key"
                selected: OpenVPN.serviceName === modelData.serviceName
                disabled: OpenVPN.connecting
                primaryActionActive: isActive
                primaryActionLoading: isConnecting
                primaryFontIcon: isActive ? "link_off" : "link"

                onPrimaryActionClicked: {
                    if (isActive) {
                        OpenVPN.disconnect();
                    } else {
                        OpenVPN.connectToService(modelData.serviceName);
                    }
                }
            }
        }

        // Tailscale entry
        ListItem {
            Layout.fillWidth: true
            visible: Tailscale.available
            text: "Tailscale"
            leftIcon: "vpn_key"
            selected: Tailscale.connected
            disabled: Tailscale.connecting
            primaryActionActive: Tailscale.connected
            primaryActionLoading: Tailscale.connecting
            primaryFontIcon: Tailscale.connected ? "link_off" : "link"

            onPrimaryActionClicked: Tailscale.toggle()
        }
    }

    // OpenVPN error
    ErrorBanner {
        visible: OpenVPN.errorMessage !== ""
        message: OpenVPN.errorMessage
    }

    // Tailscale error
    ErrorBanner {
        visible: Tailscale.errorMessage !== ""
        message: Tailscale.errorMessage
    }

    // --- Shared components ---

    component ErrorBanner: Rectangle {
        required property string message

        Layout.fillWidth: true
        Layout.preferredHeight: errorRow.implicitHeight + Foundations.spacing.s * 2
        Layout.rightMargin: root.margin

        color: Foundations.palette.base08
        radius: Foundations.radius.s
        border.color: Foundations.palette.base08
        border.width: 1

        RowLayout {
            id: errorRow
            anchors.fill: parent
            anchors.margins: Foundations.spacing.s
            spacing: Foundations.spacing.s

            Icons.MaterialFontIcon {
                color: Foundations.palette.base08
                font.pointSize: Foundations.font.size.m
                text: "error"
            }

            Text.BodyS {
                Layout.fillWidth: true
                color: Foundations.palette.base08
                text: parent.parent.message || ""
                wrapMode: QQ.Text.WordWrap
            }
        }
    }

    component DetailRow: RowLayout {
        required property string icon
        required property string label
        required property string value
        property bool loading: false

        Layout.fillWidth: true
        spacing: Foundations.spacing.s

        Icons.MaterialFontIcon {
            color: Foundations.palette.base04
            font.pointSize: Foundations.font.size.s
            text: parent.icon
        }

        Text.BodyS {
            color: Foundations.palette.base04
            text: parent.label + ":"
        }

        Item {
            Layout.fillWidth: true
        }

        Text.BodyS {
            color: Foundations.palette.base05
            font.family: parent.value.match(/^\d+\.\d+\.\d+\.\d+$/) ? Foundations.font.family.mono : Foundations.font.family.sans
            text: parent.value

            SequentialAnimation on opacity {
                running: parent.parent.loading || false
                loops: Animation.Infinite
                BasicNumberAnimation { from: 1.0; to: 0.5; duration: Foundations.duration.slow }
                BasicNumberAnimation { from: 0.5; to: 1.0; duration: Foundations.duration.slow }
            }
        }
    }
}
