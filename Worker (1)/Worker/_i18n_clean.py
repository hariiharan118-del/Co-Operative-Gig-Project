from pathlib import Path
import ast
import re

p = Path(r"e:\SIH\Worker\_i18n_build.py")
text = p.read_text(encoding="utf-8")
m = re.search(r"^TE = \{", text, re.M)
n = re.search(r"^MAPS = ", text, re.M)
head = text[: m.start()]
tail = text[n.start() :]
block = text[m.start() : n.start()]
good = {}
for line in block.splitlines():
    s = line.strip()
    if not s or s in ("TE = {", "}"):
        continue
    if s.endswith(","):
        s = s[:-1]
    try:
        pair = ast.literal_eval("{" + s + "}")
    except Exception:
        print("DROP", repr(line[:100]))
        continue
    if not isinstance(pair, dict) or len(pair) != 1:
        print("DROP2", repr(line[:100]))
        continue
    k, v = next(iter(pair.items()))
    if "\ufffd" in k or "\ufffd" in v:
        print("REPL", repr(k))
        continue
    if '":' in v:
        print("OVER", repr(k), repr(v[:40]))
        continue
    good[k] = v
print("KEPT", len(good))
lines = ["TE = {"]
for k, v in good.items():
    lines.append("    " + repr(k) + ": " + repr(v) + ",")
lines.append("}\n\n")
p.write_text(head + "\n".join(lines) + tail, encoding="utf-8")
print("rewrote")
