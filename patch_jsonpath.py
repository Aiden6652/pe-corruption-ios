#!/usr/bin/env python3
# Patch jsonpath 1.1.0's ArrayUtil.hx: thx.core >=0.43 removed containsExact.
# Adds a local containsExact and rewires calls.
import os, sys

found = []
base = os.path.expanduser('~/haxelib')
for root, dirs, files in os.walk(base):
    for f in files:
        if f == 'ArrayUtil.hx' and 'jsonpath' in root:
            found.append(os.path.join(root, f))

if not found:
    print('jsonpath ArrayUtil.hx not found, skip')
    sys.exit(0)

p = found[0]
s = open(p, encoding='utf-8').read()

method = '''
\tpublic static function containsExact<T>(arr:Array<T>, item:T, equals:T->T->Bool):Bool
\t{
\t\tfor (e in arr)
\t\t\tif (equals(e, item))
\t\t\t\treturn true;
\t\treturn false;
\t}
'''

if 'public static function containsExact' not in s:
    s = s.replace('class ArrayUtil\n{', 'class ArrayUtil\n{' + method, 1)
s = s.replace('thx.Arrays.containsExact', 'ArrayUtil.containsExact')
open(p, 'w', encoding='utf-8').write(s)
print('patched', p)
