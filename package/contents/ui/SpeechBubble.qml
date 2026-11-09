// Balão de fala da mascote principal: comenta o último evento por alguns segundos.
import QtQuick

Rectangle {
    id: bubble
    property Item hud
    property real maxW: 300

    readonly property var ev: hud.lastEvent
    readonly property color tone: !ev ? hud.theme.visor
        : (ev.kind === "recovered" || ev.kind === "docker-up") ? hud.theme.ok
        : ev.kind === "restart-bump" ? hud.theme.warn : hud.theme.alarm

    function speech(e) {
        if (!e) return ""
        switch (e.kind) {
        case "crash": return "💥 " + i18n("%1 crashed! (exit code %2)", e.name, e.exitCode)
        case "restarting": return "🔁 " + i18n("%1 keeps restarting…", e.name)
        case "unhealthy": return "🩺 " + i18n("%1 is not feeling well", e.name)
        case "recovered": return "✨ " + i18n("%1 is back!", e.name)
        case "restart-bump": return "↻ " + i18n("%1 restarted on its own", e.name)
        case "docker-down": return "🔌 " + i18n("where did docker go?!")
        case "docker-up": return "✨ " + i18n("docker is back!")
        }
        return ""
    }

    width: Math.min(bubbleText.implicitWidth + 16, maxW)
    height: bubbleText.implicitHeight + 10
    radius: 6
    color: hud.theme.bg0
    border.width: 1
    border.color: tone
    opacity: hud.bubbleOn ? 1 : 0
    scale: hud.bubbleOn ? 1 : 0.6
    visible: opacity > 0
    transformOrigin: Item.Left
    Behavior on opacity { NumberAnimation { duration: 180 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

    // rabicho apontando para a mascote
    Rectangle {
        width: 8; height: 8
        rotation: 45
        x: -4; y: parent.height / 2 - 4
        color: bubble.hud.theme.bg0
        border.width: 1
        border.color: bubble.tone
        z: -1
    }
    Rectangle { x: 0; y: parent.height / 2 - 5; width: 2; height: 10; color: bubble.hud.theme.bg0 }   // esconde a borda do rabicho por dentro
    Text {
        id: bubbleText
        anchors.centerIn: parent
        width: Math.min(implicitWidth, bubble.maxW - 16)
        text: bubble.speech(bubble.ev)
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: bubble.tone
        font.family: "Hack Nerd Font Mono"; font.pixelSize: 11; font.bold: true
    }
    MouseArea { anchors.fill: parent; onClicked: bubble.hud.bubbleOn = false }
}
