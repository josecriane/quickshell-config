pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int currentKbLayoutIndex: 0
    property string focusedOutput: ""
    property int focusedWorkspaceIndex: 0
    property bool inOverview: false
    property list<string> kbLayouts: []
    property list<var> workspaces: []

    // Function to get current layout name
    function currentKbLayoutName(): string {
        if (root.currentKbLayoutIndex >= 0 && root.currentKbLayoutIndex < root.kbLayouts.length) {
            return root.kbLayouts[root.currentKbLayoutIndex];
        }
        return "";
    }

    function getWindowByAppId(appId: string, callback: var, titleHint: string): void {
        const hint = titleHint || "";
        getWindowIdProcess.running = false;
        getWindowIdProcess.targetAppId = appId.toLowerCase();
        getWindowIdProcess.titleHint = hint.toLowerCase();
        getWindowIdProcess.resultCallback = callback;
        getWindowIdProcess.running = true;
    }

    function focusWindowById(windowId: int): void {
        focusWindowProcess.command = ["niri", "msg", "action", "focus-window", "--id", windowId.toString()];
        focusWindowProcess.running = false;
        focusWindowProcess.running = true;
    }

    function spawn(command: string): void {
        spawnProcess.command = ["niri", "msg", "action", "spawn", "--"].concat(command.split(" "));
        spawnProcess.running = false;
        spawnProcess.running = true;
    }

    function switchKbLayout(index: int): void {
        switchLayoutProcess.command = ["niri", "msg", "action", "switch-layout", index.toString()];
        switchLayoutProcess.running = false;
        switchLayoutProcess.running = true;
    }

    function focusWorkspace(workspaceId: int): void {
        focusWorkspaceProcess.command = ["niri", "msg", "action", "focus-workspace", workspaceId.toString()];
        focusWorkspaceProcess.running = false;
        focusWorkspaceProcess.running = true;
    }

    function updateFocusedOutput(): void {
        focusedOutputProcess.running = false;
        focusedOutputProcess.running = true;
    }

    Component.onCompleted: {
        layoutsInitProcess.running = true;
        updateFocusedOutput();
    }

    Process {
        command: ["niri", "msg", "-j", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const event = JSON.parse(data.trim());

                if (event.WorkspacesChanged) {
                    root.workspaces = [...event.WorkspacesChanged.workspaces].sort((a, b) => a.idx - b.idx);
                    root.focusedWorkspaceIndex = root.workspaces.findIndex(w => w.is_focused);
                    if (root.focusedWorkspaceIndex < 0) {
                        root.focusedWorkspaceIndex = 0;
                    }
                } else if (event.WorkspaceActivated) {
                    root.focusedWorkspaceIndex = root.workspaces.findIndex(w => w.id === event.WorkspaceActivated.id);
                    if (root.focusedWorkspaceIndex < 0) {
                        root.focusedWorkspaceIndex = 0;
                    }
                } else if (event.OverviewOpenedOrClosed) {
                    root.inOverview = event.OverviewOpenedOrClosed.is_open;
                } else if (event.KeyboardLayoutsChanged) {
                    root.kbLayouts = [];
                    root.currentKbLayoutIndex = -1;

                    const layouts = event.KeyboardLayoutsChanged.keyboard_layouts;
                    if (layouts && layouts.names) {
                        root.kbLayouts = layouts.names;
                        root.currentKbLayoutIndex = layouts.current_idx || 0;
                    }
                } else if (event.KeyboardLayoutSwitched) {
                    root.currentKbLayoutIndex = event.KeyboardLayoutSwitched.idx;
                }

                if (event.WorkspaceActivated || event.WindowFocusChanged || event.WindowOpenedOrClosed) {
                    root.updateFocusedOutput();
                }
            }
        }
    }

    Process {
        id: switchLayoutProcess

        running: false
    }

    Process {
        id: focusWorkspaceProcess

        running: false
    }

    Process {
        id: layoutsInitProcess

        command: ["niri", "msg", "-j", "keyboard-layouts"]
        running: false

        onStdoutChanged: {
            try {
                const data = JSON.parse(stdout.trim());
                if (data.names) {
                    root.kbLayouts = data.names;
                    root.currentKbLayoutIndex = data.current_idx || 0;
                }
            } catch (e) {
                console.log("Error parsing keyboard layouts:", e);
            }
        }
    }
    Process {
        id: spawnProcess

        running: false
    }

    Process {
        id: focusedOutputProcess

        command: ["niri", "msg", "focused-output"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const firstLine = text.split("\n")[0];
                const match = firstLine.match(/\(([^)]+)\)/);
                if (match) {
                    root.focusedOutput = match[1];
                }
            }
        }
    }

    Process {
        id: getWindowIdProcess

        property string targetAppId
        property string titleHint
        property var resultCallback

        command: ["niri", "msg", "-j", "windows"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const windows = JSON.parse(text.trim());
                    const knownBrowsers = ["chromium-browser", "chromium", "google-chrome", "google-chrome-stable", "firefox", "firefox-esr"];
                    const isBrowser = knownBrowsers.includes(getWindowIdProcess.targetAppId);

                    // Strategy 1: For browser notifications with titleHint,
                    // try to find the specific PWA window first.
                    if (isBrowser && getWindowIdProcess.titleHint && getWindowIdProcess.titleHint.length > 0) {
                        const hint = getWindowIdProcess.titleHint;

                        for (let i = 0; i < windows.length; i++) {
                            const window = windows[i];
                            const windowAppId = (window.app_id || "").toLowerCase();
                            if (windowAppId.startsWith("chrome-") && windowAppId.includes(hint)) {
                                getWindowIdProcess.resultCallback(window);
                                return;
                            }
                        }

                        const hintWords = hint.split(/\s+/).filter(w => w.length > 2);
                        for (let i = 0; i < windows.length; i++) {
                            const window = windows[i];
                            const windowAppId = (window.app_id || "").toLowerCase();
                            if (windowAppId.startsWith("chrome-") && windowAppId !== getWindowIdProcess.targetAppId) {
                                const matches = hintWords.filter(w => windowAppId.includes(w)).length;
                                if (matches > 0) {
                                    getWindowIdProcess.resultCallback(window);
                                    return;
                                }
                            }
                        }

                        // Check window titles for appName
                        for (let i = 0; i < windows.length; i++) {
                            const window = windows[i];
                            const windowTitle = (window.title || "").toLowerCase();
                            if (windowTitle.includes(getWindowIdProcess.titleHint)) {
                                getWindowIdProcess.resultCallback(window);
                                return;
                            }
                        }
                    }

                    // Strategy 2: Exact app_id match
                    for (let i = 0; i < windows.length; i++) {
                        const window = windows[i];
                        const windowAppId = (window.app_id || "").toLowerCase();
                        if (windowAppId === getWindowIdProcess.targetAppId) {
                            getWindowIdProcess.resultCallback(window);
                            return;
                        }
                    }

                    // Strategy 3: Title-based fallback for non-browser apps
                    if (getWindowIdProcess.titleHint && getWindowIdProcess.titleHint.length > 0) {
                        for (let i = 0; i < windows.length; i++) {
                            const window = windows[i];
                            const windowTitle = (window.title || "").toLowerCase();
                            if (windowTitle.includes(getWindowIdProcess.titleHint)) {
                                getWindowIdProcess.resultCallback(window);
                                return;
                            }
                        }
                    }

                    getWindowIdProcess.resultCallback(null);
                } catch (e) {
                    console.log("Error parsing windows JSON:", e);
                    getWindowIdProcess.resultCallback(null);
                }
            }
        }
    }

    Process {
        id: focusWindowProcess

        running: false
    }
}
