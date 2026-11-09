.pragma library

// Marca um texto para tradução sem traduzir aqui (bibliotecas JS não enxergam o i18n do
// Plasma): o QML chama i18n(label) na hora de exibir. Extraído por dev/i18n.sh.
function N_(s) { return s }

// Todas as mascotes são 16 colunas × 14 linhas, um caractere por pixel.
// Os caracteres são PAPÉIS de cor; o tema decide a cor real (ver Mascot.qml):
//   .  transparente        K  contorno            P  cor principal (pelo/corpo)
//   S  sombra da principal H  brilho da principal M  detalhe claro (orelha, focinho)
//   C  visor               E  olho                W  brilho do olho
//   B  blush               T  boca                F  pele
//   D  hardware (fone)     A  LED (acompanha o humor)
// eyeBg: papel usado no lugar do olho quando ele fecha (o traço vai na última linha do olho).
// shadeFrom: linha a partir da qual P vira sombra automaticamente (só a neko usa).
// colors (opcional): cores fixas que ignoram o tema — { fur, ear } — para mascotes
// com cor "de verdade" (sapo verde, chip de silício, placas de vídeo).
// vital (opcional): recurso que a mascote representa na coluna de sinais vitais.

const sprites = {
    neko: {
        label: N_("Cyborg Neko"),
        eyeBg: "C",
        shadeFrom: 11,
        grid: [
            ".K............K.",
            "KMK..........KMK",
            "KMPK..KKKK..KPMK",
            "KPPPKKPPPPKKPPPK",
            "KPPPPPPPPPPPPPPK",
            "KPHPPPPPPPPPPHPK",
            "KCCCCCCCCCCCCCCK",
            "KCEEWCCCCCCEEWCK",
            "KCEEECCCCCCEEECK",
            "KCCCCCCCCCCCCCCK",
            "KPBBPPPPPPPPBBPK",
            "KPPPPPPTTPPPPPPK",
            ".KPPPPPPPPPPPPK.",
            "..KKKKKKKKKKKK.."
        ]
    },
    robo: {
        label: N_("Unit-7 Robot"),
        eyeBg: "C",
        grid: [
            "......KAK.......",
            ".......K........",
            ".KKKKKKKKKKKKKK.",
            "KHPPPPPPPPPPPPSK",
            "KPKKKKKKKKKKKKSK",
            "KPKCCCCCCCCCCKSK",
            "KPKCEEWCCEEWCKSK",
            "MPKCEEECCEEECKSM",
            "KPKCCCCCCCCCCKSK",
            "KPKCCCTTTTCCCKSK",
            "KPKKKKKKKKKKKKSK",
            "KPPPBPPPPPPBPPSK",
            "KSSSSSSSSSSSSSSK",
            ".KKKKKKKKKKKKKK."
        ]
    },
    kitsune: {
        label: N_("Kitsune (fox)"),
        eyeBg: "C",
        grid: [
            "K..............K",
            "KK............KK",
            "KMK..........KMK",
            "KMPK........KPMK",
            "KMPPKKKKKKKKPPMK",
            "KPPPPPPPPPPPPPPK",
            "KCCCCCCCCCCCCCCK",
            "KCWEECCCCCCWEECK",
            "KCEEECCCCCCEEECK",
            "KPPCCCCCCCCCCPPK",
            "MPPPMMMMMMMMPPPM",
            ".KPPMMMTTMMMPPK.",
            "..KPPMMMMMMPPK..",
            "...KKKKKKKKKK..."
        ]
    },
    usagi: {
        label: N_("Usagi (bunny)"),
        eyeBg: "C",
        grid: [
            "...KKK....KKK...",
            "...KMK....KMK...",
            "...KMK....KMK...",
            "...KMK....KMK...",
            "..KKPKKKKKKPKK..",
            ".KHPPPPPPPPPPPK.",
            "KPPPPPPPPPPPPPPK",
            "KCCCCCCCCCCCCCCK",
            "KCEEWCCCCCCEEWCK",
            "KCEEECCCCCCEEECK",
            "KPBBPPPPPPPPBBPK",
            "KPPPPPPTTPPPPPPK",
            ".KPPPPPMMPPPPPK.",
            "..KKKKKKKKKKKK.."
        ]
    },
    yurei: {
        label: N_("Yūrei (ghost)"),
        eyeBg: "P",
        grid: [
            ".....KKKKKK.....",
            "...KKHHPPPPKK...",
            "..KHHPPPPPPPPK..",
            ".KHPPPPPPPPPPPK.",
            ".KPPPPPPPPPPPAK.",
            "KPPEEWPPPPEEWPPK",
            "KPPEEEPPPPEEEPPK",
            "KPPEEEPPPPEEEPPK",
            "KPBBPPPTTPPPBBPK",
            "KPPPPPPPPPPPPPPK",
            "KPPPPPPPPPPPPPPK",
            "KSPPPSPPPSPPPSPK",
            "KPPKPPKPPKPPKPPK",
            ".KK.KK.KK.KK.KK."
        ]
    },
    hacker: {
        label: N_("Hacker-chan"),
        eyeBg: "F",
        grid: [
            "....KKKKKKKK....",
            "..KKHHPPPPPPKK..",
            ".KHHPPPPPPPPPPK.",
            "KHPCCCCPPCCCCPPK",
            "KPPPPPPPPPPPPPPK",
            "KPPFPPFFFFPPFPPK",
            "DPFFFFFFFFFFFFPD",
            "DPFEEWFFFFEEWFPD",
            "APFEEEFFFFEEEFPA",
            "DPFEEEFFFFEEEFPD",
            "DPFBBFFFFFFBBFPD",
            "KPPFFFFTTFFFFPPK",
            ".KPPFFFFFFFFPPK.",
            "..KKKKKKKKKKKK.."
        ]
    },
    sapo: {
        label: N_("Frog"),
        vital: "ram",
        eyeBg: "M",
        colors: { fur: "#3ddc54", ear: "#d8ffb0" },
        grid: [
            "..KKKK....KKKK..",
            ".KMMMMK..KMMMMK.",
            ".KMEEWK..KMEEWK.",
            ".KMEEEKKKKMEEEK.",
            "KPKKKKPPPPKKKKPK",
            "KHPPPPPAPPPPPPPK",
            "KPPPPPPPPPPPPPPK",
            "KPBBPPPPPPPPBBPK",
            "KPPTPPPPPPPPTPPK",
            "KPPPTTTTTTTTPPPK",
            "KSPPPMMMMMMPPPSK",
            "KSSPMMMMMMMMPSSK",
            ".KSSPMMMMMMPSSK.",
            "..KKKKKKKKKKKK.."
        ]
    },
    chip: {
        label: N_("Microprocessor"),
        vital: "cpu",
        eyeBg: "C",
        colors: { fur: "#8a93a6" },
        grid: [
            "..D.D.D..D.D.D..",
            ".KKKKKKKKKKKKKK.",
            ".KHPPPPPPPPPPSK.",
            "DKPKKKKKKKKKKSKD",
            ".KPKCCCCCCCCKSK.",
            "DKPKCEWCCEWCKSKD",
            ".KPKCEECCEECKSK.",
            "DKPKCCCTTCCCKSKD",
            ".KPKKKKKKKKKKSK.",
            "DKPPBPPPPPPBPSKD",
            ".KPPPPPAPPPPPSK.",
            "DKSSSSSSSSSSSSKD",
            ".KKKKKKKKKKKKKK.",
            "..D.D.D..D.D.D.."
        ]
    },
    nvidia: {
        label: N_("NVIDIA GPU"),
        vital: "gpu",
        eyeBg: "C",
        colors: { fur: "#76b900", ear: "#ffcc33" },
        grid: [
            ".KKKKKKKKKKKKKKK",
            "DKHPPPPPPPPPPPSK",
            "DKPKKKKPPKKKKPSK",
            "DKKCCCCKKCCCCKSK",
            "DKKCEWCKKCEWCKSK",
            "DKKCEECKKCEECKSK",
            "DKKCCCCKKCCCCKSK",
            "DKPKKKKPPKKKKPSK",
            "DKPBPPPTTPPPBPSK",
            "DKPPPPPPPPPPPASK",
            "DKSSSSSSSSSSSSSK",
            ".KKKKKKKKKKKKKKK",
            "....MMMMMM.MMM..",
            "....MMMMMM.MMM.."
        ]
    },
    amd: {
        label: N_("AMD GPU"),
        vital: "gpu",
        eyeBg: "C",
        colors: { fur: "#ed1c24", ear: "#ffcc33" },
        grid: [
            ".KKKKKKKKKKKKKK.",
            "DKSHHPPPPPPHHSKK",
            "DKPKKKKHHKKKKPSK",
            "DKKCCCCKKCCCCKSK",
            "DKKCWECKKCWECKSK",
            "DKKCEECKKCEECKSK",
            "DKKCCCCKKCCCCKSK",
            "DKPKKKKHHKKKKPSK",
            "DKHBPPPTTPPPBHSK",
            "DKPHPPPPPPPPHASK",
            "DKSSHSSSSSSHSSSK",
            ".KKKKKKKKKKKKKKK",
            "....MMMMMM.MMM..",
            "....MMMMMM.MMM.."
        ]
    },
    disquete: {
        label: N_("Floppy disk"),
        vital: "disk",
        eyeBg: "M",
        grid: [
            "KKKKKKKKKKKKKKK.",
            "KPPPDDDDDDDPPPKK",
            "KPPPDDDKKDDPPPPK",
            "KPPPDDDKKDDPPPPK",
            "KPPPDDDDDDDPPPPK",
            "KHPPPPPPPPPPPPAK",
            "KPKKKKKKKKKKKKPK",
            "KPKMMMMMMMMMMKPK",
            "KPKMEEWMMEEWMKPK",
            "KPKMEEEMMEEEMKPK",
            "KPKMBBMMMMBBMKPK",
            "KPKMMMMTTMMMMKPK",
            "KSKMMMMMMMMMMKSK",
            "KKKKKKKKKKKKKKKK"
        ]
    }
}

const order = ["neko", "robo", "kitsune", "usagi", "yurei", "hacker", "sapo", "chip", "nvidia", "amd", "disquete"]

// linha onde fica o traço do olho fechado = última linha que contém um olho
for (const key of order) {
    const s = sprites[key]
    s.closedRow = s.grid.reduce((last, row, y) => row.indexOf("E") >= 0 ? y : last, -1)
    if (s.shadeFrom === undefined) s.shadeFrom = 99
}

function list() {
    return order.map(k => ({ key: k, label: sprites[k].label, vital: sprites[k].vital || "" }))
}

function get(name) {
    return sprites[name] || sprites.neko
}
