// Gera o ícone usado nas notificações. Uso: qml6 dev/render-icon.qml -- saida.png
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes

Window {
    id: win
    width: 128; height: 128; visible: true; color: "transparent"
    Item {
        id: stage
        width: 128; height: 128
        Mascot { anchors.centerIn: parent; width: 112; height: 98; kind: "neko"; mood: "idle"; theme: Themes.get("neon"); glowLevel: 90; animated: false }
    }
    Timer { interval: 1200; running: true; onTriggered: stage.grabToImage(r => { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() }) }
}
