#!/usr/bin/env python3
"""Reduz o atlas gigante do cenario (9760x11160 px = ~415 MB de textura) para 2 paginas de ~3920x3920
com os frames a 50% do tamanho. Intel HD 2000/3000 so suportam texturas de ate 8192 px, entao o original
nem carrega nessa GPU. Uso: python optimize_schoolhouse.py <Schoolhouse.png> <Schoolhouse.xml> <pasta_saida>"""
import re, sys, os
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
png, xml, out = sys.argv[1:4]
S = 0.5; COLS = 4; ROWS = 8; PER = COLS * ROWS
PAGES = [('schoolhouse','transition','dark'), ('meat',)]  # cada animacao fica inteira numa pagina
rows = []
for t in re.findall(r'<SubTexture ([^>]*)/>', open(xml).read()):
    rows.append(dict(re.findall(r'(\w+)="([^"]*)"', t)))
cw, ch = int(rows[0]['width']), int(rows[0]['height'])
dw, dh = round(cw * S), round(ch * S)
src = Image.open(png).convert('RGBA')
def anim(r): return re.sub(r'\d+$', '', r['name'])
cells = {}          # (x,y) original -> (pagina, indice na pagina)
order = []
for pi, group in enumerate(PAGES):
    n = 0
    for r in rows:
        if anim(r) in group:
            k = (int(r['x']), int(r['y']))
            if k not in cells:
                cells[k] = (pi, n); n += 1; order.append(k)
    assert n <= PER, 'pagina cheia'
pages = [Image.new('RGBA', (COLS * dw, ROWS * dh), (0, 0, 0, 0)) for _ in PAGES]
for k, (p, i) in cells.items():
    tile = src.crop((k[0], k[1], k[0] + cw, k[1] + ch)).resize((dw, dh), Image.LANCZOS)
    pages[p].paste(tile, ((i % COLS) * dw, (i // COLS) * dh))
os.makedirs(out, exist_ok=True)
for p, img in enumerate(pages):
    used = max(i for (cp, i) in cells.values() if cp == p) + 1
    img = img.crop((0, 0, COLS * dw, ((used + COLS - 1) // COLS) * dh))  # corta linhas vazias
    name = 'Schoolhouse' + 'ABCDEFG'[p]
    img.save(os.path.join(out, name + '.png'), optimize=True)
    lines = ['<?xml version="1.0" encoding="utf-8"?>', '<TextureAtlas imagePath="%s.png">' % name]
    for r in rows:
        cp, i = cells[(int(r['x']), int(r['y']))]
        if cp != p: continue
        lines.append('\t<SubTexture name="%s" x="%d" y="%d" width="%d" height="%d" frameX="%d" frameY="%d" frameWidth="%d" frameHeight="%d"/>' % (
            r['name'], (i % COLS) * dw, (i // COLS) * dh, dw, dh,
            round(int(r['frameX']) * S), round(int(r['frameY']) * S), round(int(r['frameWidth']) * S), round(int(r['frameHeight']) * S)))
    lines.append('</TextureAtlas>')
    open(os.path.join(out, name + '.xml'), 'w').write('\n'.join(lines))
    print(name, img.size, round(img.size[0] * img.size[1] * 4 / 1048576), 'MB de VRAM')
print('celulas unicas:', len(order), '| frames:', len(rows))
