import QtQuick

QtObject {
    property string appIcon: ""
    property string autocompleteText: ""
    property string fontIcon: ""
    property bool isAction: false
    property bool isApp: false
    property string name: ""
    property var onActivate: null    // Function to execute when clicked - returns true to close launcher, false to keep open
    property var onDelete: null      // Function to execute on Shift+Delete, for entries that can be removed
    property var originalData: null  // Store original DesktopEntry or Action
    property string subtitle: ""
}
