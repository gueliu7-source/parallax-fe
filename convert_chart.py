#!/usr/bin/env python3
"""Converte o chart da Codename Engine (Parallax/Expulsion) para o formato FNF classico lido pela Forever Engine,
e extrai os eventos para events.json (a Forever 2021 nao tem sistema de eventos)."""
import json, sys, math

src = sys.argv[1]; dst = sys.argv[2]; ev_dst = sys.argv[3]
d = json.load(open(src))
meta_bpm = 175.0
bpm_changes = sorted([(e['time'], e['params'][0]) for e in d['events'] if e['name'] == 'BPM Change'])

# monta secoes de 4 beats respeitando mudancas de BPM
sections = []
t = 0.0; bpm = meta_bpm
end_time = max(n['time'] for sl in d['strumLines'][:2] for n in sl['notes']) + 2000
while t < end_time:
    changed = False
    for ct, nb in bpm_changes:
        if abs(ct - t) < 1.0:
            bpm = float(nb); changed = True
    length = 4 * 60000.0 / bpm
    sections.append({'start': t, 'end': t + length, 'bpm': bpm, 'changed': changed, 'notes': []})
    t += length

def section_for(time):
    for s in sections:
        if s['start'] - 0.5 <= time < s['end'] - 0.5:
            return s
    return sections[-1]

# strumLines[0] = oponente (dad) -> data 4-7 ; strumLines[1] = jogador (bf) -> data 0-3
# todas as secoes com mustHitSection=True: 0-3 = jogador, 4-7 = oponente
for n in d['strumLines'][1]['notes']:
    section_for(n['time'])['notes'].append([n['time'], n['id'], n.get('sLen', 0)])
for n in d['strumLines'][0]['notes']:
    section_for(n['time'])['notes'].append([n['time'], 4 + n['id'], n.get('sLen', 0)])

out_sections = []
for s in sections:
    s['notes'].sort(key=lambda x: (x[0], x[1]))
    out_sections.append({
        'sectionNotes': s['notes'], 'lengthInSteps': 16, 'typeOfSection': 0,
        'mustHitSection': True, 'bpm': s['bpm'], 'changeBPM': s['changed'], 'altAnim': False})

song = {'song': {'song': 'Expulsion', 'notes': out_sections, 'bpm': meta_bpm, 'needsVoices': True,
                 'speed': d['scrollSpeed'], 'player1': 'bf', 'player2': 'educatorFake',
                 'stage': 'educator', 'noteSkin': 'educator', 'validScore': True}}
json.dump(song, open(dst, 'w'))

events = []
for e in sorted(d['events'], key=lambda e: e['time']):
    if e['name'] == 'BPM Change':  # ja vai dentro das secoes
        continue
    events.append({'time': e['time'], 'name': e['name'], 'params': e['params']})
json.dump(events, open(ev_dst, 'w'), indent=1)

print('secoes:', len(out_sections), '| notas jogador:', sum(1 for s in sections for n in s['notes'] if n[1] < 4),
      '| notas oponente:', sum(1 for s in sections for n in s['notes'] if n[1] >= 4),
      '| sustains:', sum(1 for s in sections for n in s['notes'] if n[2] > 0), '| eventos:', len(events))
