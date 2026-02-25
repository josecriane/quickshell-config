import "."
import qs.services
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Scope {
    id: root
    IpcHandler {
        id: visibilitiesHandler

        function list(): string {
            const visibilities = Visibilities.getForActive();
            return Object.keys(visibilities).filter(k => typeof visibilities[k] === "boolean").join("\n");
        }
        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
                const visibilities = Visibilities.getForActive();
                visibilities[drawer] = !visibilities[drawer];
            } else {
                console.warn(`[IPC] Drawer "${drawer}" does not exist`);
            }
        }

        target: "drawers"
    }

    IpcHandler {
        function dismiss(id: string): void {
            const nId = parseInt(id);
            for (const n of NotificationService.notifications) {
                if (n.id === nId) {
                    n.dismiss();
                    return;
                }
            }
            console.warn(`[IPC] Notification ${id} not found`);
        }
        function dismissAll(): void {
            NotificationService.clearNotifications();
        }
        function status(): string {
            return JSON.stringify({
                count: NotificationService.notifications.length,
                dnd: NotificationService.doNotDisturb
            });
        }
        function toggleDnd(): void {
            NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
        }

        target: "notifications"
    }

    IpcHandler {
        function getVolume(): string {
            return Math.round(Audio.volume * 100).toString();
        }
        function setVolume(percent: string): void {
            const val = parseInt(percent);
            if (val >= 0 && val <= 100) {
                Audio.setVolume(val / 100.0);
            }
        }
        function status(): string {
            return JSON.stringify({
                volume: Math.round(Audio.volume * 100),
                muted: Audio.muted,
                sourceVolume: Math.round(Audio.sourceVolume * 100),
                sourceMuted: Audio.sourceMuted
            });
        }
        function toggleMute(): void {
            Audio.toggleMute();
        }

        target: "audio"
    }

    IpcHandler {
        function status(): string {
            return JSON.stringify({
                wifiEnabled: Network.wifiEnabled,
                connected: Network.hasWifiConnection,
                ssid: Network.active?.ssid ?? "",
                wifiIp: Network.wifiIp,
                ethernetIp: Network.ethernetIp,
                hasEthernet: Network.hasEthernetConnection
            });
        }
        function toggleWifi(): void {
            Network.toggleWifi();
        }

        target: "network"
    }

    IpcHandler {
        function status(): string {
            const adapter = Bluetooth.defaultAdapter;
            const devs = [];
            for (const d of Bluetooth.devices.values) {
                devs.push({
                    name: d.name,
                    connected: d.connected,
                    paired: d.paired
                });
            }
            return JSON.stringify({
                enabled: adapter?.enabled ?? false,
                discovering: adapter?.discovering ?? false,
                devices: devs
            });
        }
        function toggle(): void {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter) {
                adapter.enabled = !adapter.enabled;
            }
        }

        target: "bluetooth"
    }

    IpcHandler {
        function status(): string {
            return JSON.stringify({
                connected: VPN.connected,
                connecting: VPN.connecting,
                available: VPN.available,
                connectionName: VPN.connectionName,
                serverLocation: VPN.serverLocation,
                ipAddress: VPN.ipAddress
            });
        }
        function toggle(): void {
            VPN.toggle();
        }

        target: "vpn"
    }

    IpcHandler {
        function current(): string {
            const ws = Niri.workspaces;
            const focused = ws?.[Niri.focusedWorkspaceIndex];
            if (!focused) return "none";
            return JSON.stringify({
                id: focused.id,
                idx: focused.idx,
                name: focused.name || "",
                output: focused.output
            });
        }
        function focus(idx: string): void {
            Niri.focusWorkspace(parseInt(idx));
        }
        function list(): string {
            const ws = Niri.workspaces || [];
            return JSON.stringify(ws.map(w => ({
                id: w.id,
                idx: w.idx,
                name: w.name || "",
                output: w.output,
                focused: w.is_focused
            })));
        }

        target: "workspace"
    }
}
