# CyberDock

Plasmoid para KDE Plasma 6: uma mascote em pixel art neon que vigia seus containers Docker.

Mascotes: **Neko cyborg**, **Robô Unit-7**, **Kitsune**, **Usagi**, **Yūrei** e **Hacker-chan**.

| Humor | Quando | Animação |
|---|---|---|
| `sleep` | nenhum container rodando | olhos fechados, flutua devagar, "z" subindo |
| `idle` | tudo ok | balança de leve, pisca |
| `busy` | GPU ≥ 40% ou algum container com CPU ≥ 60% | pula, olhos amarelos, ⚡ |
| `alarm` | container `restarting`/`dead`/`unhealthy`, crash nos últimos 5 min ou Docker offline | treme, glitch RGB, aura vermelha, "!" |

No painel aparece a mascote + `rodando/total` (ou `N!` se houver problema).
Clique para abrir o HUD: lista de containers com status, CPU/mem, e botões de
logs (abre no Konsole), shell (`docker exec`), reiniciar, parar e iniciar.

## Configurações

Botão direito no widget → **Configurar CyberDock…**

**Aparência** (com prévia ao vivo dos 4 humores)
- **Mascote:** galeria clicável com as 6 mascotes.
- **Tema:** Neon, Matrix, Synthwave, Vaporwave, Akira, Ghost ou Personalizado (escolha a cor do pelo e do visor). O tema vale para a mascote, a aura e todo o HUD.
- **Tamanho do ícone:** 50–100% da altura do painel (a sprite sempre fica alinhada à grade de pixels, então continua nítida).
- **Intensidade do glow:** 0 (desligado) a 100%.
- **Mostrar contador** `rodando/total` no painel (o alerta `N!` aparece mesmo desligado).
- **Animações:** desligue para uma mascote estática.

**Comportamento**
- Intervalo de atualização (1–60 s; as estatísticas de CPU/mem rodam no dobro do intervalo, mínimo 5 s).
- Limites do modo ⚡ busy: uso da GPU (%) e CPU de um container (% por núcleo).

Para criar um tema, adicione uma entrada em `package/contents/ui/Themes.js` e inclua a chave em `order`.

### Criar uma mascote

Adicione uma entrada em `package/contents/ui/Sprites.js` (grade 16×14) e inclua a chave em `order`.
Os caracteres são *papéis* de cor, então qualquer tema funciona com qualquer mascote:

| | papel | | papel |
|---|---|---|---|
| `K` | contorno | `C` | visor |
| `P` | cor principal | `E` / `W` | olho / brilho do olho |
| `S` / `H` | sombra / brilho da principal | `B` | blush |
| `M` | detalhe claro (orelha, focinho) | `T` | boca |
| `F` | pele | `D` | hardware (fones) |
| `A` | LED que acompanha o humor | `.` | transparente |

`eyeBg` é o papel desenhado no lugar do olho quando ele fecha. Valide com `python3 dev/check-sprites.py`.

## Desempenho

A sprite só é redesenhada quando algo visível muda (piscada, cor do olho, glitch, LED);
flutuar e pular são só deslocamentos. O glow é recalculado apenas quando muda humor, tema,
mascote ou tamanho, e as animações do popup pausam enquanto ele está fechado.
Em 10 s no humor idle são ~4 redesenhos (antes: ~134 entre sprite e glow) —
na prática a animação não aumenta o consumo da GPU.

## Instalar / atualizar

```bash
./install.sh
```

Depois: botão direito no painel → **Adicionar widgets** → procure **CyberDock** e arraste para o painel.
Ao atualizar um widget que já está no painel: `systemctl --user restart plasma-plasmashell`.

Requisitos: Plasma 6, usuário no grupo `docker`, Konsole (logs/shell). `nvidia-smi` é opcional (indicador de GPU).

## Desenvolver

```bash
# janela isolada com dados reais
plasmawindowed com.pedro.cyberdock

# previews com dados falsos (salvam PNG)
qml6 dev/preview-mascot.qml -- /tmp/mascot.png
qml6 dev/preview-full.qml -- alarm /tmp/full.png     # sleep | idle | busy | alarm
qml6 dev/preview-themes.qml -- /tmp/themes.png       # galeria de todos os temas
qml6 dev/preview-mascots.qml -- neon /tmp/m.png      # todas as mascotes num tema
QT_FORCE_STDERR_LOGGING=1 qml6 dev/preview-perf.qml  # conta redesenhos por humor
python3 dev/check-sprites.py                         # valida as grades
qml6 dev/preview-config.qml -- synthwave /tmp/cfg.png  # página de configuração
```

## Estrutura

```
package/
  metadata.json
  contents/ui/
    main.qml          # coleta (docker ps / stats, nvidia-smi), humor e ações
    Mascot.qml        # sprite em Canvas + glow (MultiEffect) + animações por humor
    CompactView.qml   # visão do painel
    FullView.qml      # popup HUD (scanlines, glitch no título)
    ContainerRow.qml  # linha de container com ações
    ToolTipLite.qml
    Themes.js         # paletas dos temas
    Sprites.js        # desenhos das mascotes (papéis de cor)
    configAppearance.qml / configBehavior.qml
  contents/config/
    main.xml          # chaves de configuração (KConfigXT)
    config.qml        # páginas do diálogo de configuração
```


