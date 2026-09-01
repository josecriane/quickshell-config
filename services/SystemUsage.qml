pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string autoGpuType: "NONE"
    property real cpuPerc
    property real cpuTemp
    property string cpuTempPath
    property real gpuPerc
    property real gpuTemp
    property string gpuTempPath
    readonly property string gpuType: autoGpuType
    property real lastCpuIdle
    property real lastCpuTotal
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property real memTotal
    property real memUsed
    // Incremented by views that display GPU stats. Nothing in the bar uses
    // them, so while this is 0 the GPU is not sampled at all.
    property int refCount
    property real storagePerc: storageTotal > 0 ? storageUsed / storageTotal : 0
    property real storageTotal
    property real storageUsed

    function formatKib(kib: real): var {
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

        if (kib >= tib)
            return {
                value: kib / tib,
                unit: "TiB"
            };
        if (kib >= gib)
            return {
                value: kib / gib,
                unit: "GiB"
            };
        if (kib >= mib)
            return {
                value: kib / mib,
                unit: "MiB"
            };
        return {
            value: kib,
            unit: "KiB"
        };
    }

    function refreshGpu(): void {
        if (root.refCount <= 0)
            return;

        gpuUsage.running = true;
        if (root.gpuTempPath)
            gpuTempFile.reload();
    }

    onRefCountChanged: refreshGpu()

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root.cpuTempPath)
                cpuTempFile.reload();
            root.refreshGpu();
        }
    }
    // Storage barely moves, and unlike the rest it costs a process to read.
    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: storage.running = true
    }
    FileView {
        id: stat

        path: "/proc/stat"

        onLoaded: {
            const data = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (data) {
                const stats = data.slice(1).map(n => parseInt(n, 10));
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3] + (stats[4] ?? 0);

                const totalDiff = total - root.lastCpuTotal;
                const idleDiff = idle - root.lastCpuIdle;
                root.cpuPerc = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;

                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }
        }
    }
    FileView {
        id: meminfo

        path: "/proc/meminfo"

        onLoaded: {
            const data = text();
            root.memTotal = parseInt(data.match(/MemTotal: *(\d+)/)[1], 10) || 1;
            root.memUsed = (root.memTotal - parseInt(data.match(/MemAvailable: *(\d+)/)[1], 10)) || 0;
        }
    }
    // hwmon numbering is not stable across boots, so the sensor files are
    // located once at startup. The shell only globs; the picking is done here.
    Process {
        id: hwmonProbe

        command: ["sh", "-c", 'for d in /sys/class/hwmon/hwmon*; do n=$(cat "$d/name" 2>/dev/null) || continue; for t in "$d"/temp*_input; do [ -e "$t" ] || continue; echo "$n|$(cat "${t%_input}_label" 2>/dev/null)|$t"; done; done']
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = text.trim().split("\n").filter(l => l !== "").map(l => {
                    const [name, label, path] = l.split("|");
                    return {
                        name,
                        label,
                        path
                    };
                });

                // First hwmon matching a known driver, preferring a known label
                const pick = (drivers, labels) => {
                    for (const label of labels) {
                        const hit = rows.find(r => drivers.includes(r.name) && r.label === label);
                        if (hit)
                            return hit.path;
                    }
                    return rows.find(r => drivers.includes(r.name))?.path ?? "";
                };

                root.cpuTempPath = pick(["k10temp", "zenpower", "coretemp"], ["Tdie", "Package id 0", "Tctl"]);
                root.gpuTempPath = pick(["amdgpu", "radeon", "i915", "xe"], ["edge", "junction"]);
            }
        }
    }
    FileView {
        id: cpuTempFile

        path: root.cpuTempPath

        onLoaded: root.cpuTemp = parseInt(text(), 10) / 1000
    }
    FileView {
        id: gpuTempFile

        path: root.gpuTempPath

        onLoaded: root.gpuTemp = parseInt(text(), 10) / 1000
    }
    Process {
        id: storage

        // -P guarantees one line per filesystem, -k guarantees 1 KiB blocks.
        // Filtering here instead of through a pipeline saves three processes.
        command: ["df", "-P", "-k"]

        stdout: StdioCollector {
            onStreamFinished: {
                const deviceMap = new Map();

                for (const line of text.trim().split("\n")) {
                    if (!line.startsWith("/dev/"))
                        continue;

                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 4) {
                        const device = parts[0];
                        const used = parseInt(parts[2], 10) || 0;
                        const avail = parseInt(parts[3], 10) || 0;

                        // Only keep the entry with the largest total space for each device
                        if (!deviceMap.has(device) || (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
                            deviceMap.set(device, {
                                used: used,
                                avail: avail
                            });
                        }
                    }
                }

                let totalUsed = 0;
                let totalAvail = 0;

                for (const [device, stats] of deviceMap) {
                    totalUsed += stats.used;
                    totalAvail += stats.avail;
                }

                root.storageUsed = totalUsed;
                root.storageTotal = totalUsed + totalAvail;
            }
        }
    }
    Process {
        id: gpuTypeCheck

        command: ["sh", "-c", "if command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null; then echo NVIDIA; elif ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | grep -q .; then echo GENERIC; else echo NONE; fi"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.autoGpuType = text.trim()
        }
    }
    Process {
        id: gpuUsage

        command: root.gpuType === "GENERIC" ? ["sh", "-c", "cat /sys/class/drm/card*/device/gpu_busy_percent"] : root.gpuType === "NVIDIA" ? ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"] : ["echo"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.gpuType === "GENERIC") {
                    const percs = text.trim().split("\n");
                    const sum = percs.reduce((acc, d) => acc + parseInt(d, 10), 0);
                    root.gpuPerc = sum / percs.length / 100;
                } else if (root.gpuType === "NVIDIA") {
                    const [usage, temp] = text.trim().split(",");
                    root.gpuPerc = parseInt(usage, 10) / 100;
                    root.gpuTemp = parseInt(temp, 10);
                } else {
                    root.gpuPerc = 0;
                    root.gpuTemp = 0;
                }
            }
        }
    }
}
