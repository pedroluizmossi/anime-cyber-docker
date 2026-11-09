#!/usr/bin/env bash
# Instala ou atualiza o plasmoid CyberDock para o usuário atual.
set -euo pipefail
cd "$(dirname "$0")"
id=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$id"; then
    kpackagetool6 -t Plasma/Applet -u package
else
    kpackagetool6 -t Plasma/Applet -i package
fi
echo "Instalado: $id"
echo "Se já estiver no painel, reinicie o plasmashell para ver as mudanças:"
echo "  systemctl --user restart plasma-plasmashell"
