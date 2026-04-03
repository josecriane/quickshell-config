pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    property bool connecting: false
    property bool available: true
    property string errorMessage: ""

    property string tailscaleIp: ""
    property string hostname: ""
    property string backendState: ""
    property string relay: ""

    Component.onCompleted: {
        refreshStatus();
    }

    // Status check (on-demand, no polling)
    Process {
        id: statusProcess
        command: ["tailscale", "status", "--json"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text || "";
                try {
                    const data = JSON.parse(output);
                    backendState = data.BackendState || "";
                    connected = backendState === "Running";
                    available = true;

                    if (data.Self) {
                        hostname = data.Self.HostName || "";
                        const ips = data.Self.TailscaleIPs || [];
                        tailscaleIp = ips.length > 0 ? ips[0] : "";
                        relay = data.Self.Relay || "";
                    }

                    connecting = false;
                    errorMessage = "";
                } catch (e) {
                    available = false;
                    connected = false;
                    connecting = false;
                    errorMessage = "Failed to parse tailscale status";
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    available = false;
                    connected = false;
                    connecting = false;
                    errorMessage = "Tailscale not available";
                }
            }
        }
    }

    Process {
        id: connectProcess
        command: ["pkexec", "sh", "-c", "tailscale up --accept-routes"]
        running: false

        onExited: {
            connecting = false;
            Qt.callLater(() => refreshStatus());
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    errorMessage = "Failed to start Tailscale";
                    console.error("Tailscale connect failed:", text);
                }
            }
        }
    }

    Process {
        id: disconnectProcess
        command: ["pkexec", "sh", "-c", "tailscale down"]
        running: false

        onExited: {
            connecting = false;
            Qt.callLater(() => refreshStatus());
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    errorMessage = "Failed to stop Tailscale";
                    console.error("Tailscale disconnect failed:", text);
                }
            }
        }
    }

    function connect() {
        if (connecting || connected) return;
        connecting = true;
        errorMessage = "";
        connectProcess.running = true;
    }

    function disconnect() {
        if (connecting || !connected) return;
        connecting = true;
        errorMessage = "";
        disconnectProcess.running = true;
    }

    function toggle() {
        if (connected) {
            disconnect();
        } else {
            connect();
        }
    }

    function refreshStatus() {
        if (statusProcess.running) return;
        statusProcess.running = true;
    }

    readonly property string statusIcon: {
        if (!available) return "vpn_key_off";
        if (connecting) return "sync";
        if (connected) return "vpn_key";
        return "vpn_key_off";
    }

    readonly property string statusText: {
        if (!available) return "Unavailable";
        if (connecting) return "Connecting...";
        if (connected) return "Connected";
        return "Disconnected";
    }
}
