pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.services as Services
import qs.ds.buttons as Buttons
import qs.ds.list as Lists
import qs.ds.text as Text
import qs.ds.icons as Icons
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var wrapper

    property string connectingToSsid: ""
    property string pendingSsid: ""
    property bool showPasswordDialog: false

    // ToDo: Review
    property int margin: Foundations.spacing.xxs

    spacing: margin
    width: Math.max(320, implicitWidth)

    Text.HeadingS {
        Layout.rightMargin: root.margin
        Layout.topMargin: root.margin
        text: qsTr("Network")
    }

    // Connection details section (shown when there are active connections)
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: detailsLayout.implicitHeight + Foundations.spacing.m * 2
        Layout.rightMargin: root.margin
        Layout.bottomMargin: root.margin

        color: Foundations.palette.base01
        radius: Foundations.radius.s
        border.color: Foundations.palette.base03
        border.width: 1
        visible: Network.ethernetIp !== "" || Network.wifiIp !== ""

        ColumnLayout {
            id: detailsLayout

            anchors.fill: parent
            anchors.margins: Foundations.spacing.m
            spacing: Foundations.spacing.s

            Text.BodyS {
                color: Foundations.palette.base04
                text: qsTr("Connection Details")
                font.weight: Font.Medium
            }

            // Ethernet IP
            DetailRow {
                icon: "lan"
                label: qsTr("Ethernet IP")
                value: Network.ethernetIp
                visible: Network.ethernetIp !== ""
            }

            // WiFi IP
            DetailRow {
                icon: "wifi"
                label: qsTr("WiFi IP")
                value: Network.wifiIp
                visible: Network.wifiIp !== ""
            }
        }
    }

    // No active connections message
    Text.BodyS {
        Layout.fillWidth: true
        Layout.rightMargin: root.margin
        text: qsTr("No active network connections")
        color: Foundations.palette.base03
        horizontalAlignment: Text.AlignHCenter
        visible: Network.ethernetIp === "" && Network.wifiIp === ""
    }
    Toggle {
        Layout.topMargin: root.margin
        checked: Network.wifiEnabled
        label: qsTr("WiFi enabled")

        toggle.onToggled: Network.enableWifi(checked)
    }
    Text.BodyS {
        Layout.rightMargin: root.margin
        Layout.topMargin: root.margin
        disabled: true
        text: qsTr("%1 networks available").arg(Network.networks.length)
    }
    Repeater {
        model: ScriptModel {
            values: [...Network.networks].sort((a, b) => {
                if (a.active !== b.active)
                    return b.active - a.active;
                return b.strength - a.strength;
            }).slice(0, 8)
        }

        Lists.ListItem {
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
            required property Network.AccessPoint modelData

            disabled: !Network.wifiEnabled
            leftIcon: Services.IconsService.getNetworkIcon(modelData.strength)
            primaryActionActive: modelData.active
            primaryActionLoading: isConnecting
            primaryFontIcon: modelData.active ? "link_off" : "link"
            secondaryIcon: modelData.isSecure ? "lock" : ""
            selected: modelData.active
            text: modelData.ssid

            onPrimaryActionClicked: {
                if (modelData.active) {
                    Network.disconnectFromNetwork();
                } else {
                    root.connectingToSsid = modelData.ssid;
                    root.pendingSsid = modelData.ssid;
                    Network.connectToNetwork(modelData.ssid, "");

                    if (modelData.isSecure) {
                        connectionCheckTimer.ssid = modelData.ssid;
                        connectionCheckTimer.start();
                    }
                }
            }
        }
    }
    Buttons.PrimaryButton {
        Layout.fillWidth: true
        Layout.topMargin: root.margin
        disabled: !Network.wifiEnabled
        leftIcon: "wifi_find"
        loading: Network.scanning
        text: qsTr("Rescan networks")

        onClicked: Network.rescanWifi()
    }

    // Timer to check if connection failed and show password dialog
    Timer {
        id: connectionCheckTimer
        interval: 3000
        repeat: false
        property string ssid: ""

        onTriggered: {
            if (root.connectingToSsid === ssid && (!Network.active || Network.active.ssid !== ssid)) {
                root.connectingToSsid = "";
                root.pendingSsid = ssid;
                root.showPasswordDialog = true;
            }
        }
    }

    // Reset connecting state when network changes
    Connections {
        function onActiveChanged(): void {
            if (Network.active && root.connectingToSsid === Network.active.ssid) {
                root.connectingToSsid = "";
                root.pendingSsid = "";
                connectionCheckTimer.stop();
            }
        }

        target: Network
    }

    onShowPasswordDialogChanged: {
        if (root.wrapper) {
            root.wrapper.needsFocus = showPasswordDialog;
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: passwordDialog.implicitHeight + Foundations.spacing.m * 2
        Layout.rightMargin: root.margin

        color: Foundations.palette.base01
        radius: Foundations.radius.m
        border.color: Foundations.palette.base03
        border.width: 1
        visible: root.showPasswordDialog

        ColumnLayout {
            id: passwordDialog

            anchors.fill: parent
            anchors.margins: Foundations.spacing.m
            spacing: Foundations.spacing.s

            Text.BodyS {
                color: Foundations.palette.base04
                text: qsTr("Enter WiFi Password")
                font.weight: Font.Medium
            }

            Text.BodyS {
                color: Foundations.palette.base05
                text: qsTr("Network: %1").arg(root.pendingSsid)
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true

                background: null
                backgroundColor: "transparent"
                borderWidth: 0
                placeholderText: qsTr("Password")
                echoMode: TextInput.Password
                font.pointSize: Foundations.font.size.s

                Keys.onReturnPressed: connectButton.clicked()
                Keys.onEnterPressed: connectButton.clicked()
                Keys.onEscapePressed: cancelButton.clicked()

                Timer {
                    id: focusTimer
                    interval: 1
                    repeat: true

                    onTriggered: {
                        if (passwordField.visible && root.showPasswordDialog) {
                            passwordField.forceActiveFocus();
                            passwordField.focus = true;
                            stop();
                        }
                    }
                }

                Connections {
                    function onShowPasswordDialogChanged(): void {
                        if (root.showPasswordDialog) {
                            focusTimer.start();
                        } else {
                            focusTimer.stop();
                            passwordField.text = "";
                        }
                    }

                    target: root
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Foundations.spacing.s

                Buttons.Button {
                    id: cancelButton
                    Layout.fillWidth: true
                    text: qsTr("Cancel")

                    onClicked: {
                        root.showPasswordDialog = false;
                        root.pendingSsid = "";
                        if (root.wrapper) {
                            root.wrapper.needsFocus = false;
                        }
                    }
                }

                Buttons.PrimaryButton {
                    id: connectButton
                    Layout.fillWidth: true
                    text: qsTr("Connect")
                    enabled: passwordField.text.length > 0

                    onClicked: {
                        root.connectingToSsid = root.pendingSsid;
                        Network.connectToNetwork(root.pendingSsid, passwordField.text);
                        root.showPasswordDialog = false;
                        root.pendingSsid = "";
                        if (root.wrapper) {
                            root.wrapper.needsFocus = false;
                        }
                    }
                }
            }
        }
    }

    component Toggle: RowLayout {
        property alias checked: toggle.checked
        required property string label
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: root.margin
        spacing: root.margin

        Text.BodyM {
            Layout.fillWidth: true
            text: parent.label
        }
        Switch {
            id: toggle
        }
    }

    // Component for detail rows
    component DetailRow: RowLayout {
        required property string icon
        required property string label
        required property string value

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
            font.family: Foundations.font.family.mono
            text: parent.value
        }
    }
}
