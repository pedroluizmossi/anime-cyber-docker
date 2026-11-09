// Galeria: cada mascote nos 4 humores + painel (32px). Uso: qml6 dev/preview-mascots.qml -- <tema> saida.png
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes
import "../package/contents/ui/Sprites.js" as Sprites

Window {
    id: win
    readonly property var args: Qt.application.arguments
    readonly property var th: Themes.get(args[args.length - 2])
    width: 700; height: col.implicitHeight + 20; visible: true; color: th.bg1
    Column {
        id: col
        x: 10; y: 10; spacing: 6
        Repeater {
            model: Sprites.list()
            Rectangle {
                id: band
                required property var modelData
                width: 680; height: 72; radius: 4
                gradient: Gradient { GradientStop { position: 0; color: win.th.bg0 } GradientStop { position: 1; color: win.th.bg1 } }
                border.color: Qt.rgba(win.th.visor.r, win.th.visor.g, win.th.visor.b, 0.4)
                Text { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 130; text: band.modelData.label; color: win.th.text; font.family: "Hack Nerd Font Mono"; font.pixelSize: 11; wrapMode: Text.Wrap }
                Row {
                    x: 150; anchors.verticalCenter: parent.verticalCenter; spacing: 22
                    Repeater {
                        model: ["sleep", "idle", "busy", "alarm"]
                        Mascot { required property string modelData; width: 64; height: 56; mood: modelData; kind: band.modelData.key; theme: win.th }
                    }
                    Rectangle {
                        width: 90; height: 32; color: "#1b1e24"; anchors.verticalCenter: parent.verticalCenter
                        CompactView { height: 32; width: implicitWidth; mood: "idle"; kind: band.modelData.key; running: 2; total: 2; theme: win.th }
                    }
                }
            }
        }
    }
    Timer { interval: 1300; running: true; onTriggered: win.contentItem.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() }) }
}
