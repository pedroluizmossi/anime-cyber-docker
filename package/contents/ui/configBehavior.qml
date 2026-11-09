import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property int cfg_refreshSeconds
    property int cfg_busyGpu
    property int cfg_busyCpu

    Kirigami.FormLayout {
        QQC2.SpinBox {
            Kirigami.FormData.label: "Atualizar a cada (s):"
            from: 1; to: 60
            value: page.cfg_refreshSeconds
            onValueModified: page.cfg_refreshSeconds = value
        }

        Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Modo ⚡ busy quando…" }

        QQC2.SpinBox {
            Kirigami.FormData.label: "Uso da GPU ≥ (%):"
            from: 1; to: 100
            value: page.cfg_busyGpu
            onValueModified: page.cfg_busyGpu = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: "CPU de um container ≥ (%):"
            from: 1; to: 1000
            value: page.cfg_busyCpu
            onValueModified: page.cfg_busyCpu = value
        }
        QQC2.Label {
            text: "CPU do Docker é por núcleo: 100% = um núcleo inteiro."
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }
}
