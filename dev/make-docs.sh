#!/usr/bin/env bash
# Gera as imagens do README em docs/img/. Requer: qml6 (Qt 6), ImageMagick (magick).
# Uso: dev/make-docs.sh
set -euo pipefail
cd "$(dirname "$0")/.."
out=docs/img
mkdir -p "$out"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
run() { timeout 60 qml6 "$@" >/dev/null 2>&1; }

echo "▸ banner";            run dev/render-hero.qml -- "$out/hero.png"
echo "▸ GIF dos humores";   run dev/render-gif-frames.qml -- "$tmp"
magick -delay 8 -loop 0 "$tmp"/f*.png -layers OptimizePlus -colors 128 "$out/moods.gif"

echo "▸ galeria de mascotes";  run dev/preview-mascots.qml -- neon "$out/mascots.png"
echo "▸ galeria de temas";     run dev/preview-themes.qml -- "$tmp/themes.png"
magick "$tmp/themes.png" -background "#05020c" -flatten "$out/themes.png"

echo "▸ HUD (lista simples + agrupado por stack)"
run dev/preview-hud.qml -- 0 neon - "$tmp/hud-flat.png"
run dev/preview-hud.qml -- 1 synthwave - "$tmp/hud-group.png"
magick "$tmp/hud-flat.png" "$tmp/hud-group.png" -background none -splice 24x0 +append -chop 24x0 "$out/popups.png"

echo "▸ painel (ampliado 2× sem suavizar)"
run dev/render-panel.qml -- "$tmp/panel.png"
magick "$tmp/panel.png" -filter point -resize 200% "$out/panel.png"

echo "▸ configuração"
run dev/preview-config.qml -- synthwave "$tmp/config.png"
magick "$tmp/config.png" -crop 720x430+0+0 +repage "$out/config.png"

ls -lh "$out"
