// Tooltip neon simples, acima do item pai.
import QtQuick

Rectangle {
    property alias text: label.text
    property bool shown: false
    property color accent: "#00f0ff"
    property color background: "#1a0b2e"

    visible: shown
    z: 100
    anchors.bottom: parent.top
    anchors.bottomMargin: 4
    anchors.horizontalCenter: parent.horizontalCenter
    width: label.implicitWidth + 10
    height: label.implicitHeight + 4
    radius: 2
    color: background
    border.color: accent

    Text {
        id: label
        anchors.centerIn: parent
        color: accent
        font.family: "Hack Nerd Font Mono"
        font.pixelSize: 10
    }
}
