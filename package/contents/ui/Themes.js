.pragma library

// Marca um texto para tradução sem traduzir aqui (bibliotecas JS não enxergam o i18n do
// Plasma): o QML chama i18n(label) na hora de exibir. Extraído por dev/i18n.sh.
function N_(s) { return s }

// Cada tema define a mascote (fur, visor, outline, ear, blush) e o HUD.
//   ok/warn/alarm/sleep: cores de estado     bg0/bg1: gradiente do popup
//   text/sub/muted: textos (principal, secundário, apagado)
const themes = {
    neon: {
        label: N_("Neon (magenta / cyan)"),
        fur: "#ff2bd6", visor: "#00f0ff", outline: "#12061f", ear: "#ffd1f5", blush: "#ff8fc8",
        ok: "#39ff14", warn: "#fff200", alarm: "#ff1744", sleep: "#7a5cff",
        bg0: "#14062a", bg1: "#05020c", text: "#f2e9ff", sub: "#8f7bb3", muted: "#5a4a78"
    },
    matrix: {
        label: N_("Matrix (terminal green)"),
        fur: "#00c853", visor: "#b6ff00", outline: "#001a06", ear: "#a5ffb0", blush: "#7dff9b",
        ok: "#00ff41", warn: "#e6ff00", alarm: "#ff3b30", sleep: "#2e7d32",
        bg0: "#021a08", bg1: "#000400", text: "#d7ffd9", sub: "#5fae6a", muted: "#2f5e37"
    },
    synthwave: {
        label: N_("Synthwave (purple / orange)"),
        fur: "#7b2cff", visor: "#ff8a00", outline: "#10002a", ear: "#ffb3e6", blush: "#ff6ec7",
        ok: "#00e5ff", warn: "#ffd600", alarm: "#ff1f5a", sleep: "#4527a0",
        bg0: "#1a0633", bg1: "#0b0016", text: "#ffe8ff", sub: "#b38bd9", muted: "#5e3b85"
    },
    vaporwave: {
        label: N_("Vaporwave (pastel)"),
        fur: "#ff9ecf", visor: "#7df9ff", outline: "#2a1035", ear: "#ffffff", blush: "#ffb6d9",
        ok: "#8affc1", warn: "#fff59d", alarm: "#ff5c8a", sleep: "#b39ddb",
        bg0: "#2b1b3d", bg1: "#120a1f", text: "#fff0fb", sub: "#c7a8e0", muted: "#6e5a85"
    },
    akira: {
        label: N_("Akira (red / white)"),
        fur: "#ff2a2a", visor: "#f5f5f5", outline: "#120000", ear: "#ffc2c2", blush: "#ff8080",
        ok: "#00e676", warn: "#ffc400", alarm: "#ffea00", sleep: "#8e8e8e",
        bg0: "#1a0505", bg1: "#050101", text: "#ffecec", sub: "#c48a8a", muted: "#6b3a3a"
    },
    ghost: {
        label: N_("Ghost (ice blue)"),
        fur: "#4fc3f7", visor: "#e0f7ff", outline: "#021627", ear: "#ffffff", blush: "#9be7ff",
        ok: "#64ffda", warn: "#ffe57f", alarm: "#ff5252", sleep: "#5c7c99",
        bg0: "#061a2b", bg1: "#01070d", text: "#e8f6ff", sub: "#7fa7c4", muted: "#3b5a73"
    },
    custom: {
        label: N_("Custom"),
        // fur/visor vêm da configuração; o resto herda do neon
    }
}

const order = ["neon", "matrix", "synthwave", "vaporwave", "akira", "ghost", "custom"]

function list() {
    return order.map(k => ({ key: k, label: themes[k].label }))
}

function get(name, customFur, customVisor) {
    const base = themes.neon
    if (name === "custom") {
        const t = Object.assign({}, base)
        t.label = themes.custom.label
        if (customFur) t.fur = customFur
        if (customVisor) t.visor = customVisor
        return t
    }
    return Object.assign({}, base, themes[name] || {})
}
