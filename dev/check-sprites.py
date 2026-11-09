#!/usr/bin/env python3
"""Valida as grades de Sprites.js: 16x14, papéis conhecidos, olhos presentes."""
import re, sys, pathlib
src = pathlib.Path(__file__).resolve().parent.parent / "package/contents/ui/Sprites.js"
text = src.read_text()
roles = set(".KPSHMCEWBTFDA")
ok = True
for name, body in re.findall(r'^    (\w+): \{(.*?)^    \}', text, re.S | re.M):
    rows = re.findall(r'"([^"]*)"', body.split("grid:")[1])
    errs = []
    if len(rows) != 14: errs.append(f"{len(rows)} linhas (esperado 14)")
    for i, r in enumerate(rows):
        if len(r) != 16: errs.append(f"linha {i} tem {len(r)} colunas")
        bad = set(r) - roles
        if bad: errs.append(f"linha {i} papéis desconhecidos {bad}")
    if not any("E" in r for r in rows): errs.append("sem olhos (E)")
    eyebg = re.search(r'eyeBg: "(.)"', body)
    if not eyebg or eyebg.group(1) not in roles: errs.append("eyeBg inválido")
    print(f"{'OK ' if not errs else 'ERRO'} {name:8} " + "; ".join(errs))
    ok &= not errs
sys.exit(0 if ok else 1)
