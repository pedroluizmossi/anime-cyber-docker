// Quadros de contador do HUD (CounterTile) com flip ao mudar o valor.
// Uso: qml6 dev/preview-counters.qml -- saida.png  (gera saida.png no meio do flip e saida-end.png depois)
import QtQuick
import QtQuick.Layouts
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
    readonly property string outPath: args[args.length - 1]
    readonly property string outEnd: outPath.replace(/\.png$/, "-end.png")
    property int runCount: 2

    width: 420; height: 80; visible: true; color: th.bg1

    Item {
        id: stage
        anchors.fill: parent
        anchors.margins: 16

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 6

            CounterTile {
                label: "RUN"; value: win.runCount; accent: win.th.visor; theme: win.th
                Layout.fillWidth: true; Layout.preferredWidth: 60
            }
            CounterTile {
                label: "STOP"; value: 0; accent: win.th.sub; theme: win.th
                Layout.fillWidth: true; Layout.preferredWidth: 60
            }
            CounterTile {
                label: "ERR"; value: 1; accent: win.th.alarm; theme: win.th; pulse: true
                Layout.fillWidth: true; Layout.preferredWidth: 60
            }
            CounterTile {
                label: "CPU"; value: "23%"; accent: win.th.ok; theme: win.th
                tip: "computador 23.4%  ·  docker 1.2% (100% = 1 núcleo)"
                Layout.fillWidth: true; Layout.preferredWidth: 75
            }
            CounterTile {
                label: "RAM 11G/47G"; value: "23%"; accent: win.th.ok; theme: win.th
                Layout.fillWidth: true; Layout.preferredWidth: 96
            }
        }
    }

    Timer { interval: 300; running: true; onTriggered: win.runCount = 3 }
    Timer { interval: 420; running: true; onTriggered: stage.grabToImage(r => r.saveToFile(win.outPath)) }
    Timer { interval: 1200; running: true; onTriggered: stage.grabToImage(r => { r.saveToFile(win.outEnd); Qt.quit() }) }
}
