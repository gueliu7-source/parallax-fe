# Eventos do Parallax (Expulsion) convertidos

Tudo roda em `source/gameObjects/educator/EducatorStage.hx`. Os eventos do chart vem de `assets/songs/expulsion/events.json` (gerado por `tools/convert_chart.py`), disparados pelo tempo da musica.

## 1. Eventos do chart (27)

| Tempo | Evento | Parametros | O que faz |
|---|---|---|---|
| 0:00.00 | Camera Movement |  | sem efeito: a camera deste stage e fixa (como no original) |
| 0:02.40 | HScript Call | startCutscene | abre a porta (animacao "open") |
| 0:06.86 | HScript Call | midCutscene | fade para preto + zoom da camera da porta; troca o cenario para a camera principal |
| 0:09.26 | HScript Call | reveal | tira o preto da tela (1,35 s) |
| 0:09.26 | Camera Flash | [False, -16382458, 4, 'camGame'] | flash da camera (cor preta, 4 steps) |
| 0:23.31 | HScript Call | math | sobe o quadro-negro e faz uma pergunta aleatoria (5 s para responder) |
| 0:44.91 | HScript Call | math | sobe o quadro-negro e faz uma pergunta aleatoria (5 s para responder) |
| 1:17.83 | HScript Call | math | sobe o quadro-negro e faz uma pergunta aleatoria (5 s para responder) |
| 1:47.66 | HScript Call | bgTransition | animacao "transition" do cenario, zoom 1.2, flash e cenario escuro |
| 1:49.71 | Camera Movement |  | sem efeito: a camera deste stage e fixa (como no original) |
| 2:00.69 | HScript Call | math | sobe o quadro-negro e faz uma pergunta aleatoria (5 s para responder) |
| 2:23.06 | HScript Call | math | sobe o quadro-negro e faz uma pergunta aleatoria (5 s para responder) |
| 2:35.00 | HScript Call | veryCoolSuperTransition | zoom lento ate 1.2 e tela preta |
| 2:38.40 | HScript Call | glitch | HUD "evil" + efeito de compressao por 1,25 s |
| 2:47.61 | HScript Call | meatBG | modo "evil" (vida drenada pelo oponente), cenario "meat", quadro vermelho |
| 2:47.61 | Camera Flash | [False, -1, 7, 'camGame'] | flash da camera (cor branca, 7 steps) |
| 3:24.88 | HScript Call | math | sobe o quadro-negro e faz uma pergunta aleatoria (5 s para responder) |
| 4:32.07 | Add Camera Zoom | 0.1 | soma 0.1 ao zoom da camera |
| 4:32.60 | Add Camera Zoom | 0.1 | soma 0.1 ao zoom da camera |
| 4:33.13 | Add Camera Zoom | 0.1 | soma 0.1 ao zoom da camera |
| 4:34.89 | Add Camera Zoom | 0.1 | soma 0.1 ao zoom da camera |
| 4:35.42 | Add Camera Zoom | 0.1 | soma 0.1 ao zoom da camera |
| 4:35.95 | Add Camera Zoom | 0.1 | soma 0.1 ao zoom da camera |
| 4:43.36 | Add Camera Zoom | 0.1 | soma 0.1 ao zoom da camera |
| 4:45.09 | HScript Call | math | sobe o quadro-negro e faz uma pergunta aleatoria (5 s para responder) |
| 5:32.29 | Add Camera Zoom | 0.05 | soma 0.05 ao zoom da camera |
| 5:32.64 | Add Camera Zoom | 0.05 | soma 0.05 ao zoom da camera |

O evento "BPM Change" (175 -> 170 BPM, 4:25 aprox.) foi para dentro do chart (secao 116, `changeBPM`).

## 2. Efeitos por beat (script original, funcao beatHit)

| Beat | Acao |
|---|---|
| 28 | strums do jogador aparecem em fade escalonado |
| 30 / 94 / 158 | zoom 1.2 |
| 32 / 96 | flash branco, zoom 1.0 |
| 160 | cenario e oponente escurecem, flash, zoom 1.0 |
| 192 | cores normais, flash, zoom 1.1 |
| 288 | zoom 1.0 |
| 382 / 383 / 384 | zoom 1.1 / 1.3 / flash e zoom 1.0 (pulso por beat = 2) |
| 464 / 559 | pulso por beat 0 / 2 |
| 560 | flash vermelho, zoom 1.0 -> 0.8 |
| 623 / 624 | zoom 1.0 depois 0.8 / flash vermelho (+ glitch do cenario no modo completo) |
| 686-688 | pulso 0, zoom 1.0, tremor e camera balancando de lado a lado |
| 690, 698, 702, 769, 777 | rajadas de glitch no oponente |
| 723-724, 736-740 | tela preto e branco + tremor |
| 815-816 | pulso 2, flash vermelho, glitch permanente (0.05), rastro (trail) e zoom 1.0 -> 0.8 |
| 898, 953, 956, 972 | rajadas de glitch (voltam para 0.05) |
| 944 | zoom 0.9, pulso a cada 2 beats |
| 976 | fim: compressao, tremor, zoom 0.85 e tela preta |

## 3. Steps

| Step | Acao |
|---|---|
| 1272 | troca para a animacao de transicao do oponente |
| 1280 | oponente "FakeGlitch" |
| 1952 | oponente "Real" (com rastro depois do beat 816) |

## 4. Mecanicas

- 25 perguntas de matematica (digitos 0-9 e numpad, BACKSPACE apaga). Erros mostrados com X; 4 erros = game over.
- Modo evil: cada nota do oponente tira vida.
- Camera fixa (270, 325) com deslocamento nas animacoes de cantar, sem zoom padrao por beat.
- Strums do oponente invisiveis; strums do jogador centralizadas (como no mod original).
- Sem contagem regressiva.
- O BF fica invisivel nesta musica (no original ele e empurrado 300 px para baixo, fora da tela) e nao ha popups de combo/julgamento.

## 5. Diferencas conhecidas

- Shaders de sprite individual viraram filtros de camera (qualidade configuravel em options > Effects).
- "Preto e branco" e uma versao propria; o original usa um shader do ShaderToy.
- Camera Movement (2 eventos) nao tem efeito: o proprio script original fixa a camera.
