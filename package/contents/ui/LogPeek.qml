// Prévia das últimas linhas de log (hover no botão ≡ de um container), posicionada junto ao botão.
import QtQuick

Rectangle {
    id: peek
    property Item hud

    readonly property Item anchorItem: hud.peekAnchor
    readonly property var entry: hud.logsPeek[hud.peekName]
    readonly property var lines: entry ? entry.text.split("\n") : [i18n("loading…")]
    readonly property point p: anchorItem ? anchorItem.mapToItem(hud, 0, 0) : Qt.point(0, 0)
    readonly property real aw: anchorItem ? anchorItem.width : 0
    readonly property real ah: anchorItem ? anchorItem.height : 0

    visible: hud.peekName !== "" && anchorItem !== null
    width: Math.min(hud.width - 24, 470)
    height: peekCol.implicitHeight + 12
    x: Math.max(12, Math.min(p.x + aw - width, hud.width - 12 - width))
    y: p.y + ah + 4 + height > hud.height - 8 ? p.y - height - 4 : p.y + ah + 4
    radius: 3
    color: Qt.rgba(hud.theme.bg1.r, hud.theme.bg1.g, hud.theme.bg1.b, 0.97)
    border.width: 1
    border.color: hud.theme.visor

    Column {
        id: peekCol
        x: 8; y: 6
        width: parent.width - 16
        spacing: 1
        Text {
            text: i18n("// logs · %1  (click to open)", peek.hud.peekName)
            color: peek.hud.theme.visor
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
        }
        Repeater {
            model: peek.lines
            Text {
                required property string modelData
                width: peekCol.width
                text: modelData || " "
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: /error|fatal|panic|exception/i.test(modelData) ? peek.hud.theme.alarm
                     : /warn/i.test(modelData) ? peek.hud.theme.warn : peek.hud.theme.text
                font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
            }
        }
    }
}
