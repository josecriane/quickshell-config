pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // VPN connection state
    property bool connected: false
    property bool connecting: false
    property bool available: true
    property string errorMessage: ""
    property string connectionName: ""
    property string serviceName: ""

    // Connection info
    property string serverLocation: ""
    property string ipAddress: ""
    property string connectionTime: ""

    // List of available VPN connections
    property var connections: []
    property string activeConnection: ""

    // Private properties for internal state management
    property Timer statusTimer: Timer {
        interval: 5000 // Check status every 5 seconds
        running: true
        repeat: true
        onTriggered: root.refreshStatus()
    }

    // Initialize on component creation
    Component.onCompleted: {
        scanConnections();
        refreshStatus();
    }

    // Private processes
    Process {
        id: statusProcess
        command: ["systemctl", "status", root.serviceName]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text || "";
                const wasConnected = connected;

                // Parse systemctl status output
                if (output.includes("Active: active (running)")) {
                    connected = true;
                    available = true;
                    errorMessage = "";

                    // If we just connected, get additional info
                    if (!wasConnected) {
                        getConnectionInfo();
                    }
                } else if (output.includes("Active: inactive") || output.includes("inactive (dead)")) {
                    connected = false;
                    available = true;
                    errorMessage = "";
                    ipAddress = "";
                    connectionTime = "";
                } else if (output.includes("Active: failed")) {
                    connected = false;
                    available = true;
                    errorMessage = "VPN service failed";
                    ipAddress = "";
                    connectionTime = "";
                } else if (output.includes("could not be found") || output.includes("not loaded")) {
                    available = false;
                    connected = false;
                    errorMessage = "VPN service not found";
                } else {
                    // Service exists but in unknown state - still available
                    available = true;
                    connected = false;
                    errorMessage = "";
                }
            }
        }
    }

    Process {
        id: connectProcess
        command: ["systemctl", "start", root.serviceName]
        running: false

        onExited: {
            connecting = false;
            // Always check status after connect attempt
            Qt.callLater(() => refreshStatus());
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    errorMessage = "Failed to start VPN service";
                    console.error("VPN connect failed:", text);
                }
            }
        }
    }

    Process {
        id: disconnectProcess
        command: ["systemctl", "stop", root.serviceName]
        running: false

        onExited: {
            connecting = false;
            // Always check status after disconnect attempt
            Qt.callLater(() => refreshStatus());
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    errorMessage = "Failed to stop VPN service";
                    console.error("VPN disconnect failed:", text);
                }
            }
        }
    }

    Process {
        id: ipProcess
        command: ["curl", "-s", "--max-time", "3", "https://ifconfig.me"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim()) {
                    ipAddress = text.trim();
                }
            }
        }
    }

    Process {
        id: timeProcess
        command: ["systemctl", "show", root.serviceName, "--property=ActiveEnterTimestamp", "--value"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const timestamp = text.trim();
                if (timestamp && timestamp !== "n/a") {
                    connectionTime = timestamp;
                }
            }
        }
    }

    Process {
        id: scanProcess
        command: ["systemctl", "list-unit-files", "--type=service"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text || "";
                const lines = output.split('\n');
                const vpnConnections = [];

                for (const line of lines) {
                    // Look for openvpn services
                    if (line.includes('openvpn') && line.includes('.service')) {
                        const serviceName = line.split(/\s+/)[0];
                        // Extract connection name (remove openvpn- prefix and .service suffix)
                        let connectionName = serviceName.replace(/^openvpn-/, '').replace(/\.service$/, '');
                        if (connectionName === 'openvpn') connectionName = 'default';

                        // Skip non-VPN services like restart
                        if (connectionName === 'restart') continue;

                        vpnConnections.push({
                            serviceName: serviceName,
                            connectionName: connectionName,
                            displayName: connectionName.charAt(0).toUpperCase() + connectionName.slice(1)
                        });
                    }
                }

                connections = vpnConnections;
            }
        }
    }

    // Public methods
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

    // Get additional connection information when connected
    function getConnectionInfo() {
        ipProcess.running = true;
        timeProcess.running = true;
    }

    // Scan for available VPN connections
    function scanConnections() {
        if (scanProcess.running) return;
        scanProcess.running = true;
    }

    // Connect to a specific VPN service
    function connectToService(serviceName) {
        if (connecting || connected) {
            return;
        }

        // Update current service
        root.serviceName = serviceName;

        // Find the connection name from the list
        const connection = connections.find(conn => conn.serviceName === serviceName);
        if (connection) {
            connectionName = connection.connectionName;
            activeConnection = serviceName;
        }

        connect();
    }

    // Status icon name for display
    readonly property string statusIcon: {
        if (!available) return "vpn_key_off";
        if (connecting) return "sync";
        if (connected) return "vpn_key";
        return "vpn_key_off";
    }

    // Status text for display
    readonly property string statusText: {
        if (!available) return "Unavailable";
        if (connecting) return "Connecting...";
        if (connected) return "Connected";
        return "Disconnected";
    }
}
