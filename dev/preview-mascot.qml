// Renderiza a mascote nos 4 estados e salva um PNG (uso: qml dev/preview-mascot.qml -- saida.png)
import QtQuick
import "../package/contents/ui"

Window {
    id: win
    width: 640; height: 220; visible: true; color: "#0b0614"
    Row {
        id: row
        anchors.centerIn: parent; spacing: 40
        Repeater {
            model: ["sleep", "idle", "busy", "alarm"]
            Column {
                spacing: 8
                Mascot { width: 120; height: 120; mood: modelData }
                Text { text: modelData; color: "#00f0ff"; font.family: "Hack Nerd Font Mono"; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
    Timer {
        interval: 1200; running: true
        onTriggered: win.contentItem.grabToImage(r => { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() })
    }
}
