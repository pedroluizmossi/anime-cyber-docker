.pragma library
.import "i18n-pt_BR.js" as PT

// i18n() fora do Plasma (previews e renders de dev/). No Plasma quem responde é o KI18n,
// com o .mo de package/contents/locale. Aqui: dicionário gerado do po/pt_BR.po por
// dev/i18n.sh, usado quando a localidade do sistema é pt (LANG=en_US… força inglês).
var dict = Qt.locale().name.indexOf("pt") === 0 ? PT.messages : null

function sub(s, args) {
    return s.replace(/%(\d)/g, (m, n) => args[n - 1] !== undefined ? String(args[n - 1]) : m)
}
function find(key) { return dict ? dict[key] : undefined }
function pick(entry, sing, plur, n) {
    const many = dict ? n > 1 : n !== 1          // pt_BR: plural=(n > 1); inglês: n != 1
    if (Array.isArray(entry) && entry[many ? 1 : 0]) return entry[many ? 1 : 0]
    return many ? plur : sing
}

function i18n(s, ...a) { const t = find(s); return sub(typeof t === "string" && t ? t : s, a) }
function i18nc(c, s, ...a) { const t = find(c + "\u0004" + s); return sub(typeof t === "string" && t ? t : s, a) }
function i18np(s, p, n, ...a) { return sub(pick(find(s), s, p, n), [n].concat(a)) }
function i18ncp(c, s, p, n, ...a) { return sub(pick(find(c + "\u0004" + s), s, p, n), [n].concat(a)) }
