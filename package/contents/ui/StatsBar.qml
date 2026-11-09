// Contadores RUN / STOP / ERR (+ CPU / RAM / GPU quando não há coluna de sinais vitais).
import QtQuick
import QtQuick.Layouts
import "Logic.js" as Logic

RowLayout {
    id: bar
    property Item hud
    spacing: 6

    Repeater {
        model: {
            const h = bar.hud
            const t = h.theme
            const base = [
                { k: i18nc("counter label: running containers", "RUN"), v: h.running, c: t.visor, w: 1 },
                { k: i18nc("counter label: stopped containers", "STOP"), v: h.containers.length - h.running, c: t.sub, w: 1 },
                { k: i18nc("counter label: containers with errors", "ERR"), v: h.problems, c: h.problems ? t.alarm : t.muted, w: 1, urgent: h.problems > 0 }
            ]
            if (h.sideBySide) return base
            const memFrac = h.hostMemTotal > 0 ? h.hostMemUsed / h.hostMemTotal : 0
            return base.concat([
                { k: "CPU", v: Math.round(h.hostCpu) + "%", w: 1.25,
                  c: h.hostCpu >= 85 ? t.alarm : h.hostCpu >= 60 ? t.warn : t.ok,
                  tip: i18n("computer %1%  ·  docker %2% (100% = 1 core)", h.hostCpu.toFixed(1), h.dockerCpu.toFixed(1)) },
                { k: "RAM " + Logic.formatBytes(h.hostMemUsed) + "/" + Logic.formatBytes(h.hostMemTotal), w: 1.6,
                  v: h.hostMemTotal > 0 ? Math.round(memFrac * 100) + "%" : "–",
                  c: memFrac >= 0.9 ? t.alarm : memFrac >= 0.75 ? t.warn : t.ok,
                  tip: i18n("computer %1 of %2  ·  docker %3", Logic.formatBytes(h.hostMemUsed), Logic.formatBytes(h.hostMemTotal), Logic.formatBytes(h.dockerMem)) },
                { k: h.gpuMemTotal > 0 ? "GPU " + Logic.formatMiB(h.gpuMemUsed) + "/" + Logic.formatMiB(h.gpuMemTotal) : "GPU", w: 1.6,
                  v: Math.round(h.gpuUtil) + "%", c: h.mood === "busy" ? t.warn : t.ok,
                  tip: h.gpuMemTotal > 0 ? i18n("usage %1%  ·  VRAM %2 of %3", Math.round(h.gpuUtil), Logic.formatMiB(h.gpuMemUsed), Logic.formatMiB(h.gpuMemTotal)) : "" }
            ])
        }
        delegate: CounterTile {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredWidth: 60 * modelData.w     // quadros com texto maior ganham mais espaço
            label: modelData.k
            value: modelData.v
            accent: modelData.c
            theme: bar.hud.theme
            tip: modelData.tip || ""
            animated: bar.hud.animating
            pulse: !!modelData.urgent
        }
    }
}
