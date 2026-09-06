import qs.modules.launcher
import qs.services.search
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Search {
    id: root

    required property string prefix

    readonly property string encryptedPasswordPath: ConfigsJson.keepass.encryptedPasswordPath
    readonly property string ageIdentityPath: ConfigsJson.keepass.ageIdentityPath
    readonly property string dbPath: ConfigsJson.keepass.databasePath

    readonly property string otpPrefix: prefix + "o"
    readonly property string usernamePrefix: prefix + "u"
    property string mode: "password"

    function modeFor(search: string): string {
        if (search === otpPrefix || search.startsWith(otpPrefix + " "))
            return "otp";
        if (search === usernamePrefix || search.startsWith(usernamePrefix + " "))
            return "username";
        return "password";
    }

    function stripPrefix(search: string, used: string): string {
        const rest = search.slice(used.length);
        return rest.startsWith(" ") ? rest.slice(1) : rest;
    }

    function search(search: string): list<var> {
        mode = modeFor(search);
        const isBare = search === prefix || search === otpPrefix || search === usernamePrefix;
        if (isBare && encryptedPasswordPath && ageIdentityPath && dbPath) {
            loadEntries();
        }
        const results = query(search);
        if (mode === "otp") {
            return results.filter(item => item.hasOtp);
        }
        if (mode === "username") {
            return results.filter(item => item.entryUsername);
        }
        return results;
    }

    function transformSearch(search: string): string {
        if (mode === "otp") {
            return stripPrefix(search, otpPrefix);
        }
        if (mode === "username") {
            return stripPrefix(search, usernamePrefix);
        }
        return search.slice(prefix.length);
    }

    list: variants.instances

    onEncryptedPasswordPathChanged: {
        if (encryptedPasswordPath && ageIdentityPath && dbPath) {
            loadEntries();
        }
    }

    onAgeIdentityPathChanged: {
        if (encryptedPasswordPath && ageIdentityPath && dbPath) {
            loadEntries();
        }
    }

    onDbPathChanged: {
        if (encryptedPasswordPath && ageIdentityPath && dbPath) {
            loadEntries();
        }
    }

    function loadEntries() {
        entriesProcess.command = ["bash", "-c", `keepassxc-cli export -q -f csv "${dbPath}" < <(age -d -i "${ageIdentityPath}" "${encryptedPasswordPath}") | awk -F'","' 'NR>1 && $2 != "" { group=$1; title=$2; user=$3; totp=$7; gsub(/^"/, "", group); sub(/^\\//, "", group); sub(/^Root\\/?/, "", group); if (group != "" && group !~ /\\/$/) group = group "\\/"; print group title "\t" user "\t" (totp != "" ? "1" : "0") }'`];
        entriesProcess.running = true;
    }

    property var entryList: []

    Process {
        id: entriesProcess

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(line => line.length > 0);
                root.entryList = lines;
            }
        }
    }

    Variants {
        id: variants

        model: entryList

        delegate: LauncherItemModel {
            required property var modelData

            readonly property string entryName: modelData.split('\t')[0]
            readonly property string entryUsername: modelData.split('\t')[1] || ""
            readonly property bool hasOtp: modelData.split('\t')[2] === "1"

            function onActivate() {
                if (root.mode === "username") {
                    Quickshell.execDetached(["wl-copy", "--", entryUsername]);
                } else if (root.mode === "otp") {
                    Quickshell.execDetached(["bash", "-c", `SECRET=$(keepassxc-cli show -t -q "${root.dbPath}" "${entryName}" < <(age -d -i "${root.ageIdentityPath}" "${root.encryptedPasswordPath}") | tr -d '\\n'); printf '%s' "$SECRET" | wl-copy; (sleep 15 && [[ "$(wl-paste -n 2>/dev/null)" == "$SECRET" ]] && wl-copy "") &`]);
                } else {
                    Quickshell.execDetached(["bash", "-c", `SECRET=$(keepassxc-cli show -q -a password "${root.dbPath}" "${entryName}" < <(age -d -i "${root.ageIdentityPath}" "${root.encryptedPasswordPath}") | tr -d '\\n'); printf '%s' "$SECRET" | wl-copy; (sleep 15 && [[ "$(wl-paste -n 2>/dev/null)" == "$SECRET" ]] && wl-copy "") &`]);
                }
                return true;
            }

            autocompleteText: ""
            fontIcon: root.mode === "otp" ? "timer" : (root.mode === "username" ? "person" : "key")
            isAction: true
            name: entryName
            subtitle: {
                if (root.mode === "otp")
                    return "OTP code";
                if (root.mode === "username")
                    return entryUsername;
                return entryUsername || "Password entry";
            }
        }
    }
}
