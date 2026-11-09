// Gera o ícone usado nas notificações. Uso: qml6 dev/render-icon.qml -- saida.png
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
    width: 128; height: 128; visible: true; color: "transparent"
    Item {
        id: stage
        width: 128; height: 128
        Mascot { anchors.centerIn: parent; width: 112; height: 98; kind: "neko"; mood: "idle"; theme: Themes.get("neon"); glowLevel: 90; animated: false }
    }
    Timer { interval: 1200; running: true; onTriggered: stage.grabToImage(r => { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() }) }
}
