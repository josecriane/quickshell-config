pragma ComponentBehavior: Bound

import qs.services
import qs.services as Services
import qs.ds
import qs.ds.text as Text
import qs.ds.icons
import qs.ds.buttons
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.ds.animations

Rectangle {
    id: root

    property color colour: Foundations.palette.base0D
    readonly property alias items: iconRow
    readonly property int margin: Foundations.spacing.s
    readonly property int iconSpacing: Foundations.spacing.xxs

    clip: true
    color: Foundations.palette.base02
    implicitHeight: height
    implicitWidth: iconRow.implicitWidth + margin * 2
    radius: Foundations.radius.all

    Behavior on implicitWidth {
        BasicNumberAnimation {
            duration: Foundations.duration.slow
        }
    }

    RowLayout {
        id: iconRow

        anchors.centerIn: parent
        spacing: iconSpacing

        // Audio icon
        WrappedLoader {
            name: "audio"

            sourceComponent: RowLayout {
                spacing: iconSpacing

                MaterialFontIcon {
                    animate: true
                    color: root.colour
                    text: "screen_record"
                    visible: ScreenShare.isSharing
                }

                MaterialFontIcon {
                    animate: true
                    color: root.colour
                    text: "mic_off"
                    visible: Audio.sourceMuted
                }

                IconButton {
                    buttonColor: "transparent"
                    focusColor: "transparent"
                    iconColor: root.colour
                    icon: Services.IconsService.getVolumeIcon(Audio.volume, Audio.muted)
                    buttonSize: Foundations.font.size.xl
                    iconPointSize: Foundations.font.size.m

                    onClicked: {
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }
        }

        // Keyboard layout icon
        WrappedLoader {
            name: "kblayout"

            sourceComponent: ClickableIcon {
                onClicked: {
                    const nextIndex = (Niri.currentKbLayoutIndex + 1) % Niri.kbLayouts.length;
                    Niri.switchKbLayout(nextIndex);
                }

                Text.BodyM {
                    color: root.colour
                    font.family: Foundations.font.family.mono
                    text: {
                        const fullName = Niri.currentKbLayoutName();
                        if (!fullName)
                            return "??";

                        if (fullName.includes("Spanish"))
                            return "ES";
                        if (fullName.includes("English"))
                            return "US";

                        return "??";
                    }
                }
            }
        }

        // Network icon
        WrappedLoader {
            name: "network"

            sourceComponent: ClickableIcon {
                onClicked: Network.toggleWifi()

                MaterialFontIcon {
                    animate: true
                    color: root.colour
                    text: {
                        if (Network.hasEthernetConnection)
                            return "lan";
                        if (Network.active)
                            return Services.IconsService.getNetworkIcon(Network.active.strength ?? 0);
                        return "wifi_off";
                    }
                }
            }
        }

        // VPN icon
        WrappedLoader {
            name: "vpn"

            sourceComponent: ClickableIcon {
                onClicked: VPN.toggle()

                Item {
                    implicitWidth: vpnIcon.implicitWidth
                    implicitHeight: vpnIcon.implicitHeight

                    MaterialFontIcon {
                        id: vpnIcon
                        animate: true
                        color: {
                            if (!VPN.available) return Foundations.palette.base08;
                            if (VPN.connecting) return Foundations.palette.base0A;
                            if (VPN.connected) return Foundations.palette.base0B;
                            return root.colour;
                        }
                        text: VPN.statusIcon

                        Behavior on color {
                            BasicColorAnimation { }
                        }
                    }

                    // Subtle pulsing animation for connecting state
                    SequentialAnimation on opacity {
                        running: VPN.connecting
                        loops: Animation.Infinite
                        BasicNumberAnimation { from: 1.0; to: 0.4; duration: Foundations.duration.slow }
                        BasicNumberAnimation { from: 0.4; to: 1.0; duration: Foundations.duration.slow }
                    }

                    // Small progress dot indicator
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: -2
                        anchors.topMargin: -2
                        width: 6
                        height: 6
                        radius: 3
                        color: Foundations.palette.base0D
                        visible: VPN.connecting

                        SequentialAnimation on scale {
                            running: VPN.connecting
                            loops: Animation.Infinite
                            BasicNumberAnimation { from: 1.0; to: 1.4; duration: Foundations.duration.standard }
                            BasicNumberAnimation { from: 1.4; to: 1.0; duration: Foundations.duration.standard }
                        }
                    }
                }
            }
        }

        // Bluetooth section
        WrappedLoader {
            name: "bluetooth"

            sourceComponent: RowLayout {
                spacing: iconSpacing

                // Bluetooth icon (clickable to toggle)
                ClickableIcon {
                    onClicked: {
                        if (Bluetooth.defaultAdapter) {
                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                        }
                    }

                    MaterialFontIcon {
                        animate: true
                        color: root.colour
                        text: {
                            if (!Bluetooth.defaultAdapter?.enabled)
                                return "bluetooth_disabled";
                            if (Bluetooth.devices.values.some(d => d.connected))
                                return "bluetooth_connected";
                            return "bluetooth";
                        }
                    }
                }

                // Connected bluetooth devices
                Repeater {
                    model: ScriptModel {
                        values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected)
                    }

                    MaterialFontIcon {
                        id: device

                        required property BluetoothDevice modelData

                        animate: true
                        color: root.colour
                        text: Services.IconsService.getBluetoothIcon(modelData.icon)

                        SequentialAnimation on opacity {
                            alwaysRunToEnd: true
                            loops: Animation.Infinite
                            running: device.modelData.state !== BluetoothDeviceState.Connected

                            BasicNumberAnimation {
                                duration: Foundations.duration.slow
                                from: 1
                                to: 0
                            }
                            BasicNumberAnimation {
                                duration: Foundations.duration.slow
                                from: 0
                                to: 1
                            }
                        }
                    }
                }
            }
        }

        // Battery icon
        WrappedLoader {
            name: "battery"

            sourceComponent: ClickableIcon {
                onClicked: Quickshell.execDetached(["gnome-power-statistics"])

                MaterialFontIcon {
                    animate: true
                    color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Foundations.palette.base08
                    text: {
                        if (!UPower.displayDevice.isLaptopBattery) {
                            if (PowerProfiles.profile === PowerProfile.PowerSaver)
                                return "energy_savings_leaf";
                            if (PowerProfiles.profile === PowerProfile.Performance)
                                return "rocket_launch";
                            return "balance";
                        }

                        const perc = UPower.displayDevice.percentage;
                        const charging = !UPower.onBattery;
                        if (perc === 1)
                            return charging ? "battery_charging_full" : "battery_full";
                        let level = Math.floor(perc * 7);
                        if (charging && (level === 4 || level === 1))
                            level--;
                        return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                    }
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property string name

        Layout.alignment: Qt.AlignVCenter
        // asynchronous: true
        visible: active
    }

    component ClickableIcon: Rectangle {
        id: clickableIcon

        signal clicked()

        default property alias content: contentContainer.children

        implicitWidth: contentContainer.childrenRect.width
        implicitHeight: contentContainer.childrenRect.height
        color: "transparent"
        radius: Foundations.radius.s

        Item {
            id: contentContainer
            anchors.centerIn: parent
            width: childrenRect.width
            height: childrenRect.height
        }

        InteractiveArea {
            function onClicked(): void {
                clickableIcon.clicked();
            }

            radius: clickableIcon.radius
        }
    }
}
