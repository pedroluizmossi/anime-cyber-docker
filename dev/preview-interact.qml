// Interações: olhar para o lado, carinho (pet) e dança. Uso: qml6 dev/preview-interact.qml -- <saida.png>
// Linha de cima: as interações (olhar, carinho, dança) a ~500 ms. Linha de baixo: referência neutra.
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
    readonly property var args: Qt.application.arguments
    readonly property var th: Themes.get("neon")
    width: 4 * 64 + 3 * 28 + 40; height: 2 * 56 + 28 + 20
    visible: true
    color: th.bg1

    Component.onCompleted: {
        pet.pet()
        dance.dance()
    }

    Row {
        x: 20; y: 10; spacing: 28
        Mascot { width: 64; height: 56; kind: "neko"; lookX: -1; theme: win.th }
        Mascot { width: 64; height: 56; kind: "chip"; lookX: 1; theme: win.th }
        Mascot { id: pet; width: 64; height: 56; kind: "sapo"; theme: win.th }
        Mascot { id: dance; width: 64; height: 56; kind: "nvidia"; theme: win.th }
    }
    Row {
        x: 20; y: 10 + 56 + 28; spacing: 28
        Mascot { width: 64; height: 56; kind: "neko"; theme: win.th }
        Mascot { width: 64; height: 56; kind: "chip"; theme: win.th }
        Mascot { width: 64; height: 56; kind: "sapo"; theme: win.th }
        Mascot { width: 64; height: 56; kind: "nvidia"; theme: win.th }
    }

    Timer {
        interval: 500; running: true
        onTriggered: win.contentItem.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() })
    }
}
