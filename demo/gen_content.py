#!/usr/bin/env python3
"""content_library.dart -> demo/content.js üreticisi."""
import re, io, json, os, functools

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, 'talk_buddy', 'lib', 'data', 'curriculum', 'content_library.dart')


def skip_string(s, i):
    q = s[i]; j = i + 1
    while j < len(s):
        if s[j] == '\\': j += 2; continue
        if s[j] == q: return j + 1
        j += 1
    return j


def match_bracket(s, i):
    depth = 0; j = i
    while j < len(s):
        c = s[j]
        if c in "'\"": j = skip_string(s, j); continue
        if c in '[(': depth += 1
        elif c in '])':
            depth -= 1
            if depth == 0: return j
        j += 1
    return -1


def strings_in(seg):
    out = []; i = 0
    while i < len(seg):
        if seg[i] in "'\"":
            q = seg[i]; j = i + 1; buf = []
            while j < len(seg) and seg[j] != q:
                if seg[j] == '\\':
                    j += 1
                    if j < len(seg): buf.append(seg[j])
                else: buf.append(seg[j])
                j += 1
            out.append(''.join(buf)); i = j + 1
        else: i += 1
    return out


def field(block, name):
    m = re.search(r'\b' + name + r':\s*\[', block)
    if not m: return None
    st = m.end() - 1; en = match_bracket(block, st)
    return block[st + 1:en]


def scalar(block, name):
    m = re.search(r'\b' + name + r":\s*'([^']*)'", block)
    if m: return m.group(1)
    m = re.search(r'\b' + name + r':\s*([\w.]+)', block)
    return m.group(1) if m else None


def main():
    src = io.open(SRC, encoding='utf-8').read()

    def toplevel(name):
        m = re.search(r'\b' + name + r'\s*=\s*(?:<[^>]+>)?\s*\[', src)
        if not m: return ''
        st = src.index('[', m.end() - 1); en = match_bracket(src, st)
        return src[st + 1:en]

    shared = {}
    for m in re.finditer(r"static const _(\w+) = SlotFill\('([^']+)',\s*\[", src):
        st = src.index('[', m.end() - 1); en = match_bracket(src, st)
        shared[m.group(1)] = {'key': m.group(2), 'values': strings_in(src[st + 1:en])}

    tseg = toplevel('templates')
    templates = []
    for m in re.finditer(r'ExerciseTemplate\(', tseg):
        st = m.end() - 1; en = match_bracket(tseg, st); b = tseg[st + 1:en]
        slots = []; seg = field(b, 'slots') or ''
        for sm in re.finditer(r"SlotFill\('([^']+)',\s*\[", seg):
            s2 = seg.index('[', sm.end() - 1); e2 = match_bracket(seg, s2)
            slots.append({'key': sm.group(1), 'values': strings_in(seg[s2 + 1:e2])})
        stripped = re.sub(r"SlotFill\('[^']+',\s*\[.*?\]\)", '', seg, flags=re.S)
        for ref in re.findall(r'_(\w+)', stripped):
            if ref in shared: slots.append(shared[ref])
        templates.append({
            'id': scalar(b, 'id'),
            'type': scalar(b, 'type').split('.')[-1],
            'domain': scalar(b, 'domain').split('.')[-1],
            'targetPhonemes': strings_in(field(b, 'targetPhonemes') or ''),
            'difficulty': int(scalar(b, 'difficulty') or 1),
            'emoji': scalar(b, 'emoji') or '',
            'prompts': strings_in(field(b, 'prompts') or ''),
            'slots': slots,
        })

    useg = toplevel('units')
    units = []
    for m in re.finditer(r'Unit\(', useg):
        st = m.end() - 1; en = match_bracket(useg, st); b = useg[st + 1:en]
        lessons = []; lseg = field(b, 'lessons') or ''
        for lm in re.finditer(r'Lesson\(', lseg):
            s2 = lm.end() - 1; e2 = match_bracket(lseg, s2); lb = lseg[s2 + 1:e2]
            lessons.append({
                'id': scalar(lb, 'id'), 'unitId': scalar(lb, 'unitId'),
                'title': scalar(lb, 'title'), 'index': int(scalar(lb, 'index')),
                'templateIds': strings_in(field(lb, 'templateIds') or ''),
                'exerciseCount': int(scalar(lb, 'exerciseCount') or 6),
            })
        units.append({
            'id': scalar(b, 'id'), 'title': scalar(b, 'title'),
            'subtitle': scalar(b, 'subtitle'), 'emoji': scalar(b, 'emoji'),
            'color': '#' + (scalar(b, 'colorValue') or '0xFF5B6CFF')[4:],
            'domain': scalar(b, 'domain').split('.')[-1],
            'targetPhonemes': strings_in(field(b, 'targetPhonemes') or ''),
            'minAgeMonths': int(scalar(b, 'minAgeMonths') or 24),
            'lessons': lessons,
        })

    J = lambda o: json.dumps(o, ensure_ascii=False, indent=2)
    out = ("/* ===========================================================================\n"
           "   Talk Buddy - Icerik kutuphanesi\n"
           "   OTOMATIK URETILDI: lib/data/curriculum/content_library.dart dosyasindan.\n"
           "   Elle duzenlemeyin; Dart tarafini degistirip 'python3 demo/gen_content.py' calistirin.\n"
           "   =========================================================================== */\n"
           "'use strict';\n\n"
           f"const TEMPLATES = {J(templates)};\n\n"
           f"const UNITS = {J(units)};\n\n"
           f"const OPENERS = {J(strings_in(toplevel('openers')))};\n\n"
           f"const CLOSERS = {J(strings_in(toplevel('closers')))};\n\n"
           f"const TRANSITIONS = {J(strings_in(toplevel('transitions')))};\n\n"
           "const ALL_LESSONS = UNITS.flatMap(u => u.lessons);\n"
           "const lessonById = id => ALL_LESSONS.find(l => l.id === id) || null;\n"
           "const unitById = id => UNITS.find(u => u.id === id) || null;\n")

    io.open(os.path.join(HERE, 'content.js'), 'w', encoding='utf-8', newline='\n').write(out)

    combos = sum(len(t['prompts']) * functools.reduce(
        lambda a, s: a * len(s['values']), t['slots'], 1) for t in templates)
    print('content.js uretildi')
    print('  Sablon      : %d' % len(templates))
    print('  Unite/Ders  : %d / %d' % (len(units), sum(len(u['lessons']) for u in units)))
    print('  Kombinasyon : %s' % format(combos, ',').replace(',', '.'))
    return combos


if __name__ == '__main__':
    main()
