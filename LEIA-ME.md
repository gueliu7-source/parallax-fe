# Parallax -> Forever Engine (port completo, fase 6)

## Conteudo deste zip
- `source/` e `Project.xml`: arquivos da Forever **ja modificados** (copie por cima da pasta `Forever-Engine-master`, mantendo os caminhos).
  - `source/gameObjects/educator/EducatorStage.hx` (NOVO): stage, eventos do chart, troca de personagens, shaders e minigame de matematica.
  - `PlayState.hx`, `Character.hx`, `Stage.hx`, `ClassHUD.hx`, `Main.hx`: ganchos minimos (jogo agora em 1280x960, janela 960x720).
- `assets/songs/expulsion/`: chart convertido (`expulsion-hard.json`, `expulsion.json`) e `events.json`.
- `assets/images/bgs/educator/`: cenario otimizado (415 MB -> ~109 MB de textura, em 2 paginas).
- `copiar_assets.bat`: copia o resto dos assets do mod (imagens, shaders, fontes, sons, musicas, Inst/Voices).
- `.github/workflows/buildwin.yml`: compila o .exe na nuvem do GitHub (nao precisa instalar Haxe no seu PC).
- `tools/`: scripts usados (reduzir atlas, converter chart).

## Passo a passo
1. Extraia a Forever e o Parallax em pastas.
2. Copie `source/`, `Project.xml`, `assets/` e `.github/` deste zip por cima da Forever (substituir).
3. Rode: `copiar_assets.bat "C:\...\Parallax" "C:\...\Forever-Engine-master"` (ele apaga o atlas original gigante; o jogo usa o otimizado SchoolhouseA/B).
4. Crie um repositorio no GitHub, envie a pasta da Forever, abra a aba **Actions > BuildWin > Run workflow**.
5. Quando terminar, baixe o artefato `windowsBuild`: la dentro esta o `.exe`.

## Qualidade dos efeitos (30 FPS)
Edite `assets/data/parallax.json` (Bloco de Notas, dentro da pasta do jogo): `"quality"`: 0 = sem shaders, 1 = rajadas curtas [padrao], 2 = completo; `"math": false` desliga o minigame. Comece em 1; se nao der 30 FPS, use 0.

## Limitacoes conhecidas
- Nao foi compilado nem testado (o ambiente onde foi escrito nao tem Haxe).
- Posicoes de BF/oponente estimadas (constantes no topo de EducatorStage.hx).
- Shaders por-sprite viraram filtros de camera; "preto e branco" e uma versao propria.
- O jogo abre no aviso do mod (ENTER), depois no titulo (mouse ou setas): play, options, credits. As opcoes (matematica, cursor Schoolhouse, qualidade dos efeitos) ficam salvas pelo proprio jogo.
- Discord Rich Presence usa o clientID e o icone do mod (data/config/discord.json).
- As animacoes da janela do original (descer no aviso, "pular" no titulo) foram portadas; BACK no aviso pula a animacao.

## Atualizar o repositorio no GitHub (Codespace)
1. Suba este zip para o Codespace (arraste para a lista de arquivos).
2. No terminal: `git pull`, depois
   `unzip -q -o parallax-forever-fase7.zip && cp -r parallax-forever/. . && rm -rf parallax-forever parallax-forever-fase7.zip`
3. `git add -A && git commit -m "fase 7" && git push` (o build roda sozinho na aba Actions).


Se voce ja tinha subido a fase anterior, apague os atlases antigos do menu antes do push:
`rm -f assets/images/menus/title/Paralaxlogo.* assets/images/menus/title/pressenterparralaxxx.*`

## Eventos
Veja `docs/EVENTOS-PARALLAX.md` (todos os eventos do chart, os efeitos por beat e os steps, com o que cada um faz).

## Menus (fase 6)
- Titulo: play (Expulsion direto), freeplay, story mode (menus da Forever com as musicas originais), options, credits.
- Options: Math Mechanics, Notes (MOD pixel / DEFAULT), Schoolhouse Cursor, Effects, e "Game Settings" que abre as opcoes completas da engine (Preferences, Controls, Note Skin, Downscroll...). Todas voltam para o titulo/opcoes do Parallax.
- Corrigido: o Stage.hx da Forever escolhia o cenario pelo NOME da musica e ignorava o stage do chart; agora 'expulsion' -> stage 'educator'.

## Diagnostico e ajuste de posicoes
- Ao abrir *Expulsion*, o jogo grava `parallax-debug.txt` na pasta do .exe (cameras, posicao/visibilidade do BF, oponente, HUD...). Se algo aparecer errado, envie o conteudo desse arquivo.
- `assets/data/parallax.json` aceita `"bf": [x, y]`, `"dad": [x, y]` e `"camera": [x, y]` para ajustar posicoes sem recompilar.

## Atualizacao da fase 6 (correcoes comparadas com o mod original)
- Pasta de UI renomeada: `assets/images/ui/educator` -> `assets/images/uiEducator` (no Windows `ui` e `UI` sao a mesma pasta e o jogo nao achava a moldura, o quadro-negro e os icones). No repositorio, rode `git mv assets/images/ui/educator assets/images/uiEducator` ANTES de copiar este zip.
- Causa raiz de varias coisas: o Main.hx cria o jogo com zoom 0.75 (janela 960x720) mas o PlayState levava as cameras de HUD/strums a zoom 1, deixando notas e HUD 33% maiores e as strums fora do topo da tela. Agora todos os zooms sao multiplicados por Main.zoom.
- A moldura volta a ocupar 0..960 (o original centralizava com altura 720); o quadro-negro tambem.
- Strums no alto (y=50), alinhadas com as notas; textos "Health" e "Accuracy | Misses | Score" do mod com a fonte schoolhouse.
- Titulo: itens do menu e logo nao aparecem mais na tela errada.
