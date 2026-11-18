# Parallax -> Forever Engine (fase 1 + 2)

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
`EducatorStage.quality` (0 = sem shaders, 1 = rajadas curtas [padrao], 2 = completo). Comece em 1; se nao der 30 FPS, use 0.

## Limitacoes conhecidas
- Nao foi compilado nem testado (o ambiente onde foi escrito nao tem Haxe).
- Posicoes de BF/oponente estimadas (constantes no topo de EducatorStage.hx).
- Shaders por-sprite viraram filtros de camera; "preto e branco" e uma versao propria.
- Faltam: game over customizado, notas EDUCATOR_Notes, telas de titulo/aviso/creditos/opcoes, cursor.
