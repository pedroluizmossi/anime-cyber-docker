<p align="center">
  <img src="docs/img/hero.png" alt="CyberDock — mascotes neon em pixel art que vigiam seus containers Docker" width="100%">
</p>

<p align="center">
  <img alt="KDE Plasma 6" src="https://img.shields.io/badge/KDE%20Plasma-6-1d99f3?logo=kde&logoColor=white">
  <img alt="Qt 6 / QML" src="https://img.shields.io/badge/Qt%206-QML-41cd52?logo=qt&logoColor=white">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-watcher-2496ed?logo=docker&logoColor=white">
  <img alt="Licença MIT" src="https://img.shields.io/badge/licen%C3%A7a-MIT-ff2bd6">
</p>

**CyberDock** é um widget (plasmoid) para o painel do KDE Plasma 6: uma mascote em pixel art
estilo cyberpunk/anime que vive na sua barra de tarefas e reage ao estado dos seus containers
Docker — dorme quando nada roda, pula quando a GPU esquenta e entra em pânico quando um
container cai. Clique nela para abrir um HUD neon com todos os containers e ações rápidas.

## ⚡ Instalar

```bash
curl -fsSL https://raw.githubusercontent.com/pedroluizmossi/anime-cyber-docker/main/install.sh | bash
```

Depois: botão direito no painel → **Adicionar widgets** → procure **CyberDock** → arraste para o painel.

<sub>O mesmo comando atualiza uma instalação existente. Para remover: `… | bash -s -- --uninstall`.
Não precisa de root nem de clonar o repositório — o script baixa só o pacote do widget e o instala
em `~/.local/share/plasma/plasmoids/` com o `kpackagetool6`.</sub>

**Requisitos:** KDE Plasma 6 · Docker acessível sem `sudo` (usuário no grupo `docker`) ·
Konsole para os botões de logs/shell · `nvidia-smi` opcional (indicador de GPU).

## Humores

<p align="center"><img src="docs/img/moods.gif" alt="Os quatro humores animados" width="720"></p>

| Humor | Quando | Animação |
|---|---|---|
| 💤 `sleep` | nenhum container rodando | olhos fechados, visor apagado, "z" subindo |
| 😺 `idle` | tudo certo | flutua de leve e pisca |
| ⚡ `busy` | GPU ≥ 40% ou um container com CPU ≥ 60% | pula, olhos e aura amarelos |
| 🚨 `alarm` | container `restarting`/`dead`/`unhealthy`, crash nos últimos 5 min ou Docker fora do ar | treme, glitch RGB, aura piscando, "!" |

Containers parados há muito tempo **não** disparam o alarme — só conta como crash quem
estava rodando e caiu nos últimos 5 minutos.

## No painel

<p align="center"><img src="docs/img/panel.png" alt="A mascote no painel do KDE em vários temas" width="560"></p>

A mascote fica nítida em qualquer tamanho (a sprite é alinhada à grade de pixels da tela) e mostra
`rodando/total` ao lado — ou `N!` quando há containers com problema.

## HUD

<p align="center"><img src="docs/img/popups.png" alt="Popup HUD nos humores idle, busy e alarm" width="100%"></p>

Clique na mascote para abrir o HUD: scanlines, título com glitch, contadores `RUN / STOP / ERR / GPU`
e a lista de containers com estado, CPU, memória e projeto do Compose. Cada linha tem botões para
**logs** (abre no Konsole), **shell** (`docker exec`), **reiniciar**, **parar** e **iniciar**.

## 6 mascotes

<p align="center"><img src="docs/img/mascots.png" alt="As seis mascotes nos quatro humores" width="700"></p>

**Neko cyborg** · **Robô Unit-7** · **Kitsune** · **Usagi** · **Yūrei** · **Hacker-chan**

## 6 temas (+ personalizado)

<p align="center"><img src="docs/img/themes.png" alt="Os seis temas de cor" width="760"></p>

Neon · Matrix · Synthwave · Vaporwave · Akira · Ghost — ou **Personalizado**, escolhendo as cores
do pelo e do visor. O tema vale para tudo: mascote, aura, HUD, botões e tooltips.

## Configurações

<p align="center"><img src="docs/img/config.png" alt="Página de configuração com prévia ao vivo" width="720"></p>

Botão direito na mascote → **Configurar CyberDock…**

**Aparência** — com prévia ao vivo dos 4 humores
- **Mascote:** galeria clicável com as 6 mascotes.
- **Tema:** os 6 temas ou Personalizado.
- **Tamanho do ícone:** 50–100% da altura do painel.
- **Intensidade do glow:** 0 (desligado) a 100%.
- **Mostrar contador** `rodando/total` (o alerta `N!` aparece mesmo desligado).
- **Animações:** desligue para uma mascote estática.

**Comportamento**
- Intervalo de atualização (1–60 s; CPU/mem são lidas no dobro do intervalo, mínimo 5 s).
- Limites do modo ⚡ busy: uso da GPU (%) e CPU de um container (% por núcleo).

## Desempenho

A animação praticamente não custa GPU: a sprite só é redesenhada quando algo visível muda
(piscada, cor dos olhos, glitch, LED), flutuar e pular são apenas deslocamentos, o glow é
recalculado só quando muda humor/tema/mascote/tamanho e as animações do HUD pausam com ele
fechado. No humor `idle` são ~4 redesenhos a cada 10 s. Medido numa RTX 4070 Ti SUPER:
23,8 W com animação × 23,9 W sem.

## Criar mascotes e temas

**Mascote:** adicione uma grade 16×14 em [`Sprites.js`](package/contents/ui/Sprites.js) e inclua a
chave em `order`. Os caracteres são *papéis* de cor, então qualquer tema funciona com qualquer mascote:

| | papel | | papel |
|---|---|---|---|
| `K` | contorno | `C` | visor |
| `P` | cor principal | `E` / `W` | olho / brilho do olho |
| `S` / `H` | sombra / brilho da principal | `B` | blush |
| `M` | detalhe claro (orelha, focinho) | `T` | boca |
| `F` | pele | `D` | hardware (fones) |
| `A` | LED que acompanha o humor | `.` | transparente |

`eyeBg` é o papel desenhado no lugar do olho quando ele fecha. Valide com `python3 dev/check-sprites.py`.

**Tema:** adicione uma paleta em [`Themes.js`](package/contents/ui/Themes.js) e inclua a chave em `order`.

## Desenvolver

```bash
git clone https://github.com/pedroluizmossi/anime-cyber-docker.git && cd anime-cyber-docker
./install.sh                                  # instala a partir do clone
systemctl --user restart plasma-plasmashell   # recarrega o widget no painel
plasmawindowed com.pedro.cyberdock            # roda numa janela isolada, com dados reais
```

Previews com dados de exemplo (salvam PNG, não precisam do Plasma):

```bash
qml6 dev/preview-mascots.qml -- neon /tmp/m.png        # todas as mascotes num tema
qml6 dev/preview-themes.qml -- /tmp/themes.png         # todos os temas
qml6 dev/preview-full.qml -- alarm /tmp/full.png       # popup: sleep | idle | busy | alarm
qml6 dev/preview-config.qml -- synthwave /tmp/cfg.png  # página de configuração
QT_FORCE_STDERR_LOGGING=1 qml6 dev/preview-perf.qml    # conta redesenhos por humor
python3 dev/check-sprites.py                           # valida as grades das mascotes
dev/make-docs.sh                                       # regera as imagens deste README
```

<details>
<summary>Estrutura do projeto</summary>

```
install.sh                  # instalador (local ou via curl | bash)
package/
  metadata.json
  contents/ui/
    main.qml                # coleta (docker ps / stats, nvidia-smi), humor e ações
    Mascot.qml              # sprite em Canvas + glow (MultiEffect) + animações
    Sprites.js              # desenhos das mascotes (papéis de cor)
    Themes.js               # paletas dos temas
    CompactView.qml         # visão do painel
    FullView.qml            # HUD (scanlines, glitch no título)
    ContainerRow.qml        # linha de container com ações
    ToolTipLite.qml
    configAppearance.qml    # página "Aparência"
    configBehavior.qml      # página "Comportamento"
  contents/config/
    main.xml                # chaves de configuração (KConfigXT)
    config.qml              # páginas do diálogo de configuração
dev/                        # previews, validação e gerador das imagens
docs/img/                   # imagens do README
```

</details>

## Licença

[MIT](LICENSE) — as mascotes e temas são originais deste projeto.
