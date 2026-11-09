// Uma linha da lista de containers, estilo HUD.
import QtQuick
import QtQuick.Layouts
import "Themes.js" as Themes
import "Logic.js" as Logic

Rectangle {
    id: rowItem

    required property var container
    property var stat: null           // { cpu, mem, memBytes }
    property var hist: null           // { cpu: [], mem: [] }
    property real vramMiB: 0
    property bool favorite: false
    property bool showGraphs: true
    property var theme: Themes.get("neon")
    signal action(string verb)
    signal toggleFavorite()
    signal openUrl(string url)

    readonly property bool isRunning: ["running", "restarting", "paused"].includes(container.state)
    readonly property var ports: container.ports || []
    readonly property bool hasMetrics: showGraphs && container.state === "running" && !!stat
    readonly property color stateColor: container.problem ? theme.alarm
                                      : container.state === "running" ? (container.health === "healthy" ? theme.ok : theme.visor)
                                      : container.state === "paused" ? theme.warn
                                      : theme.muted
    readonly property color btnColor: theme.fur

    implicitHeight: info.implicitHeight + 14
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
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8

        ColumnLayout {
            id: info
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            // linha 1: favorito + nome + portas
            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    text: rowItem.favorite ? "★" : "☆"
                    color: rowItem.favorite ? rowItem.theme.warn : (favArea.containsMouse ? rowItem.theme.text : rowItem.theme.muted)
                    font.pixelSize: 13
                    MouseArea {
                        id: favArea
                        anchors.fill: parent; anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rowItem.toggleFavorite()
                    }
                    ToolTipLite { text: rowItem.favorite ? "desafixar" : "fixar no topo"; shown: favArea.containsMouse; accent: rowItem.theme.visor; background: rowItem.theme.bg0 }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 40
                    text: rowItem.container.name
                    color: rowItem.theme.text
                    font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 13
                    elide: Text.ElideRight
                }
                Repeater {
                    model: rowItem.ports.slice(0, 3)
                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: portLabel.implicitWidth + 8
                        implicitHeight: 15
                        radius: 2
                        color: portArea.containsMouse ? Qt.rgba(rowItem.theme.visor.r, rowItem.theme.visor.g, rowItem.theme.visor.b, 0.25) : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(rowItem.theme.visor.r, rowItem.theme.visor.g, rowItem.theme.visor.b, portArea.containsMouse ? 0.9 : 0.4)
                        Text {
                            id: portLabel
                            anchors.centerIn: parent
                            text: ":" + modelData.port + " ↗"
                            color: rowItem.theme.visor
                            font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                        }
                        MouseArea {
                            id: portArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rowItem.openUrl(modelData.url)
                        }
                        ToolTipLite { text: modelData.url; shown: portArea.containsMouse; accent: rowItem.theme.visor; background: rowItem.theme.bg0 }
                    }
                }
                Text {
                    visible: rowItem.ports.length > 3
                    text: "+" + (rowItem.ports.length - 3)
                    color: rowItem.theme.sub
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                }
            }

            // linha 2: imagem · stack
            Text {
                Layout.fillWidth: true
                text: rowItem.container.image + (rowItem.container.project ? `  ·  ${rowItem.container.project}` : "")
                color: rowItem.theme.sub
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 10
                elide: Text.ElideMiddle
            }

            // linha 3: status
            Text {
                Layout.fillWidth: true
                text: rowItem.container.status
                      + (!rowItem.hasMetrics && rowItem.stat && rowItem.isRunning ? `  ·  cpu ${rowItem.stat.cpu.toFixed(1)}%  mem ${rowItem.stat.mem}` : "")
                color: rowItem.stateColor
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 10
                elide: Text.ElideRight
            }

            // linha 4: métricas com sparklines
            RowLayout {
                visible: rowItem.hasMetrics
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 4
                Text { text: "cpu"; color: rowItem.theme.sub; font.family: "Hack Nerd Font Mono"; font.pixelSize: 9 }
                Sparkline {
                    Layout.preferredWidth: 50; Layout.preferredHeight: 13
                    values: rowItem.hist ? rowItem.hist.cpu : []
                    color: rowItem.theme.visor
                    minScale: 5
                }
                Text {
                    Layout.preferredWidth: 38
                    text: rowItem.stat ? rowItem.stat.cpu.toFixed(1) + "%" : ""
                    color: rowItem.theme.visor
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                }
                Text { text: "mem"; color: rowItem.theme.sub; font.family: "Hack Nerd Font Mono"; font.pixelSize: 9 }
                Sparkline {
                    Layout.preferredWidth: 50; Layout.preferredHeight: 13
                    values: rowItem.hist ? rowItem.hist.mem : []
                    color: rowItem.theme.fur
                    minScale: 1048576
                }
                Text {
                    Layout.preferredWidth: 34
                    text: rowItem.stat ? Logic.formatBytes(rowItem.stat.memBytes) : ""
                    color: rowItem.theme.fur
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                }
                Text {
                    visible: rowItem.vramMiB > 0
                    text: "vram " + Logic.formatMiB(rowItem.vramMiB)
                    color: rowItem.theme.warn
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                }
                Item { Layout.fillWidth: true }
            }
        }

        Repeater {
            model: rowItem.isRunning
                   ? [{ v: "logs", g: "≡", t: "logs" }, { v: "shell", g: ">_", t: "shell" }, { v: "restart", g: "↻", t: "reiniciar" }, { v: "stop", g: "■", t: "parar" }]
                   : [{ v: "logs", g: "≡", t: "logs" }, { v: "start", g: "▶", t: "iniciar" }]
            delegate: Rectangle {
                required property var modelData
                Layout.alignment: Qt.AlignVCenter
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
