// Cabeçalho de uma stack do Compose no HUD: recolher/expandir + ações da stack inteira.
import QtQuick
import QtQuick.Layouts
import "Themes.js" as Themes

Rectangle {
    id: header

    property var group: ({})          // { project, total, running, problems, collapsed }
    property var theme: Themes.get("neon")
    signal toggled()
    signal stackAction(string verb)

    readonly property bool standalone: !group.project
    readonly property color accent: group.problems > 0 ? theme.alarm : group.running > 0 ? theme.visor : theme.muted

    implicitHeight: 28
    radius: 3
    color: Qt.rgba(accent.r, accent.g, accent.b, headerHover.hovered ? 0.16 : 0.08)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.35)

    HoverHandler { id: headerHover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: header.toggled()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 6

        Text {
            text: header.group.collapsed ? "▸" : "▾"
            color: header.accent
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 12; font.bold: true
        }
        Text {
            Layout.fillWidth: true
            text: header.standalone ? i18n("// no stack") : header.group.project
            color: header.standalone ? header.theme.sub : header.theme.text
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 12; font.bold: !header.standalone
            font.letterSpacing: 1
            elide: Text.ElideRight
        }
        Text {
            text: `${header.group.running}/${header.group.total}` + (header.group.problems ? `  ${header.group.problems}!` : "")
            color: header.accent
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 11; font.bold: true
        }

        Repeater {
            model: header.standalone ? [] : [
                { v: "start", g: "▶", t: i18n("start stack") },
                { v: "restart", g: "↻", t: i18n("restart stack") },
                { v: "stop", g: "■", t: i18n("stop stack") }
            ]
            delegate: Rectangle {
                required property var modelData
                width: 22; height: 20; radius: 3
                color: sb.containsMouse ? Qt.rgba(header.theme.fur.r, header.theme.fur.g, header.theme.fur.b, 0.25) : "transparent"
                border.width: 1
                border.color: sb.containsMouse ? header.theme.fur : Qt.rgba(header.theme.fur.r, header.theme.fur.g, header.theme.fur.b, 0.3)
                Text {
                    anchors.centerIn: parent
                    text: modelData.g
                    color: sb.containsMouse ? "#ffffff" : Qt.lighter(header.theme.fur, 1.3)
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 10; font.bold: true
                }
                MouseArea {
                    id: sb
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: header.stackAction(modelData.v)
                }
                ToolTipLite { text: modelData.t; shown: sb.containsMouse; accent: header.theme.visor; background: header.theme.bg0 }
            }
        }
    }
}
