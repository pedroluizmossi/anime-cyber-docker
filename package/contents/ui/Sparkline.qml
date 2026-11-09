// Mini-gráfico de linha com preenchimento. Escala automática (mínimo = minScale).
import QtQuick

Canvas {
    id: spark

    property var values: []
    property color color: "#00f0ff"
    property real minScale: 1

    implicitWidth: 52
    implicitHeight: 14
    antialiasing: true
    renderStrategy: Canvas.Cooperative

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const v = values || []
        // linha de base
        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.18)
        ctx.fillRect(0, height - 1, width, 1)
        if (v.length < 2) return

        const max = Math.max(minScale, ...v)
        const step = width / (v.length - 1)
        const y = val => height - 1 - (val / max) * (height - 2)

        ctx.beginPath()
        ctx.moveTo(0, height)
        for (let i = 0; i < v.length; i++) ctx.lineTo(i * step, y(v[i]))
        ctx.lineTo(width, height)
        ctx.closePath()
        const g = ctx.createLinearGradient(0, 0, 0, height)
        g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.45))
        g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0.02))
        ctx.fillStyle = g
        ctx.fill()

        ctx.beginPath()
        for (let i = 0; i < v.length; i++) {
            if (i === 0) ctx.moveTo(0, y(v[0]))
            else ctx.lineTo(i * step, y(v[i]))
        }
        ctx.strokeStyle = color
        ctx.lineWidth = 1.2
        ctx.stroke()

        // ponto no último valor
        ctx.fillStyle = color
        ctx.fillRect(width - 2, y(v[v.length - 1]) - 1, 2, 2)
    }
}
