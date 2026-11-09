// Prévia do VitalCard: normal (coluna esquerda) x compacto (direita).
// Uso: qml6 dev/preview-vitalcard.qml -- [--anim] saida.png
// Sem --anim tudo é estático (grab determinístico); com --anim as animações rodam.
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
    readonly property string outPath: args[args.length - 1]
    readonly property bool anim: args.indexOf("--anim") >= 0
    readonly property var th: Themes.get("neon")
    width: 580; height: 640; visible: true; color: th.bg0

    function wave(n, base, amp, phase) {
        const out = []
        for (let i = 0; i < n; i++) out.push(Math.max(0, Math.min(100, base + amp * Math.sin(i / 4 + phase) + amp * 0.4 * Math.sin(i * 1.7 + phase))))
        return out
    }

    Item {
        id: root
        anchors.fill: parent

        Row {
            x: 16; y: 16
            spacing: 20

            // coluna 1: modo normal
            Column {
                width: 250
                spacing: 10
                VitalCard {
                    width: 250
                    compact: false
                    label: "CPU"; kind: "chip"; value: 64; warnAt: 60; alarmAt: 85; temp: 72
                    series: win.wave(60, 45, 25, 0); bars: [{ k: "uso", v: 64 }]
                    detail: "docker 3.2%  ·  ▲ postgres"
                    theme: win.th; animated: win.anim
                }
                VitalCard {
                    width: 250
                    compact: false
                    label: "RAM"; kind: "sapo"; value: 88; warnAt: 75; alarmAt: 90
                    series: win.wave(60, 60, 20, 1); bars: [{ k: "mem", v: 88, part: 30 }]
                    detail: "14.1GiB / 16GiB  ·  docker 4.8GiB"
                    theme: win.th; animated: win.anim
                }
                VitalCard {
                    width: 250
                    compact: false
                    label: "GPU NVIDIA"; kind: "nvidia"; value: 71; warnAt: 40; alarmAt: 90; temp: 84; tempHot: 80; tempCritical: 90
                    series: win.wave(60, 50, 30, 2); bars: [{ k: "core", v: 71 }, { k: "vram", v: 17, part: 13 }]
                    detail: "VRAM 1.4GiB / 8GiB  ·  ▲ llama-swap"
                    theme: win.th; animated: win.anim
                    // slot extra: um filho declarado dentro do cartão
                    Text {
                        text: "extra: slot funciona"
                        color: "#ffd84a"
                        font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                    }
                }
            }

            // coluna 2: modo compacto (mesmos dados)
            Column {
                width: 250
                spacing: 10
                VitalCard {
                    width: 250
                    compact: true
                    label: "CPU"; kind: "chip"; value: 64; warnAt: 60; alarmAt: 85; temp: 72
                    series: win.wave(60, 45, 25, 0); bars: [{ k: "uso", v: 64 }]
                    detail: "docker 3.2%  ·  ▲ postgres"
                    theme: win.th; animated: win.anim
                }
                VitalCard {
                    width: 250
                    compact: true
                    label: "RAM"; kind: "sapo"; value: 88; warnAt: 75; alarmAt: 90
                    series: win.wave(60, 60, 20, 1); bars: [{ k: "mem", v: 88, part: 30 }]
                    detail: "14.1GiB / 16GiB  ·  docker 4.8GiB"
                    theme: win.th; animated: win.anim
                }
                VitalCard {
                    width: 250
                    compact: true
                    label: "GPU NVIDIA"; kind: "nvidia"; value: 71; warnAt: 40; alarmAt: 90; temp: 84; tempHot: 80; tempCritical: 90
                    series: win.wave(60, 50, 30, 2); bars: [{ k: "core", v: 71 }, { k: "vram", v: 17, part: 13 }]
                    detail: "VRAM 1.4GiB / 8GiB  ·  ▲ llama-swap"
                    theme: win.th; animated: win.anim
                    Text {
                        text: "extra: slot funciona"
                        color: "#ffd84a"
                        font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                    }
                }
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: {
            root.grabToImage(function (result) {
                result.saveToFile(win.outPath)
                Qt.quit()
            })
        }
    }

}
