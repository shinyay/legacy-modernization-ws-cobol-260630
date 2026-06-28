#!/usr/bin/env python3
"""
gen-branches-seed.py — Generate branches-mvp.dat for 02-branch BR-LOAD.

Per docs/architecture/data-contracts.md §10.4 branch.idx:
    PIC 9(3)  BRCH-CODE        (3 bytes)
    PIC X(40) BRCH-NAME-KANJI  (40 bytes; kanji name — UTF-8 truncated to 40)
    PIC X(40) BRCH-NAME-KANA   (40 bytes; katakana name)
    PIC X(20) BRCH-REGION      (20 bytes; Tokyo/Osaka/Aichi/Other)
    PIC 9(8)  BRCH-OPENED-DATE (8 bytes; YYYYMMDD)
    PIC X(1)  BRCH-STATUS      (1 byte; A=Active)
    PIC X(20) FILLER           (20 bytes)
    TOTAL: 132 bytes per record × 10 = 1320 bytes

Per seed-data-spec §2.2 (10 canonical branches).
"""
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent.parent / \
    "subsystems/02-branch/data/branches-mvp.dat"

BRANCHES = [
    ("001", "東京本店",   "トウキョウホンテン",   "Tokyo"),
    ("002", "新宿支店",   "シンジュクシテン",     "Tokyo"),
    ("003", "渋谷支店",   "シブヤシテン",         "Tokyo"),
    ("004", "池袋支店",   "イケブクロシテン",     "Tokyo"),
    ("005", "大阪支店",   "オオサカシテン",       "Osaka"),
    ("006", "梅田支店",   "ウメダシテン",         "Osaka"),
    ("007", "難波支店",   "ナンバシテン",         "Osaka"),
    ("008", "名古屋支店", "ナゴヤシテン",         "Aichi"),
    ("009", "栄支店",     "サカエシテン",         "Aichi"),
    ("010", "札幌支店",   "サッポロシテン",       "Other"),
]

def pad_bytes(s, n):
    """Encode string to UTF-8 and pad/truncate to exactly n bytes."""
    b = s.encode("utf-8")
    if len(b) > n:
        # Truncate at byte boundary safely (rough but ok for ASCII fallback)
        b = b[:n]
    return b.ljust(n, b" ")

def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "wb") as f:
        for code, kanji, kana, region in BRANCHES:
            rec = (
                code.encode("ascii").ljust(3, b" ") +   # BRCH-CODE 3
                pad_bytes(kanji, 40) +                   # BRCH-NAME-KANJI 40
                pad_bytes(kana, 40) +                    # BRCH-NAME-KANA 40
                pad_bytes(region, 20) +                  # BRCH-REGION 20
                b"20260101" +                            # BRCH-OPENED-DATE 8
                b"A" +                                   # BRCH-STATUS 1
                b" " * 20                                # FILLER 20
            )
            assert len(rec) == 132, f"Record length {len(rec)} != 132"
            f.write(rec)
            f.write(b"\n")
    print(f"Generated: {OUTPUT}")
    print(f"  Records: 10, File size: {OUTPUT.stat().st_size} bytes")

if __name__ == "__main__":
    main()
