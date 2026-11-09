// Galeria dos fundos: ThemeBackdrop + Skyline em 6 temas. Uso: qml6 dev/preview-backdrop.qml -- saida.png
pragma ComponentBehavior: Bound
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
    readonly property var keys: ["neon", "matrix", "synthwave", "vaporwave", "akira", "ghost"]
    readonly property var moods: ["idle", "busy", "alarm", "sleep", "happy", "idle"]
    width: 3 * 300 + 4 * 10; height: 2 * 220 + 3 * 10; visible: true; color: "#000000"

    Grid {
        x: 10; y: 10; columns: 3; spacing: 10
        Repeater {
            model: win.keys
            Item {
                id: tile
                required property var modelData
                required property int index
                readonly property var th: Themes.get(modelData)
                width: 300; height: 220

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: tile.th.bg0 }
                        GradientStop { position: 1.0; color: tile.th.bg1 }
                    }
                }
                ThemeBackdrop {
                    anchors.fill: parent
                    opacity: 0.3
                    themeKey: tile.modelData
                    theme: tile.th
                }
                Skyline {
                    anchors.fill: parent
                    theme: tile.th
                    mood: win.moods[tile.index]
                    load: 20 + tile.index * 14
                }
                // linhas de exemplo por cima, para checar legibilidade
                Column {
                    x: 12; y: 12; spacing: 6
                    Text { text: tile.th.label; color: tile.th.text; font.family: "Hack Nerd Font Mono"; font.pixelSize: 11 }
                    Text { text: "nginx-proxy   running"; color: tile.th.visor; font.family: "Hack Nerd Font Mono"; font.pixelSize: 11 }
                    Text { text: "postgres-1     healthy"; color: tile.th.ok; font.family: "Hack Nerd Font Mono"; font.pixelSize: 11 }
                    Text { text: "worker-3       " + win.moods[tile.index]; color: tile.th.sub; font.family: "Hack Nerd Font Mono"; font.pixelSize: 11 }
                }
            }
        }
    }
    Timer { interval: 1500; running: true; onTriggered: win.contentItem.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() }) }
}
