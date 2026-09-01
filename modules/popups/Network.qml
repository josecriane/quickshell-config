pragma ComponentBehavior: Bound

import qs.services
import qs.ds
import qs.services as Services
import qs.ds.buttons as Buttons
import qs.ds.list as Lists
import qs.ds.text as Text
import qs.ds.icons as Icons
import Quickshell
import Quickshell.Networking as Net
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var wrapper

    property var connectingTo: null
    property var pendingNetwork: null
    property bool showPasswordDialog: false

    readonly property string pendingSsid: pendingNetwork?.name ?? ""

    property int margin: Foundations.spacing.xxs

    spacing: margin
    width: Math.max(320, implicitWidth)

    Component.onCompleted: Network.acquireScanner()
    Component.onDestruction: Network.releaseScanner()

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
                if (a.connected !== b.connected)
                    return b.connected - a.connected;
                return b.signalStrength - a.signalStrength;
            }).slice(0, 8)
        }

        Lists.ListItem {
            readonly property bool isConnecting: root.connectingTo === modelData || modelData.stateChanging
            required property Net.WifiNetwork modelData

            disabled: !Network.wifiEnabled
            leftIcon: Services.IconsService.getNetworkIcon(modelData.signalStrength)
            primaryActionActive: modelData.connected
            primaryActionLoading: isConnecting
            primaryFontIcon: modelData.connected ? "link_off" : "link"
            secondaryIcon: modelData.security === Net.WifiSecurityType.Open ? "" : "lock"
            selected: modelData.connected
            text: modelData.name

            onPrimaryActionClicked: {
                if (modelData.connected) {
                    modelData.disconnect();
                } else {
                    root.connectingTo = modelData;
                    root.pendingNetwork = modelData;
                    modelData.connect();
                }
            }
        }
    }

    Connections {
        function onConnectionFailed(reason: int): void {
            if (root.connectingTo !== root.pendingNetwork)
                return;

            root.connectingTo = null;
            if (reason === Net.ConnectionFailReason.NoSecrets)
                root.showPasswordDialog = true;
            else
                root.pendingNetwork = null;
        }

        ignoreUnknownSignals: true
        target: root.pendingNetwork
    }

    // Reset connecting state when network changes
    Connections {
        function onActiveChanged(): void {
            if (Network.active && root.connectingTo === Network.active) {
                root.connectingTo = null;
                root.pendingNetwork = null;
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
                    interval: 16
                    repeat: true
                    triggeredOnStart: true

                    onTriggered: {
                        if (!root.showPasswordDialog) {
                            stop();
                            return;
                        }
                        if (passwordField.visible) {
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
                        root.pendingNetwork = null;
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
                        root.connectingTo = root.pendingNetwork;
                        root.pendingNetwork.connectWithPsk(passwordField.text);
                        root.showPasswordDialog = false;
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
