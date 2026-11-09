.pragma library

// Todas as mascotes são 16 colunas × 14 linhas, um caractere por pixel.
// Os caracteres são PAPÉIS de cor; o tema decide a cor real (ver Mascot.qml):
//   .  transparente        K  contorno            P  cor principal (pelo/corpo)
//   S  sombra da principal H  brilho da principal M  detalhe claro (orelha, focinho)
//   C  visor               E  olho                W  brilho do olho
//   B  blush               T  boca                F  pele
//   D  hardware (fone)     A  LED (acompanha o humor)
// eyeBg: papel usado no lugar do olho quando ele fecha (o traço vai na última linha do olho).
// shadeFrom: linha a partir da qual P vira sombra automaticamente (só a neko usa).

const sprites = {
    neko: {
        label: "Neko cyborg",
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
        label: "Robô Unit-7",
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
        label: "Kitsune (raposa)",
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
        label: "Usagi (coelha)",
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
        label: "Yūrei (fantasma)",
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
        label: "Hacker-chan",
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
    }
}

const order = ["neko", "robo", "kitsune", "usagi", "yurei", "hacker"]

// linha onde fica o traço do olho fechado = última linha que contém um olho
for (const key of order) {
    const s = sprites[key]
    s.closedRow = s.grid.reduce((last, row, y) => row.indexOf("E") >= 0 ? y : last, -1)
    if (s.shadeFrom === undefined) s.shadeFrom = 99
}

function list() {
    return order.map(k => ({ key: k, label: sprites[k].label }))
}

function get(name) {
    return sprites[name] || sprites.neko
}
