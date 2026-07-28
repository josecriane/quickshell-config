import "."
import qs.services
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Scope {
    id: root

    // Drawer visibility controls
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

    // Notification controls
    IpcHandler {
        function dismiss(id: string): string {
            const notifId = parseInt(id);
            const notification = NotificationService.notifications.find(n => n.id === notifId);
            if (notification) {
                notification.dismiss();
                return "dismissed";
            }
            return "not found";
        }
        function dismissAll(): string {
            NotificationService.clearNotifications();
            return "all dismissed";
        }
        function toggleDnd(): string {
            NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
            return NotificationService.doNotDisturb ? "enabled" : "disabled";
        }
        function status(): string {
            return `count: ${NotificationService.notifications.length}, dnd: ${NotificationService.doNotDisturb}`;
        }

        target: "notifications"
    }

    // Audio controls
    IpcHandler {
        function toggleMute(): string {
            Audio.muted = !Audio.muted;
            return Audio.muted ? "muted" : "unmuted";
        }
        function setVolume(percent: string): string {
            const vol = parseFloat(percent) / 100;
            if (vol >= 0 && vol <= 1) {
                Audio.volume = vol;
                return `volume set to ${Math.round(vol * 100)}%`;
            }
            return "invalid volume (0-100)";
        }
        function getVolume(): string {
            return `${Math.round(Audio.volume * 100)}%`;
        }
        function status(): string {
            return `volume: ${Math.round(Audio.volume * 100)}%, muted: ${Audio.muted}`;
        }

        target: "audio"
    }

    // Network controls
    IpcHandler {
        function toggleWifi(): string {
            Network.toggleWifi();
            return "toggled";
        }
        function status(): string {
            if (Network.hasEthernetConnection) return "ethernet";
            if (Network.active) return `wifi: ${Network.active.ssid} (${Network.active.strength}%)`;
            return "disconnected";
        }

        target: "network"
    }

    // Bluetooth controls
    IpcHandler {
        function toggle(): string {
            if (Bluetooth.defaultAdapter) {
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                return Bluetooth.defaultAdapter.enabled ? "enabled" : "disabled";
            }
            return "no adapter";
        }
        function status(): string {
            if (!Bluetooth.defaultAdapter) return "no adapter";
            const enabled = Bluetooth.defaultAdapter.enabled;
            const connected = Bluetooth.devices.values.filter(d => d.connected).length;
            return `enabled: ${enabled}, connected devices: ${connected}`;
        }

        target: "bluetooth"
    }

    // VPN controls
    IpcHandler {
        function toggle(): string {
            VPN.toggle();
            return VPN.connected ? "disconnecting" : "connecting";
        }
        function status(): string {
            if (!VPN.available) return "unavailable";
            if (VPN.connecting) return "connecting";
            if (VPN.connected) return `connected (${VPN.connectionName})`;
            return "disconnected";
        }

        target: "vpn"
    }

    // Workspace controls
    IpcHandler {
        function focus(id: string): string {
            const workspaceId = parseInt(id);
            Mango.focusWorkspace(workspaceId);
            return `focusing workspace ${workspaceId}`;
        }
        function list(): string {
            return Mango.workspaces.map(w => `${w.id}: ${w.name || 'unnamed'} (${w.output})`).join("\n");
        }
        function current(): string {
            const ws = Mango.workspaces[Mango.focusedWorkspaceIndex];
            return ws ? `${ws.id}: ${ws.name || 'unnamed'}` : "unknown";
        }

        target: "workspace"
    }
}
