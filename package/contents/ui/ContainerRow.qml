// Uma linha da lista de containers, estilo HUD.
import QtQuick
import QtQuick.Layouts
import "Themes.js" as Themes

Rectangle {
    id: rowItem

    required property var container
    property var stat: null
    property var theme: Themes.get("neon")
    signal action(string verb)

    readonly property bool isRunning: ["running", "restarting", "paused"].includes(container.state)
    readonly property color stateColor: container.problem ? theme.alarm
                                      : container.state === "running" ? (container.health === "healthy" ? theme.ok : theme.visor)
                                      : container.state === "paused" ? theme.warn
                                      : theme.muted
    readonly property color btnColor: theme.fur

    height: 58
    radius: 3
    color: hover.hovered ? Qt.rgba(stateColor.r, stateColor.g, stateColor.b, 0.10) : Qt.rgba(1, 1, 1, 0.025)
    border.width: 1
    border.color: Qt.rgba(stateColor.r, stateColor.g, stateColor.b, hover.hovered ? 0.8 : 0.35)

    HoverHandler { id: hover }

    // barra lateral neon
    Rectangle {
        width: 3; height: parent.height - 10
        anchors.left: parent.left; anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        color: rowItem.stateColor
        SequentialAnimation on opacity {
            running: rowItem.isRunning || rowItem.container.problem
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: rowItem.container.problem ? 250 : 1400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: rowItem.container.problem ? 250 : 1400; easing.type: Easing.InOutSine }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 8
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: rowItem.container.name
                color: rowItem.theme.text
                font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: rowItem.container.image + (rowItem.container.project ? `  ·  ${rowItem.container.project}` : "")
                color: rowItem.theme.sub
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 10
                elide: Text.ElideMiddle
            }
            Text {
                Layout.fillWidth: true
                text: rowItem.container.status
                      + (rowItem.stat && rowItem.isRunning ? `  ·  cpu ${rowItem.stat.cpu.toFixed(1)}%  mem ${rowItem.stat.mem}` : "")
                color: rowItem.stateColor
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: rowItem.isRunning
                   ? [{ v: "logs", g: "≡", t: "logs" }, { v: "shell", g: ">_", t: "shell" }, { v: "restart", g: "↻", t: "reiniciar" }, { v: "stop", g: "■", t: "parar" }]
                   : [{ v: "logs", g: "≡", t: "logs" }, { v: "start", g: "▶", t: "iniciar" }]
            delegate: Rectangle {
                required property var modelData
                width: 26; height: 26; radius: 3
                color: btn.containsMouse ? Qt.rgba(rowItem.btnColor.r, rowItem.btnColor.g, rowItem.btnColor.b, 0.25) : "transparent"
                border.width: 1
                border.color: btn.containsMouse ? rowItem.btnColor : Qt.rgba(rowItem.btnColor.r, rowItem.btnColor.g, rowItem.btnColor.b, 0.3)
                Text {
                    anchors.centerIn: parent
                    text: modelData.g
                    color: btn.containsMouse ? "#ffffff" : Qt.lighter(rowItem.btnColor, 1.3)
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 12; font.bold: true
                }
                MouseArea {
                    id: btn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rowItem.action(modelData.v)
                }
                ToolTipLite { text: modelData.t; shown: btn.containsMouse; accent: rowItem.theme.visor; background: rowItem.theme.bg0 }
            }
        }
    }
}
