"""IAST/romanization to Indic scripts. ASCII source only."""

from __future__ import annotations

import re

# independent, sign, extra_short_indep, extra_short_sign
# Northern scripts ignore short e/o distinction (map to e/o).
# Dravidian: e/o short, E/O long written as ē/ō.

_SCRIPTS = {
    "mr": {  # Devanagari (Marathi)
        "virama": "\u094d",
        "anusvara": "\u0902",
        "visarga": "\u0903",
        "vowel": {
            "a": ("\u0905", ""),
            "\u0101": ("\u0906", "\u093e"),  # ā
            "i": ("\u0907", "\u093f"),
            "\u012b": ("\u0908", "\u0940"),  # ī
            "u": ("\u0909", "\u0941"),
            "\u016b": ("\u090a", "\u0942"),  # ū
            "\u1e5b": ("\u090b", "\u0943"),  # ṛ
            "e": ("\u090f", "\u0947"),
            "\u0113": ("\u090f", "\u0947"),  # ē
            "ai": ("\u0910", "\u0948"),
            "o": ("\u0913", "\u094b"),
            "\u014d": ("\u0913", "\u094b"),  # ō
            "au": ("\u0914", "\u094c"),
        },
        "cons": None,  # filled below
    },
    "bn": {
        "virama": "\u09cd",
        "anusvara": "\u0982",
        "visarga": "\u0983",
        "vowel": {
            "a": ("\u0985", ""),
            "\u0101": ("\u0986", "\u09be"),
            "i": ("\u0987", "\u09bf"),
            "\u012b": ("\u0988", "\u09c0"),
            "u": ("\u0989", "\u09c1"),
            "\u016b": ("\u098a", "\u09c2"),
            "\u1e5b": ("\u098b", "\u09c3"),
            "e": ("\u098f", "\u09c7"),
            "\u0113": ("\u098f", "\u09c7"),
            "ai": ("\u0990", "\u09c8"),
            "o": ("\u0993", "\u09cb"),
            "\u014d": ("\u0993", "\u09cb"),
            "au": ("\u0994", "\u09cc"),
        },
        "cons": None,
    },
    "pa": {
        "virama": "\u0a4d",
        "anusvara": "\u0a02",
        "visarga": "\u0a03",
        "vowel": {
            "a": ("\u0a05", ""),
            "\u0101": ("\u0a06", "\u0a3e"),
            "i": ("\u0a07", "\u0a3f"),
            "\u012b": ("\u0a08", "\u0a40"),
            "u": ("\u0a09", "\u0a41"),
            "\u016b": ("\u0a0a", "\u0a42"),
            "\u1e5b": ("\u0a30\u0a3f", "\u0a4d\u0a30\u0a3f"),  # ṛ → ri
            "e": ("\u0a0f", "\u0a47"),
            "\u0113": ("\u0a0f", "\u0a47"),
            "ai": ("\u0a10", "\u0a48"),
            "o": ("\u0a13", "\u0a4b"),
            "\u014d": ("\u0a13", "\u0a4b"),
            "au": ("\u0a14", "\u0a4c"),
        },
        "cons": None,
    },
    "gu": {
        "virama": "\u0acd",
        "anusvara": "\u0a82",
        "visarga": "\u0a83",
        "vowel": {
            "a": ("\u0a85", ""),
            "\u0101": ("\u0a86", "\u0abe"),
            "i": ("\u0a87", "\u0abf"),
            "\u012b": ("\u0a88", "\u0ac0"),
            "u": ("\u0a89", "\u0ac1"),
            "\u016b": ("\u0a8a", "\u0ac2"),
            "\u1e5b": ("\u0a8b", "\u0ac3"),
            "e": ("\u0a8f", "\u0ac7"),
            "\u0113": ("\u0a8f", "\u0ac7"),
            "ai": ("\u0a90", "\u0ac8"),
            "o": ("\u0a93", "\u0acb"),
            "\u014d": ("\u0a93", "\u0acb"),
            "au": ("\u0a94", "\u0acc"),
        },
        "cons": None,
    },
    "te": {
        "virama": "\u0c4d",
        "anusvara": "\u0c02",
        "visarga": "\u0c03",
        "vowel": {
            "a": ("\u0c05", ""),
            "\u0101": ("\u0c06", "\u0c3e"),
            "i": ("\u0c07", "\u0c3f"),
            "\u012b": ("\u0c08", "\u0c40"),
            "u": ("\u0c09", "\u0c41"),
            "\u016b": ("\u0c0a", "\u0c42"),
            "\u1e5b": ("\u0c0b", "\u0c43"),
            "e": ("\u0c0e", "\u0c46"),  # short
            "\u0113": ("\u0c0f", "\u0c47"),  # ē
            "ai": ("\u0c10", "\u0c48"),
            "o": ("\u0c12", "\u0c4a"),  # short
            "\u014d": ("\u0c13", "\u0c4b"),  # ō
            "au": ("\u0c14", "\u0c4c"),
        },
        "cons": None,
    },
    "kn": {
        "virama": "\u0ccd",
        "anusvara": "\u0c82",
        "visarga": "\u0c83",
        "vowel": {
            "a": ("\u0c85", ""),
            "\u0101": ("\u0c86", "\u0cbe"),
            "i": ("\u0c87", "\u0cbf"),
            "\u012b": ("\u0c88", "\u0cc0"),
            "u": ("\u0c89", "\u0cc1"),
            "\u016b": ("\u0c8a", "\u0cc2"),
            "\u1e5b": ("\u0c8b", "\u0cc3"),
            "e": ("\u0c8e", "\u0cc6"),
            "\u0113": ("\u0c8f", "\u0cc7"),
            "ai": ("\u0c90", "\u0cc8"),
            "o": ("\u0c92", "\u0cca"),
            "\u014d": ("\u0c93", "\u0ccb"),
            "au": ("\u0c94", "\u0ccc"),
        },
        "cons": None,
    },
    "ml": {
        "virama": "\u0d4d",
        "anusvara": "\u0d02",
        "visarga": "\u0d03",
        "vowel": {
            "a": ("\u0d05", ""),
            "\u0101": ("\u0d06", "\u0d3e"),
            "i": ("\u0d07", "\u0d3f"),
            "\u012b": ("\u0d08", "\u0d40"),
            "u": ("\u0d09", "\u0d41"),
            "\u016b": ("\u0d0a", "\u0d42"),
            "\u1e5b": ("\u0d0b", "\u0d43"),
            "e": ("\u0d0e", "\u0d46"),
            "\u0113": ("\u0d0f", "\u0d47"),
            "ai": ("\u0d10", "\u0d48"),
            "o": ("\u0d12", "\u0d4a"),
            "\u014d": ("\u0d13", "\u0d4b"),
            "au": ("\u0d14", "\u0d4c"),
        },
        "cons": None,
    },
}

# Consonant letters in Sanskrit order; values are (mr, bn, pa, gu, te, kn, ml)
_CONS_ROWS = [
    ("k", "\u0915", "\u0995", "\u0a15", "\u0a95", "\u0c15", "\u0c95", "\u0d15"),
    ("kh", "\u0916", "\u0996", "\u0a16", "\u0a96", "\u0c16", "\u0c96", "\u0d16"),
    ("g", "\u0917", "\u0997", "\u0a17", "\u0a97", "\u0c17", "\u0c97", "\u0d17"),
    ("gh", "\u0918", "\u0998", "\u0a18", "\u0a98", "\u0c18", "\u0c98", "\u0d18"),
    ("\u1e45", "\u0919", "\u0999", "\u0a19", "\u0a99", "\u0c19", "\u0c99", "\u0d19"),  # ṅ
    ("c", "\u091a", "\u099a", "\u0a1a", "\u0a9a", "\u0c1a", "\u0c9a", "\u0d1a"),
    ("ch", "\u091b", "\u099b", "\u0a1b", "\u0a9b", "\u0c1b", "\u0c9b", "\u0d1b"),
    ("j", "\u091c", "\u099c", "\u0a1c", "\u0a9c", "\u0c1c", "\u0c9c", "\u0d1c"),
    ("jh", "\u091d", "\u099d", "\u0a1d", "\u0a9d", "\u0c1d", "\u0c9d", "\u0d1d"),
    ("\u00f1", "\u091e", "\u099e", "\u0a1e", "\u0a9e", "\u0c1e", "\u0c9e", "\u0d1e"),  # ñ
    ("\u1e6d", "\u091f", "\u099f", "\u0a1f", "\u0a9f", "\u0c1f", "\u0c9f", "\u0d1f"),  # ṭ
    ("\u1e6dh", "\u0920", "\u09a0", "\u0a20", "\u0aa0", "\u0c20", "\u0ca0", "\u0d20"),  # ṭh
    ("\u1e0d", "\u0921", "\u09a1", "\u0a21", "\u0aa1", "\u0c21", "\u0ca1", "\u0d21"),  # ḍ
    ("\u1e0dh", "\u0922", "\u09a2", "\u0a22", "\u0aa2", "\u0c22", "\u0ca2", "\u0d22"),  # ḍh
    ("\u1e47", "\u0923", "\u09a3", "\u0a23", "\u0aa3", "\u0c23", "\u0ca3", "\u0d23"),  # ṇ
    ("t", "\u0924", "\u09a4", "\u0a24", "\u0aa4", "\u0c24", "\u0ca4", "\u0d24"),
    ("th", "\u0925", "\u09a5", "\u0a25", "\u0aa5", "\u0c25", "\u0ca5", "\u0d25"),
    ("d", "\u0926", "\u09a6", "\u0a26", "\u0aa6", "\u0c26", "\u0ca6", "\u0d26"),
    ("dh", "\u0927", "\u09a7", "\u0a27", "\u0aa7", "\u0c27", "\u0ca7", "\u0d27"),
    ("n", "\u0928", "\u09a8", "\u0a28", "\u0aa8", "\u0c28", "\u0ca8", "\u0d28"),
    ("\u1e49", "\u0928", "\u09a8", "\u0a28", "\u0aa8", "\u0c28", "\u0ca8", "\u0d28"),  # ṉ
    ("p", "\u092a", "\u09aa", "\u0a2a", "\u0aaa", "\u0c2a", "\u0caa", "\u0d2a"),
    ("ph", "\u092b", "\u09ab", "\u0a2b", "\u0aab", "\u0c2b", "\u0cab", "\u0d2b"),
    ("b", "\u092c", "\u09ac", "\u0a2c", "\u0aac", "\u0c2c", "\u0cac", "\u0d2c"),
    ("bh", "\u092d", "\u09ad", "\u0a2d", "\u0aad", "\u0c2d", "\u0cad", "\u0d2d"),
    ("m", "\u092e", "\u09ae", "\u0a2e", "\u0aae", "\u0c2e", "\u0cae", "\u0d2e"),
    ("y", "\u092f", "\u09af", "\u0a2f", "\u0aaf", "\u0c2f", "\u0caf", "\u0d2f"),
    ("\u1e8f", "\u092f", "\u09af\u09bc", "\u0a2f", "\u0aaf", "\u0c2f", "\u0caf", "\u0d2f"),  # ẏ → bn য়
    ("r", "\u0930", "\u09b0", "\u0a30", "\u0ab0", "\u0c30", "\u0cb0", "\u0d30"),
    ("l", "\u0932", "\u09b2", "\u0a32", "\u0ab2", "\u0c32", "\u0cb2", "\u0d32"),
    ("v", "\u0935", "\u09ac", "\u0a35", "\u0ab5", "\u0c35", "\u0cb5", "\u0d35"),  # bn v→ব
    ("w", "\u0935", "\u09ac", "\u0a35", "\u0ab5", "\u0c35", "\u0cb5", "\u0d35"),
    ("\u015b", "\u0936", "\u09b6", "\u0a36", "\u0ab6", "\u0c36", "\u0cb6", "\u0d36"),  # ś
    ("\u1e63", "\u0937", "\u09b7", "\u0a36", "\u0ab7", "\u0c37", "\u0cb7", "\u0d37"),  # ṣ
    ("s", "\u0938", "\u09b8", "\u0a38", "\u0ab8", "\u0c38", "\u0cb8", "\u0d38"),
    ("h", "\u0939", "\u09b9", "\u0a39", "\u0ab9", "\u0c39", "\u0cb9", "\u0d39"),
    ("\u1e37", "\u0933", "\u09b2", "\u0a33", "\u0ab3", "\u0c33", "\u0cb3", "\u0d33"),  # ḷ
    ("\u1e3b", "\u0933", "\u09b2", "\u0a33", "\u0ab3", "\u0c33", "\u0cb3", "\u0d34"),  # ḻ → ml ഴ
    ("\u1e5f", "\u0930", "\u09b0", "\u0a30", "\u0ab0", "\u0c31", "\u0cb1", "\u0d31"),  # ṟ
    ("f", "\u092b", "\u09ab", "\u0a2b", "\u0aab", "\u0c2b", "\u0cab", "\u0d2b"),
    ("z", "\u091c", "\u099c", "\u0a1c", "\u0a9c", "\u0c1c", "\u0c9c", "\u0d1c"),
]

_LANG_INDEX = {"mr": 1, "bn": 2, "pa": 3, "gu": 4, "te": 5, "kn": 6, "ml": 7}

for lang, idx in _LANG_INDEX.items():
    _SCRIPTS[lang]["cons"] = {row[0]: row[idx] for row in _CONS_ROWS}
    vows = _SCRIPTS[lang]["vowel"]
    vows["\u014f"] = vows["o"]  # ŏ
    vows["\u0115"] = vows["e"]  # ĕ

_CONS_KEYS = sorted(_SCRIPTS["mr"]["cons"], key=len, reverse=True)
_VOWEL_KEYS = sorted(_SCRIPTS["te"]["vowel"], key=len, reverse=True)

_KEEP = {
    "KRIYANTA",
    "Razorpay",
    "Android",
    "iOS",
    "PIN",
    "OTP",
    "SMS",
    "UPI",
    "ETA",
    "ID",
    "OK",
}

_IAST_LETTERS = (
    r"A-Za-z\u0101\u012b\u016b\u0113\u014d\u1e5b\u1e45\u00f1\u1e6d\u1e0d"
    r"\u1e47\u015b\u1e63\u1e37\u1e3b\u1e5f\u1e43\u1e25\u1e8f\u1e49\u014f\u0115"
)

_TOKEN = re.compile(
    r"(\{\}|KRIYANTA|Razorpay|Android|iOS|name@example\.com|"
    r"[A-Z]{2,}|\d+|"
    rf"[{_IAST_LETTERS}]+|"
    r"\s+|.)"
)


def _match_prefix(text: str, keys: list[str]) -> str | None:
    for key in keys:
        if text.startswith(key):
            return key
    return None


def _word_to_script(word: str, script: str) -> str:
    spec = _SCRIPTS[script]
    cons_map = spec["cons"]
    vowel_map = spec["vowel"]
    virama = spec["virama"]
    out: list[str] = []
    i = 0
    pending: list[str] = []

    def flush(vowel: str | None) -> None:
        if not pending:
            if vowel:
                out.append(vowel_map[vowel][0])
            return
        if (
            script == "pa"
            and len(pending) >= 2
            and pending[-1] == pending[-2]
        ):
            for cons in pending[:-2]:
                out.append(cons + virama)
            out.append("\u0a71")  # addak
            last = pending[-1]
            if vowel is None:
                out.append(last + virama)
            else:
                out.append(last)
                if vowel != "a":
                    out.append(vowel_map[vowel][1])
            pending.clear()
            return
        if (
            script == "ml"
            and vowel is None
            and len(pending) == 1
            and pending[0]
            in {
                "\u0d28": "\u0d7b",
                "\u0d30": "\u0d7c",
                "\u0d32": "\u0d7d",
                "\u0d33": "\u0d7e",
            }
        ):
            chillu = {
                "\u0d28": "\u0d7b",
                "\u0d30": "\u0d7c",
                "\u0d32": "\u0d7d",
                "\u0d33": "\u0d7e",
            }
            out.append(chillu[pending[0]])
            pending.clear()
            return
        for cons in pending[:-1]:
            out.append(cons + virama)
        last = pending[-1]
        if vowel is None:
            out.append(last + virama)
        else:
            out.append(last)
            if vowel != "a":
                out.append(vowel_map[vowel][1])
        pending.clear()

    while i < len(word):
        ch = word[i]
        if ch == "\u1e43":  # ṃ
            flush("a" if pending else None)
            rest = word[i + 1 :]
            if script == "pa" and rest and _match_prefix(rest, _CONS_KEYS):
                out.append("\u0a70")  # tippi
            else:
                out.append(spec["anusvara"])
            i += 1
            continue
        if ch == "\u1e25":  # ḥ
            flush("a" if pending else None)
            out.append(spec["visarga"])
            i += 1
            continue
        cons = _match_prefix(word[i:], _CONS_KEYS)
        if cons:
            pending.append(cons_map[cons])
            i += len(cons)
            continue
        vow = _match_prefix(word[i:], _VOWEL_KEYS)
        if vow:
            flush(vow)
            i += len(vow)
            continue
        flush("a" if pending else None)
        out.append(ch)
        i += 1
    if pending:
        # Northern scripts keep inherent a; Dravidian loanwords use virama.
        if script in {"mr", "bn", "gu", "pa"}:
            flush("a")
        else:
            flush(None)
    return "".join(out)


def iast(text: str, script: str) -> str:
    parts: list[str] = []
    for tok in _TOKEN.findall(text):
        if not tok:
            continue
        if (
            tok in _KEEP
            or tok == "{}"
            or tok == "name@example.com"
            or tok.isdigit()
            or tok in {"Android", "iOS"}
            or (tok.isascii() and tok.isupper() and len(tok) >= 2)
        ):
            parts.append(tok)
        elif re.fullmatch(rf"[{_IAST_LETTERS}]+", tok):
            parts.append(_word_to_script(tok, script))
        else:
            parts.append(tok)
    return "".join(parts)
