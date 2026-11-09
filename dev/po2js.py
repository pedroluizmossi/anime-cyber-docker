#!/usr/bin/env python3
"""Converte um .po em dicionário JS para o shim de i18n dos previews (dev/I18nShim.js).
Chave: msgid (ou "contexto\\x04msgid"); valor: msgstr ou [msgstr[0], msgstr[1]]."""
import json, re, sys

def unquote(s):
    return json.loads(s)  # strings do .po usam os mesmos escapes que JSON para o que usamos

def parse(path):
    entries, cur, key = [], {}, None
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip():
            if cur: entries.append(cur); cur, key = {}, None
            continue
        if line.startswith("#"):
            if line.startswith("#,") and "fuzzy" in line: cur["fuzzy"] = True
            continue
        m = re.match(r'^(msgctxt|msgid_plural|msgid|msgstr(?:\[\d\])?)\s+(".*")$', line)
        if m:
            key = m.group(1); cur[key] = unquote(m.group(2))
        elif line.startswith('"') and key:
            cur[key] += unquote(line)
    if cur: entries.append(cur)
    return entries

out = {}
for e in parse(sys.argv[1]):
    if not e.get("msgid") or e.get("fuzzy"): continue
    k = (e["msgctxt"] + "\x04" if "msgctxt" in e else "") + e["msgid"]
    if "msgid_plural" in e:
        forms = [e.get("msgstr[0]", ""), e.get("msgstr[1]", "")]
        if any(forms): out[k] = forms
    elif e.get("msgstr"):
        out[k] = e["msgstr"]
with open(sys.argv[2], "w", encoding="utf-8") as f:
    f.write(".pragma library\n// Gerado por dev/i18n.sh a partir de %s — não edite à mão.\nvar messages = " % sys.argv[1])
    json.dump(out, f, ensure_ascii=False, indent=1, sort_keys=True)
    f.write("\n")
