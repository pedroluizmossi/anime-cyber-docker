// Cabeçalho do HUD: mascote principal (interativa), título com glitch, humor e, no modo largo, os contadores.
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: header
    property Item hud
    spacing: 12

    // humor: linha em japonês (decorativa, não traduzida) + linha de status traduzida
    readonly property var moodJp: ({ sleep: "スリープ", idle: "システム正常", busy: "フル稼働", happy: "やったー!", alarm: "警告" })
    readonly property string moodLine: {
        switch (hud.mood) {
        case "sleep": return i18n("no active containers... zzz")
        case "busy": return i18n("high load on the neural net")
        case "happy": return i18n("everything back to normal")
        case "alarm": return hud.dockerOk ? i18np("%1 container with problems", "%1 containers with problems", hud.problems)
                                          : i18n("docker offline")
        }
        return i18n("all systems online")
    }

    Mascot {
        mood: header.hud.mood
        kind: header.hud.kind
        theme: header.hud.theme
        glowLevel: header.hud.glowLevel
        animated: header.hud.animating
        interactive: true            // clique = carinho, clique duplo = dancinha
        Layout.preferredWidth: 84
        Layout.preferredHeight: 74
    }
    ColumnLayout {
        spacing: 0
        Layout.fillWidth: true
        Item {
            // some enquanto a mascote fala (o balão ocupa este lugar)
            opacity: header.hud.bubbleOn ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }
            implicitWidth: title.implicitWidth
            implicitHeight: title.implicitHeight
            // aberração cromática do título
            Text { x: glitch.offset; text: title.text; font: title.font; color: header.hud.theme.visor; opacity: 0.7 }
            Text { x: -glitch.offset; text: title.text; font: title.font; color: header.hud.theme.fur; opacity: 0.7 }
            Text {
                id: title
                // digitado durante a abertura
                text: "CYBERDOCK".slice(0, Math.ceil(Math.min(1, header.hud.bootT / 0.6) * 9)) + (header.hud.bootT < 0.6 ? "▌" : "")
                color: "#ffffff"
                font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 24; font.letterSpacing: 3
            }
            QtObject { id: glitch; property real offset: 1 }
            SequentialAnimation {
                running: header.hud.animating; loops: Animation.Infinite
                PauseAnimation { duration: header.hud.mood === "alarm" ? 300 : 2600 }
                NumberAnimation { target: glitch; property: "offset"; to: 4; duration: 60 }
                NumberAnimation { target: glitch; property: "offset"; to: -3; duration: 60 }
                NumberAnimation { target: glitch; property: "offset"; to: 1; duration: 80 }
            }
        }
        Text {
            text: header.moodJp[header.hud.mood] || ""
            color: header.hud.neon
            font.family: "Noto Sans Mono CJK JP"; font.pixelSize: 13; font.bold: true
        }
        Text {
            text: "> " + header.moodLine + (cursor.visible ? "_" : " ")
            color: Qt.lighter(header.hud.theme.sub, 1.3)
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 11
            Timer { id: cursor; property bool visible: true; interval: 500; running: header.hud.active; repeat: true; onTriggered: visible = !visible }
        }
    }
    Item { Layout.fillWidth: true; visible: header.hud.sideBySide }
    StatsBar {
        hud: header.hud
        visible: header.hud.sideBySide
        Layout.preferredWidth: 250
        Layout.maximumWidth: 250
        Layout.alignment: Qt.AlignVCenter
    }
}
