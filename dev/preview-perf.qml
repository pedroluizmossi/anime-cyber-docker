// Conta redesenhos da sprite em 10 s por humor (antes da otimização: 1 por quadro).
// Uso: qml6 dev/preview-perf.qml
import QtQuick
import "../package/contents/ui"
import "I18nShim.js" as I18n

Window {
    id: win
    // i18n fora do Plasma (ver dev/I18nShim.js)
    function i18n(...a) { return I18n.i18n(...a) }
    function i18nc(...a) { return I18n.i18nc(...a) }
    function i18np(...a) { return I18n.i18np(...a) }
    function i18ncp(...a) { return I18n.i18ncp(...a) }
    width: 400; height: 60; visible: true; color: "#000"
    readonly property var moods: ["sleep", "idle", "busy", "alarm"]
    Row {
        Repeater {
            id: rep
            model: win.moods
            Mascot { required property string modelData; width: 37; height: 32; mood: modelData; kind: "hacker" }
        }
    }
    Timer {
        interval: 10000; running: true
        onTriggered: {
            for (let i = 0; i < rep.count; i++) {
                const m = rep.itemAt(i)
                const ticks = Math.round(10000 / ({ sleep: 250, idle: 200, busy: 120, alarm: 80 })[m.mood])
                const oldTicks = Math.round(10000 / ({ sleep: 150, idle: 150, busy: 90, alarm: 70 })[m.mood])
                console.info(`${m.mood.padEnd(5)}  redesenhos: ${String(m.paintCount).padStart(3)} em ${ticks} quadros   (antes: ~${oldTicks} redesenhos da sprite + ${oldTicks} do glow)`)
            }
            Qt.quit()
        }
    }
}
