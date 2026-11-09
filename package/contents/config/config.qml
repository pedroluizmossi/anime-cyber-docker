import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Aparência"
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: "Comportamento"
        icon: "preferences-system"
        source: "configBehavior.qml"
    }
}
