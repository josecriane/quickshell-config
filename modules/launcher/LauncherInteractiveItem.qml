import qs.services
import qs.ds.text as DsText
import qs.ds.buttons as DsButtons
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.ds.animations
import qs.ds

LauncherItem {
    id: root

    property string commandPrefix: ""
    readonly property alias data: root.input
    property int elideWidth: 300
    property alias hintButton: hintButton
    property string hintIcon: "open_in_new"
    property string hintText: qsTr("Open")
    readonly property string input: visibilities.searchText.slice(commandPrefix.length)
    property bool isError: false
    required property var list
    property var onHintClicked: function () {
        return true;
    }
    property var onProcessOutput: function (output) {}
    property string placeholderText: qsTr("Type a command")
    property var processCommand: ["echo"]
    property color resultColor: {
        if (isError)
            return Foundations.palette.base08;
        if (!input)
            return Foundations.palette.base04;
        return Foundations.palette.base07;
    }
    property string resultText: metrics.elidedText

    visibilities: list.visibilities

    modelData: LauncherItemModel {
        function onActivate() {
            Quickshell.execDetached(["sh", "-c", `echo '${root.input}' | wl-copy`]);
            return true;
        }

        fontIcon: "function"
        isAction: true
        name: ""
        subtitle: ""
    }

    Component.onCompleted: {
        metrics.text = root.placeholderText;
    }
    onInputChanged: {
        if (input && processCommand.length > 0) {
            process.command = processCommand.concat([input]);
            process.running = true;
        } else if (!input) {
            process.running = false;
            metrics.text = root.placeholderText;
            root.isError = false;
        }
    }

    height: Math.max(root.list.itemHeight, contentItem.implicitHeight)

    RowLayout {
        id: contentItem

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Foundations.spacing.m

        DsText.BodyM {
            id: result

            Layout.fillWidth: true
            color: root.resultColor
            text: root.resultText
            wrapMode: Text.Wrap
            maximumLineCount: 10
        }
        DsButtons.HintButton {
            id: hintButton

            Layout.alignment: Qt.AlignVCenter
            hint: root.hintText
            icon: root.hintIcon

            onClicked: {
                const shouldClose = root.onHintClicked();
                if (shouldClose) {
                    root.list.visibilities.launcher = false;
                }
            }
        }
    }
    Process {
        id: process

        stdout: StdioCollector {
            id: stdoutCollector

            onStreamFinished: {
                const output = stdoutCollector.text.trim();
                metrics.text = output;

                root.onProcessOutput(output);
            }
        }
    }
    TextMetrics {
        id: metrics

        elide: Text.ElideRight
        elideWidth: root.elideWidth
        text: root.placeholderText
    }
}
