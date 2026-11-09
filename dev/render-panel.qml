// Faixa de painel KDE com a mascote em várias combinações. Uso: qml6 dev/render-panel.qml -- saida.png
import QtQuick
import "../package/contents/ui"
import "../package/contents/ui/Themes.js" as Themes

Window {
    id: win
    width: 340; height: 4 * 36 + 3 * 4; visible: true; color: "#0d0f12"

    Rectangle {
      id: stage
      width: win.width; height: win.height
      color: "#0d0f12"
      Column {
        spacing: 4
        Repeater {
            model: [
                { k: "neko", t: "neon", m: "idle", r: 4, n: 5, p: 0 },
                { k: "robo", t: "synthwave", m: "busy", r: 5, n: 5, p: 0 },
                { k: "hacker", t: "vaporwave", m: "sleep", r: 0, n: 3, p: 0 },
                { k: "kitsune", t: "akira", m: "alarm", r: 3, n: 5, p: 1 }
            ]
            Rectangle {
                required property var modelData
                width: 340; height: 36
                color: "#1b1e24"
                Row {
                    anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    CompactView {
                        height: 32; width: implicitWidth
                        anchors.verticalCenter: parent.verticalCenter
                        kind: modelData.k; mood: modelData.m; theme: Themes.get(modelData.t)
                        running: modelData.r; total: modelData.n; problems: modelData.p
                    }
                    Repeater {
                        model: ["\uf1eb", "\uf293", "\uf028", "\uf0f3"]   // wifi, bluetooth, volume, sino (Nerd Font)
                        Text { text: modelData; color: "#e6e6e6"; font.family: "Hack Nerd Font Mono"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "01:17"; color: "#e6e6e6"; font.pixelSize: 13; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "09/11/2026"; color: "#bdbdbd"; font.pixelSize: 10 }
                    }
                }
            }
        }
    }

    }

    Timer { interval: 1400; running: true; onTriggered: stage.grabToImage(r => { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() }) }
}
