#!/usr/bin/env python3
"""
gen-interestrates-seed.py — Generate interestrates-mvp.dat for 06-interestrate IRATE-LOAD.

Per data-contracts §10.4 interestrate.idx (49 bytes COMP-3-heavy):
    RATE-KEY (13 bytes DISPLAY: PRODUCT 3 + TIER 2 + EFFECTIVE 8)
    RATE-TIER-MIN-JPY  S9(15) COMP-3 = 8 bytes
    RATE-TIER-MAX-JPY  S9(15) COMP-3 = 8
    RATE-ANNUAL-PCT    S9(3)V9(4) COMP-3 = 4 bytes (ceil((3+4+1)/2)=4)
    RATE-EFFECTIVE-TO  PIC 9(8)         = 8 bytes
    FILLER             PIC X(8)         = 8 bytes
    TOTAL: 13+8+8+4+8+8 = 49 bytes

Per seed-data-spec §2.5 (= 3 products × 3 effective dates = 9 records; single tier).
"""
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent.parent / \
    "subsystems/06-interestrate/data/interestrates-mvp.dat"

# RATES values are in 1/10000 (= V9(4)) units; e.g., 10 = 0.0010 = 0.10%
RATES = [
    ("001", 1, "20260101", 10,   "20261231"),  # 0.0010 = 0.10% (was: 0.001000)
    ("001", 1, "20270101", 15,   "20271231"),  # 0.0015
    ("001", 1, "20280101", 20,   "99991231"),  # 0.0020
    ("002", 1, "20260101", 500,  "20261231"),  # 0.0500 = 5.00% (note: 0.05 -> stored)
    ("002", 1, "20270101", 550,  "20271231"),
    ("002", 1, "20280101", 600,  "99991231"),
    ("003", 1, "20260101", 0,    "20261231"),
    ("003", 1, "20270101", 0,    "20271231"),
    ("003", 1, "20280101", 0,    "99991231"),
]

def comp3_encode(value, total_digits):
    """Encode signed int as PIC S9(N) COMP-3.
    Length = ceil((total_digits+1)/2) bytes."""
    sign = 0xC if value >= 0 else 0xD
    n = abs(value)
    digits = []
    while n > 0:
        digits.append(n % 10)
        n //= 10
    while len(digits) < total_digits:
        digits.append(0)
    digits = digits[:total_digits]
    digits.reverse()
    nibbles = digits + [sign]
    # Pad to even count
    if len(nibbles) % 2 == 1:
        nibbles = [0] + nibbles
    out = bytearray()
    for i in range(0, len(nibbles), 2):
        out.append((nibbles[i] << 4) | nibbles[i+1])
    return bytes(out)

def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "wb") as f:
        for prod, tier, eff_from, rate_micro, eff_to in RATES:
            rec = (
                prod.encode("ascii").ljust(3, b" ") +      # 3
                f"{tier:02d}".encode("ascii") +              # 2 (TIER-NO)
                eff_from.encode("ascii") +                  # 8
                comp3_encode(0, 15) +                       # 8 TIER-MIN
                comp3_encode(99999999999999, 15) +          # 8 TIER-MAX (no tier in MVP)
                comp3_encode(rate_micro, 7) +               # 4 ANNUAL-PCT
                eff_to.encode("ascii") +                    # 8
                b" " * 8                                     # 8 FILLER
            )
            assert len(rec) == 49, f"len={len(rec)} expected 49"
            f.write(rec)
            # No newline separator: COMP-3 may contain 0x0A
    print(f"Generated: {OUTPUT}")
    print(f"  Records: 9, File size: {OUTPUT.stat().st_size} bytes")
    print("  NOTE: NO newline separators (COMP-3 binary contains 0x0A; use SEQUENTIAL fixed-length FD).")

if __name__ == "__main__":
    main()
