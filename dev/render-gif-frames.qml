// Captura quadros dos 4 humores animados para virar GIF.
// Uso: qml6 dev/render-gif-frames.qml -- <pasta_de_saida>
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes
import "I18nShim.js" as I18n

Window {
    id: win
    // i18n fora do Plasma (ver dev/I18nShim.js)
    function i18n(...a) { return I18n.i18n(...a) }
    function i18nc(...a) { return I18n.i18nc(...a) }
    function i18np(...a) { return I18n.i18np(...a) }
    function i18ncp(...a) { return I18n.i18ncp(...a) }
    width: 720; height: 200; visible: true; color: "#05020c"
    readonly property string outDir: Qt.application.arguments[Qt.application.arguments.length - 1]
    property int shot: 0
    readonly property int totalShots: 48

    Rectangle {
        id: stage
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#14062a" }
            GradientStop { position: 1; color: "#05020c" }
        }
        Row {
            anchors.centerIn: parent
            spacing: 44
            Repeater {
                model: [
                    { k: "hacker", t: "vaporwave", m: "sleep", l: "SLEEP · スリープ" },
                    { k: "neko", t: "neon", m: "idle", l: "IDLE · 正常" },
                    { k: "robo", t: "synthwave", m: "busy", l: "BUSY · フル稼働" },
                    { k: "kitsune", t: "akira", m: "alarm", l: "ALARM · 警告" }
                ]
                Column {
                    required property var modelData
                    spacing: 10
                    Mascot {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 128; height: 112
                        kind: modelData.k; mood: modelData.m
                        theme: Themes.get(modelData.t)
                        glowLevel: 100
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.l
                        color: Themes.get(modelData.t).visor
                        font.family: "Noto Sans Mono CJK JP"; font.pixelSize: 13; font.bold: true
                    }
                }
            }
        }
    }

    Timer {
        interval: 80; running: true; repeat: true
        onTriggered: {
            const n = String(win.shot).padStart(3, "0")
            stage.grabToImage(r => r.saveToFile(`${win.outDir}/f${n}.png`))
            win.shot++
            if (win.shot >= win.totalShots) { stop(); quitSoon.start() }
        }
    }
    Timer { id: quitSoon; interval: 400; onTriggered: Qt.quit() }
}
