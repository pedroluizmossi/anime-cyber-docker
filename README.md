# CyberDock

Plasmoid para KDE Plasma 6: uma neko cyborg em pixel art neon que vigia seus containers Docker.

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
- **Tema:** Neon, Matrix, Synthwave, Vaporwave, Akira, Ghost ou Personalizado (escolha a cor do pelo e do visor). O tema vale para a mascote, a aura e todo o HUD.
- **Tamanho do ícone:** 50–100% da altura do painel (a sprite sempre fica alinhada à grade de pixels, então continua nítida).
- **Intensidade do glow:** 0 (desligado) a 100%.
- **Mostrar contador** `rodando/total` no painel (o alerta `N!` aparece mesmo desligado).
- **Animações:** desligue para uma mascote estática.

**Comportamento**
- Intervalo de atualização (1–60 s; as estatísticas de CPU/mem rodam no dobro do intervalo, mínimo 5 s).
- Limites do modo ⚡ busy: uso da GPU (%) e CPU de um container (% por núcleo).

Para criar um tema, adicione uma entrada em `package/contents/ui/Themes.js` e inclua a chave em `order`.

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
    configAppearance.qml / configBehavior.qml
  contents/config/
    main.xml          # chaves de configuração (KConfigXT)
    config.qml        # páginas do diálogo de configuração
```

O desenho da mascote fica no array `grid` de `Mascot.qml` (16×14, um caractere por pixel).
