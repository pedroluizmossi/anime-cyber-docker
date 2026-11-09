// Abre a página de Aparência fora do Plasma. Uso: qml6 dev/preview-config.qml -- <tema> saida.png
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "../package/contents/ui"

Window {
    id: win
    width: 720; height: 520; visible: true; color: palette.window
    readonly property var args: Qt.application.arguments
    Loader {
        anchors.fill: parent
        source: "../package/contents/ui/configAppearance.qml"
        onStatusChanged: if (status === Loader.Error) console.log("ERRO ao carregar configAppearance")
        onLoaded: {
            item.cfg_theme = win.args[win.args.length - 2]
            item.cfg_mascot = "hacker"
            item.cfg_customFur = "#ff2bd6"; item.cfg_customVisor = "#00f0ff"
            item.cfg_iconScale = 100; item.cfg_showCounter = true; item.cfg_glowLevel = 75; item.cfg_animations = true
        }
    }
    Timer {
        interval: 1500; running: true
        onTriggered: {
            const ok = win.contentItem.grabToImage(r => { r.saveToFile(win.args[win.args.length - 1]); Qt.quit() })
            if (!ok) { console.log("grab falhou"); Qt.quit() }
        }
    }
    Timer { interval: 6000; running: true; onTriggered: Qt.quit() }
}
