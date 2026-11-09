#!/usr/bin/env bash
# Traduções do CyberDock. Requer gettext (xgettext, msgmerge, msgfmt) e python3.
#   dev/i18n.sh          extrai os textos, atualiza po/*.po, compila os .mo e o dicionário dos previews
#   dev/i18n.sh --check  idem, e falha se houver mensagem sem tradução
# Textos-fonte em inglês, marcados no QML com i18n()/i18nc()/i18np()/i18ncp() e, nas bibliotecas
# JS (que não enxergam o i18n do Plasma), com N_() — o QML traduz na hora de exibir.
set -euo pipefail
cd "$(dirname "$0")/.."
domain="plasma_applet_$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')"
mkdir -p po

find package -name '*.qml' -o -name '*.js' | sort | xargs xgettext \
    --from-code=UTF-8 -L JavaScript -C --package-name=cyberdock --msgid-bugs-address=https://github.com/pedroluizmossi/anime-cyber-docker/issues \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 -kN_:1 \
    -o "po/$domain.pot"
sed -i 's/charset=CHARSET/charset=UTF-8/' "po/$domain.pot"

for po in po/*.po; do
    [ -e "$po" ] || continue
    lang="$(basename "$po" .po)"
    msgmerge --quiet --update --backup=none --no-fuzzy-matching "$po" "po/$domain.pot"
    out="package/contents/locale/$lang/LC_MESSAGES"
    mkdir -p "$out"
    msgfmt --check -o "$out/$domain.mo" "$po"
    python3 dev/po2js.py "$po" "dev/i18n-$lang.js"
    stats="$(msgfmt --statistics -o /dev/null "$po" 2>&1)"
    echo "▸ $lang: $stats"
    if [[ "${1:-}" == "--check" ]] && grep -qE 'untranslated|fuzzy' <<<"$stats"; then
        echo "✗ $lang tem mensagens sem tradução" >&2; exit 1
    fi
done
