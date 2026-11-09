// Coluna de sinais vitais: CPU, RAM, GPU e disco/rede, uma mascote por recurso.
// Rola se não couber; cartões ficam compactos quando falta altura.
import QtQuick
import QtQuick.Layouts
import "Logic.js" as Logic

ColumnLayout {
    id: col
    property Item hud
    spacing: 8

    // cartões compactos quando os quatro não cabem na altura disponível (~570 px no modo normal)
    readonly property bool compactCards: vflick.height > 0 && vflick.height < 570
    // no alarme (ou quando a principal fala) todas olham para ela, à esquerda
    readonly property int look: hud.mood === "alarm" || hud.bubbleOn ? -1 : 0

    Text {
        text: "// VITALS  バイタル"
        color: col.hud.theme.sub
        font.family: "Hack Nerd Font Mono"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1
        Layout.preferredHeight: 26
        verticalAlignment: Text.AlignVCenter
    }
    Flickable {
        id: vflick
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: vcol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // indicador de rolagem (só aparece quando os cartões não cabem)
        Rectangle {
            parent: vflick
            visible: vflick.contentHeight > vflick.height
            anchors.right: parent.right
            width: 2; radius: 1
            y: vflick.visibleArea.yPosition * vflick.height
            height: vflick.visibleArea.heightRatio * vflick.height
            color: col.hud.theme.visor
            opacity: 0.6
            z: 5
        }
        ColumnLayout {
            id: vcol
            width: vflick.width
            spacing: 8

            VitalCard {
                Layout.fillWidth: true
                opacity: col.hud.cardIn(0)
                transform: Translate { x: (1 - col.hud.cardIn(0)) * 24 }
                compact: col.compactCards
                lookX: col.look
                label: "CPU"; kind: col.hud.cpuKind
                value: col.hud.hostCpu
                warnAt: 60; alarmAt: 85
                bars: [{ k: i18nc("short bar label: cpu usage", "use"), v: col.hud.hostCpu }]
                series: col.hud.hostHistory.cpu
                temp: col.hud.showTemps ? col.hud.cpuTemp : 0
                tempHot: col.hud.tempHot; tempCritical: col.hud.tempCritical
                detail: "docker " + col.hud.dockerCpu.toFixed(1) + "%" + (col.hud.topCpu ? "  ·  ▲ " + col.hud.topCpu.name : "")
                tip: i18n("computer %1%  ·  docker %2% (100% = 1 core)", col.hud.hostCpu.toFixed(1), col.hud.dockerCpu.toFixed(1))
                     + (col.hud.topCpu ? "\n" + i18n("heaviest: %1 %2%", col.hud.topCpu.name, col.hud.topCpu.v.toFixed(1)) : "")
                theme: col.hud.theme; glowLevel: col.hud.glowLevel; animated: col.hud.animating
            }
            VitalCard {
                Layout.fillWidth: true
                opacity: col.hud.cardIn(1)
                transform: Translate { x: (1 - col.hud.cardIn(1)) * 24 }
                compact: col.compactCards
                lookX: col.look
                label: "RAM"; kind: col.hud.ramKind
                value: col.hud.hostMemPct
                available: col.hud.hostMemTotal > 0
                warnAt: 75; alarmAt: 90
                bars: [{ k: "mem", v: col.hud.hostMemPct, part: col.hud.hostMemTotal > 0 ? col.hud.dockerMem / col.hud.hostMemTotal * 100 : 0 }]
                series: col.hud.hostHistory.mem
                detail: Logic.formatBytes(col.hud.hostMemUsed) + " / " + Logic.formatBytes(col.hud.hostMemTotal) + "  ·  docker " + Logic.formatBytes(col.hud.dockerMem)
                tip: i18n("bar: Docker's share highlighted, the rest is the computer")
                theme: col.hud.theme; glowLevel: col.hud.glowLevel; animated: col.hud.animating
            }
            VitalCard {
                Layout.fillWidth: true
                opacity: col.hud.cardIn(2)
                transform: Translate { x: (1 - col.hud.cardIn(2)) * 24 }
                compact: col.compactCards
                lookX: col.look
                label: col.hud.gpuVendor ? "GPU " + col.hud.gpuVendor.toUpperCase() : "GPU"; kind: col.hud.gpuKind
                value: col.hud.gpuUtil
                available: col.hud.gpuMemTotal > 0
                warnAt: 40; alarmAt: 90
                bars: [{ k: "core", v: col.hud.gpuUtil },
                       { k: "vram", v: col.hud.gpuMemPct, part: col.hud.gpuMemTotal > 0 ? col.hud.dockerVram / col.hud.gpuMemTotal * 100 : 0 }]
                series: col.hud.hostHistory.gpu
                temp: col.hud.showTemps ? col.hud.gpuTemp : 0
                tempHot: col.hud.tempHot; tempCritical: col.hud.tempCritical
                detail: col.hud.gpuMemTotal > 0
                        ? "VRAM " + Logic.formatMiB(col.hud.gpuMemUsed) + " / " + Logic.formatMiB(col.hud.gpuMemTotal) + (col.hud.topVram ? "  ·  ▲ " + col.hud.topVram.name : "")
                        : i18n("no NVIDIA/AMD GPU")
                tip: col.hud.gpuMemTotal > 0
                     ? i18n("usage %1%  ·  VRAM %2 of %3  ·  docker %4", Math.round(col.hud.gpuUtil), Logic.formatMiB(col.hud.gpuMemUsed), Logic.formatMiB(col.hud.gpuMemTotal), Logic.formatMiB(col.hud.dockerVram))
                     : i18n("no nvidia-smi and no amdgpu card")
                theme: col.hud.theme; glowLevel: col.hud.glowLevel; animated: col.hud.animating
            }
            VitalCard {
                id: diskCard
                Layout.fillWidth: true
                opacity: col.hud.cardIn(3)
                transform: Translate { x: (1 - col.hud.cardIn(3)) * 24 }
                compact: col.compactCards
                lookX: col.look
                readonly property var disk: col.hud.disk
                readonly property real pct: disk.total > 0 ? disk.used / disk.total * 100 : 0
                label: i18nc("vital card title", "DISK · NET"); kind: col.hud.diskKind
                value: pct
                available: disk.total > 0
                warnAt: 85; alarmAt: 95
                bars: [{ k: i18nc("short bar label", "disk"), v: pct, part: disk.total > 0 ? disk.docker / disk.total * 100 : 0 }]
                showSeries: false
                detail: Logic.formatBytes(disk.used) + " / " + Logic.formatBytes(disk.total) + "  ·  docker " + Logic.formatBytes(disk.docker)
                tip: Object.keys(disk.parts).map(k => k + " " + Logic.formatBytes(disk.parts[k])).join("  ·  ")
                theme: col.hud.theme; glowLevel: col.hud.glowLevel; animated: col.hud.animating

                // rede: throughput total do computador (sem loopback / interfaces do Docker)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Text {
                        text: i18nc("short label: network", "net")
                        color: col.hud.theme.muted
                        font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                        Layout.preferredWidth: 30
                    }
                    Sparkline {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        values: col.hud.hostHistory.net || []
                        color: col.hud.theme.visor
                        minScale: 64 * 1024
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: "↓ " + Logic.formatBytes(col.hud.netRx) + "/s   ↑ " + Logic.formatBytes(col.hud.netTx) + "/s"
                    color: col.hud.theme.visor
                    font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                }
                // limpeza: dois cliques (o 1º arma, o 2º confirma)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: col.hud.pruneResult ? "♻ " + col.hud.pruneResult
                                                  : "♻ " + i18n("%1 reclaimable", Logic.formatBytes(diskCard.disk.reclaimable))
                        color: col.hud.theme.sub
                        elide: Text.ElideRight
                        font.family: "Hack Nerd Font Mono"; font.pixelSize: 9
                    }
                    Rectangle {
                        id: pruneBtn
                        property bool armed: false
                        readonly property color cc: armed ? col.hud.theme.alarm : col.hud.theme.fur
                        implicitWidth: pruneLabel.implicitWidth + 12
                        implicitHeight: 18
                        radius: 3
                        color: pruneArea.containsMouse || armed ? Qt.rgba(cc.r, cc.g, cc.b, 0.25) : "transparent"
                        border.width: 1
                        border.color: cc
                        Text {
                            id: pruneLabel
                            anchors.centerIn: parent
                            text: pruneBtn.armed ? i18n("confirm?") : i18n("clean up")
                            color: pruneBtn.cc
                            font.family: "Hack Nerd Font Mono"; font.pixelSize: 9; font.bold: true
                        }
                        MouseArea {
                            id: pruneArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (pruneBtn.armed) { pruneBtn.armed = false; col.hud.prune() }
                                else { pruneBtn.armed = true; disarm.restart() }
                            }
                        }
                        Timer { id: disarm; interval: 4000; onTriggered: pruneBtn.armed = false }
                        ToolTipLite {
                            text: i18n("removes images without containers and the build cache\n(they will have to be downloaded again)")
                            shown: pruneArea.containsMouse; accent: col.hud.theme.alarm; background: col.hud.theme.bg0
                            anchors.horizontalCenter: undefined; anchors.right: parent.right
                        }
                    }
                }
            }
        }
    }
}
