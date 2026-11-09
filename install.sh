#!/usr/bin/env bash
# CyberDock — instalador do plasmoid para KDE Plasma 6.
#
#   Instalar / atualizar (sem clonar):
#     curl -fsSL https://raw.githubusercontent.com/pedroluizmossi/anime-cyber-docker/main/install.sh | bash
#
#   Desinstalar:
#     curl -fsSL https://raw.githubusercontent.com/pedroluizmossi/anime-cyber-docker/main/install.sh | bash -s -- --uninstall
#
#   De um clone local: ./install.sh [--uninstall]
#   Outra branch/tag:  CYBERDOCK_REF=v0.2.0 bash install.sh
set -euo pipefail

REPO="pedroluizmossi/anime-cyber-docker"
REF="${CYBERDOCK_REF:-main}"
ID="com.pedro.cyberdock"

c_ok=$'\e[38;5;51m'; c_pk=$'\e[38;5;213m'; c_err=$'\e[38;5;196m'; c_dim=$'\e[2m'; c_off=$'\e[0m'
say()  { printf '%s▸%s %s\n' "$c_pk" "$c_off" "$*"; }
ok()   { printf '%s✔%s %s\n' "$c_ok" "$c_off" "$*"; }
die()  { printf '%s✘ %s%s\n' "$c_err" "$*" "$c_off" >&2; exit 1; }

command -v kpackagetool6 >/dev/null || die "kpackagetool6 não encontrado — o CyberDock precisa do KDE Plasma 6."

installed() { kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$ID"; }

if [[ "${1:-}" == "--uninstall" ]]; then
    if installed; then
        kpackagetool6 -t Plasma/Applet -r "$ID" >/dev/null
        ok "CyberDock removido. Tire o widget do painel se ele ainda estiver lá."
    else
        say "CyberDock não está instalado."
    fi
    exit 0
fi

printf '%s' "$c_pk"
cat <<'BANNER'
   ____      _               ____             _
  / ___|   _| |__   ___ _ __|  _ \  ___   ___| | __
 | |  | | | | '_ \ / _ \ '__| | | |/ _ \ / __| |/ /
 | |__| |_| | |_) |  __/ |  | |_| | (_) | (__|   <
  \____\__, |_.__/ \___|_|  |____/ \___/ \___|_|\_\
       |___/        neon companion para o Docker
BANNER
printf '%s\n' "$c_off"

# 1. pacote: clone local (se rodou de dentro do repo) ou download do GitHub
script_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "$script_dir" && -f "$script_dir/package/metadata.json" ]]; then
    pkg="$script_dir/package"
    say "Usando o pacote local: ${c_dim}$pkg${c_off}"
else
    command -v curl >/dev/null || die "curl é necessário para baixar o CyberDock."
    command -v tar  >/dev/null || die "tar é necessário para extrair o CyberDock."
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    say "Baixando ${REPO}@${REF}…"
    curl -fsSL "https://codeload.github.com/${REPO}/tar.gz/${REF}" | tar -xz -C "$tmp" \
        || die "Falha no download de ${REPO}@${REF}."
    pkg="$(find "$tmp" -mindepth 2 -maxdepth 2 -type d -name package | head -n1)"
    [[ -f "$pkg/metadata.json" ]] || die "Pacote inválido no download."
fi

# 2. instala ou atualiza
if installed; then
    say "Atualizando o CyberDock…"
    kpackagetool6 -t Plasma/Applet -u "$pkg" >/dev/null
    updated=1
else
    say "Instalando o CyberDock…"
    kpackagetool6 -t Plasma/Applet -i "$pkg" >/dev/null
    updated=0
fi
version="$(grep -o '"Version": *"[^"]*"' "$pkg/metadata.json" | cut -d'"' -f4)"
ok "CyberDock ${version} instalado em ~/.local/share/plasma/plasmoids/${ID}"

# 3. avisos de requisitos (não bloqueiam)
if ! command -v docker >/dev/null; then
    printf '%s!%s Docker não encontrado — a mascote vai ficar em alerta até ele existir.\n' "$c_err" "$c_off"
elif ! docker ps >/dev/null 2>&1; then
    printf '%s!%s Seu usuário não acessa o Docker sem sudo. Rode: %ssudo usermod -aG docker "$USER"%s e faça logout/login.\n' \
        "$c_err" "$c_off" "$c_dim" "$c_off"
fi
command -v konsole >/dev/null || printf '%s!%s Konsole não encontrado: os botões de logs/shell não vão abrir terminal.\n' "$c_err" "$c_off"

echo
if [[ $updated == 1 ]]; then
    say "Para carregar a nova versão no painel: ${c_ok}systemctl --user restart plasma-plasmashell${c_off}"
else
    say "Agora: botão direito no painel → ${c_ok}Adicionar widgets${c_off} → procure ${c_ok}CyberDock${c_off} e arraste para o painel."
fi
