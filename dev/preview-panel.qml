// Renderiza a visão do painel em tamanho real (32px). Uso: qml6 dev/preview-panel.qml -- saida.png
import QtQuick
import "../package/contents/ui"

Window {
    id: win
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
