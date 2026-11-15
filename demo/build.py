#!/usr/bin/env python3
"""Talk Buddy demo derleyicisi: parçaları tek HTML dosyasına birleştirir."""
import io, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

PARTS = [
    ('@@CONTENT@@', 'content.js'),
    ('@@ENGINE@@',  'engine.js'),
    ('@@SPEECH@@',  'speech.js'),
    ('@@APP@@',     'app.js'),
    ('@@PANELS@@',  'panels.js'),
    ('@@NAV@@',     'nav.js'),
]

def strip_use_strict(src):
    return '\n'.join(l for l in src.split('\n') if l.strip() not in ("'use strict';", '"use strict";'))

def main():
    html = io.open(os.path.join(HERE, 'shell.html'), encoding='utf-8').read()
    total = 0
    for token, fname in PARTS:
        src = io.open(os.path.join(HERE, fname), encoding='utf-8').read()
        total += len(src)
        html = html.replace('/* ' + token + ' */', strip_use_strict(src))
    html = html.replace('<script>', "<script>\n'use strict';", 1)

    out = os.path.join(ROOT, 'talk_buddy_demo.html')
    io.open(out, 'w', encoding='utf-8', newline='\n').write(html)
    print('talk_buddy_demo.html yazildi')
    print('  JS kaynak : %.1f KB' % (total / 1024))
    print('  Toplam    : %.1f KB' % (len(html) / 1024))
    return out

if __name__ == '__main__':
    main()
