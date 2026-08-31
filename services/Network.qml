pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking as Net
import QtQuick

Singleton {
    id: root

    readonly property var devices: Net.Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === Net.DeviceType.Wifi) ?? null
    readonly property var ethernetDevice: devices.find(d => d.type === Net.DeviceType.Wired) ?? null

    readonly property bool wifiEnabled: Net.Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Net.Networking.wifiHardwareEnabled

    readonly property var networks: wifiDevice?.networks.values ?? []
    readonly property var active: networks.find(n => n.connected) ?? null

    readonly property bool hasWifiConnection: wifiDevice?.connected ?? false
    readonly property bool hasEthernetConnection: ethernetDevice?.connected ?? false

    property int scanRefCount: 0
    readonly property bool scanning: wifiDevice?.scannerEnabled ?? false

    property var ipsByInterface: ({})
    readonly property string wifiIp: wifiDevice ? (ipsByInterface[wifiDevice.name] ?? "") : ""
    readonly property string ethernetIp: ethernetDevice ? (ipsByInterface[ethernetDevice.name] ?? "") : ""

    function enableWifi(enabled: bool): void {
        Net.Networking.wifiEnabled = enabled;
    }
    function toggleWifi(): void {
        Net.Networking.wifiEnabled = !Net.Networking.wifiEnabled;
    }

    function acquireScanner(): void {
        root.scanRefCount++;
    }
    function releaseScanner(): void {
        if (root.scanRefCount > 0)
            root.scanRefCount--;
    }

    function refreshIps(): void {
        ipDebounce.restart();
    }

    onWifiDeviceChanged: root.refreshIps()
    onEthernetDeviceChanged: root.refreshIps()

    Binding {
        property: "scannerEnabled"
        target: root.wifiDevice
        value: root.scanRefCount > 0
        when: root.wifiDevice !== null
    }

    Connections {
        function onStateChanged(): void {
            root.refreshIps();
        }

        ignoreUnknownSignals: true
        target: root.wifiDevice
    }
    Connections {
        function onStateChanged(): void {
            root.refreshIps();
        }

        ignoreUnknownSignals: true
        target: root.ethernetDevice
    }

    Timer {
        id: ipDebounce

        interval: 500

        onTriggered: {
            ipProc.running = false;
            ipProc.running = true;
        }
    }
    Process {
        id: ipProc

        command: ["ip", "-j", "-4", "addr", "show"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const byName = {};
                try {
                    for (const iface of JSON.parse(text || "[]")) {
                        const addr = iface.addr_info?.find(a => a.family === "inet");
                        if (addr?.local)
                            byName[iface.ifname] = addr.local;
                    }
                } catch (e) {
                    console.warn("Network: could not parse `ip` output:", e);
                    return;
                }
                root.ipsByInterface = byName;
            }
        }
    }
}
