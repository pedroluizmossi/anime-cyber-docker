// Banner do README. Uso: qml6 dev/render-hero.qml -- saida.png
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
    width: 1280; height: 440; visible: true; color: "#05020c"

    Rectangle {
        id: stage
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1d0838" }
            GradientStop { position: 0.62; color: "#0b0318" }
            GradientStop { position: 1.0; color: "#05020c" }
        }

        // sol synthwave
        Rectangle {
            width: 300; height: 300; radius: 150
            x: parent.width - 360; y: 40
            opacity: 0.22
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ff2bd6" }
                GradientStop { position: 1.0; color: "#ff8a00" }
            }
        }

        // chão em perspectiva
        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                const hz = height * 0.66
                ctx.strokeStyle = "rgba(0,240,255,0.22)"
                ctx.lineWidth = 1
                for (let i = -24; i <= 24; i++) {
                    ctx.beginPath()
                    ctx.moveTo(width / 2 + i * 14, hz)
                    ctx.lineTo(width / 2 + i * 140, height)
                    ctx.stroke()
                }
                for (let k = 0; k < 9; k++) {
                    const y = hz + Math.pow(k / 8, 2) * (height - hz)
                    ctx.strokeStyle = `rgba(255,43,214,${0.10 + k * 0.03})`
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                }
                // scanlines
                ctx.fillStyle = "rgba(255,255,255,0.035)"
                for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
            }
        }

        // título com aberração cromática
        Item {
            x: 64; y: 54
            width: title.implicitWidth; height: title.implicitHeight
            Text { x: 4; text: title.text; font: title.font; color: "#00f0ff"; opacity: 0.75 }
            Text { x: -4; text: title.text; font: title.font; color: "#ff2bd6"; opacity: 0.75 }
            Text { id: title; text: "CYBERDOCK"; color: "#ffffff"; font.family: "Hack Nerd Font Mono"; font.bold: true; font.pixelSize: 84; font.letterSpacing: 8 }
        }
        Text {
            x: 70; y: 160
            text: "コンテナ監視ネコ  //  neon companion para o Docker"
            color: "#c9b8ff"
            font.family: "Noto Sans Mono CJK JP"; font.pixelSize: 22
        }
        Text {
            x: 70; y: 196
            text: "> plasmoid KDE Plasma 6 · 11 mascotes · 6 temas · zero GPU extra_"
            color: "#00f0ff"
            font.family: "Hack Nerd Font Mono"; font.pixelSize: 17
        }

        // desfile de mascotes
        Row {
            x: 70; y: 262
            spacing: 34
            Repeater {
                model: [
                    { k: "neko", t: "neon", m: "idle" },
                    { k: "robo", t: "synthwave", m: "busy" },
                    { k: "kitsune", t: "akira", m: "idle" },
                    { k: "usagi", t: "vaporwave", m: "idle" },
                    { k: "yurei", t: "ghost", m: "sleep" },
                    { k: "hacker", t: "matrix", m: "idle" }
                ]
                Mascot {
                    required property var modelData
                    width: 128; height: 112
                    kind: modelData.k
                    mood: modelData.m
                    theme: Themes.get(modelData.t)
                    glowLevel: 100
                }
            }
        }
    }

    Timer {
        interval: 1400; running: true
        onTriggered: stage.grabToImage(r => { r.saveToFile(Qt.application.arguments[Qt.application.arguments.length - 1]); Qt.quit() })
    }
}
