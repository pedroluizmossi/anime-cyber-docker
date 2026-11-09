// Renderiza a visão do painel em tamanho real (32px). Uso: qml6 dev/preview-panel.qml -- saida.png
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
    width: 360; height: 40; visible: true; color: "#1b1e24"
    Row {
        x: 6; y: 4; spacing: 18
        Repeater {
            model: ["sleep", "idle", "busy", "alarm"]
            CompactView { height: 32; width: implicitWidth; mood: modelData; running: 2; total: 2; problems: modelData === "alarm" ? 1 : 0 }
        }
    }
    Timer { interval: 1200; running: true; onTriggered: win.contentItem.grabToImage(r => { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() }) }
}
