// Galeria: cada tema nos 4 humores + visão do painel (32px). Uso: qml6 dev/preview-themes.qml -- saida.png
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes

Window {
    id: win
    width: 760; height: col.implicitHeight + 20; visible: true; color: "#000000"
    Column {
        id: col
        x: 10; y: 10; spacing: 6
        Repeater {
            model: ["neon", "matrix", "synthwave", "vaporwave", "akira", "ghost"]
            Rectangle {
                id: band
                required property string modelData
                readonly property var th: Themes.get(modelData)
                width: 740; height: 72; radius: 4
                gradient: Gradient { GradientStop { position: 0; color: band.th.bg0 } GradientStop { position: 1; color: band.th.bg1 } }
                border.color: band.th.visor
                Text { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 150; text: band.th.label; color: band.th.text; font.family: "Hack Nerd Font Mono"; font.pixelSize: 11; wrapMode: Text.Wrap }
                Row {
                    x: 170; anchors.verticalCenter: parent.verticalCenter; spacing: 22
                    Repeater {
                        model: ["sleep", "idle", "busy", "alarm"]
                        Mascot { required property string modelData; width: 64; height: 56; mood: modelData; theme: band.th }
                    }
                    Rectangle {
                        width: 110; height: 32; color: "#1b1e24"; anchors.verticalCenter: parent.verticalCenter
                        CompactView { height: 32; width: implicitWidth; mood: "idle"; running: 2; total: 2; theme: band.th }
                    }
                }
            }
        }
    }
    Timer { interval: 1300; running: true; onTriggered: win.contentItem.grabToImage(r => { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() }) }
}
