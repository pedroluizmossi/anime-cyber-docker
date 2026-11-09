// Busca + botões de filtro do HUD.
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: sb
    property Item hud
    spacing: 6

    Rectangle {
        Layout.fillWidth: true
        height: 26; radius: 3
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: searchInput.activeFocus ? sb.hud.theme.visor : Qt.rgba(sb.hud.theme.visor.r, sb.hud.theme.visor.g, sb.hud.theme.visor.b, 0.3)
        Text {
            id: searchIcon
            anchors.left: parent.left; anchors.leftMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            text: "⌕"
            color: sb.hud.theme.sub
            font.pixelSize: 14
        }
        TextInput {
            id: searchInput
            anchors.left: searchIcon.right; anchors.leftMargin: 6
            anchors.right: clearSearch.left; anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            color: sb.hud.theme.text
            selectionColor: sb.hud.theme.fur
            selectedTextColor: "#ffffff"
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 11
            clip: true
            text: sb.hud.search
            onTextChanged: sb.hud.search = text
            Keys.onEscapePressed: text = ""
            Text {
                visible: !searchInput.text && !searchInput.activeFocus
                text: i18n("filter by name, image or stack…")
                color: sb.hud.theme.muted
                font: searchInput.font
            }
        }
        Text {
            id: clearSearch
            visible: searchInput.text.length > 0
            anchors.right: parent.right; anchors.rightMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            color: clearArea.containsMouse ? sb.hud.theme.fur : sb.hud.theme.sub
            font.pixelSize: 11
            MouseArea { id: clearArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: searchInput.text = "" }
        }
    }

    Repeater {
        model: [
            { key: "hideStopped", on: sb.hud.hideStopped, g: "◌", t: i18n("hide stopped") },
            { key: "groupStacks", on: sb.hud.groupStacks, g: "▤", t: i18n("group by stack") },
            { key: "showGraphs", on: sb.hud.showGraphs, g: "∿", t: i18n("cpu/mem graphs") },
            { key: "showVitals", on: sb.hud.showVitals, g: "▥", t: i18n("vital signs column") }
        ]
        delegate: Rectangle {
            required property var modelData
            width: 28; height: 26; radius: 3
            color: modelData.on ? Qt.rgba(sb.hud.theme.visor.r, sb.hud.theme.visor.g, sb.hud.theme.visor.b, 0.22)
                                : (chipArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
            border.width: 1
            border.color: modelData.on ? sb.hud.theme.visor : Qt.rgba(sb.hud.theme.visor.r, sb.hud.theme.visor.g, sb.hud.theme.visor.b, 0.3)
            Text {
                anchors.centerIn: parent
                text: modelData.g
                color: modelData.on ? sb.hud.theme.visor : sb.hud.theme.sub
                font.pixelSize: 14; font.bold: true
            }
            MouseArea {
                id: chipArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sb.hud.setOption(modelData.key, !modelData.on)
            }
            ToolTipLite { text: modelData.t; shown: chipArea.containsMouse; accent: sb.hud.theme.visor; background: sb.hud.theme.bg0 }
        }
    }
}
