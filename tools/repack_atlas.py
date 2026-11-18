#!/usr/bin/env python3
"""Reduz e reempacota um atlas Sparrow (png + xml) com 'shelf packing'.
Uso: python repack_atlas.py <atlas.png> <atlas.xml> <escala> <saida_sem_extensao> [largura_max=4096]
Frames repetidos (mesma regiao) sao guardados uma unica vez; frameX/frameY/frameWidth/frameHeight sao reescalados."""
import re, sys, os
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
png, xml, S, out = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
MAXW = int(sys.argv[5]) if len(sys.argv) > 5 else 4096
PAD = 2
src = Image.open(png).convert('RGBA')
head = open(xml).read()
rows = [dict(re.findall(r'(\w+)="([^"]*)"', t)) for t in re.findall(r'<SubTexture ([^>]*)/>', head)]
key = lambda r: (int(r['x']), int(r['y']), int(r['width']), int(r['height']))
uniq = {}
for r in rows: uniq.setdefault(key(r), None)
sz = lambda k: (max(1, round(k[2] * S)), max(1, round(k[3] * S)))
order = sorted(uniq, key=lambda k: -sz(k)[1])
x = y = shelf_h = 0; maxy = 0
for k in order:
    w, h = sz(k)
    if x + w + PAD > MAXW: x = 0; y += shelf_h + PAD; shelf_h = 0
    uniq[k] = (x, y); x += w + PAD; shelf_h = max(shelf_h, h); maxy = max(maxy, y + h)
W = MAXW if len(order) > 1 else sz(order[0])[0]
H = maxy
page = Image.new('RGBA', (W, H), (0, 0, 0, 0))
for k, (px, py) in uniq.items():
    w, h = sz(k)
    page.paste(src.crop((k[0], k[1], k[0] + k[2], k[1] + k[3])).resize((w, h), Image.LANCZOS), (px, py))
page.save(out + '.png', optimize=True)
name = os.path.basename(out)
lines = ['<?xml version="1.0" encoding="utf-8"?>', '<TextureAtlas imagePath="%s.png">' % name]
for r in rows:
    px, py = uniq[key(r)]; w, h = sz(key(r))
    a = 'name="%s" x="%d" y="%d" width="%d" height="%d"' % (r['name'], px, py, w, h)
    if 'frameX' in r:
        a += ' frameX="%d" frameY="%d" frameWidth="%d" frameHeight="%d"' % (round(int(r['frameX']) * S), round(int(r['frameY']) * S), round(int(r['frameWidth']) * S), round(int(r['frameHeight']) * S))
    lines.append('\t<SubTexture %s/>' % a)
lines.append('</TextureAtlas>')
open(out + '.xml', 'w').write('\n'.join(lines))
print(name, (W, H), round(W * H * 4 / 1048576, 1), 'MB de VRAM |', len(order), 'regioes unicas |', len(rows), 'frames')
