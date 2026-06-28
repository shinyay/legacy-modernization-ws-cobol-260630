#!/usr/bin/env python3
"""
gen-feeschedules-seed.py — Generate feeschedules-mvp.dat for 07-feeschedule FEE-LOAD.

Per data-contracts §10.4 feeschedule.idx (41 bytes):
    FEE-KEY 12 bytes (CATEGORY 2 + TIER 2 + EFFECTIVE 8)
    FEE-TIER-MIN-JPY  S9(15) COMP-3 = 8 bytes
    FEE-TIER-MAX-JPY  S9(15) COMP-3 = 8
    FEE-AMOUNT-JPY    S9(9)  COMP-3 = 5 bytes (ceil((9+1)/2))
    FEE-EFFECTIVE-TO  PIC 9(8)         = 8
    TOTAL: 12+8+8+5+8 = 41 bytes

Per seed-data-spec §2.6 (= 4 categories × 3 tiers × 2 dates = 24 records).
"""
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent.parent / \
    "subsystems/07-feeschedule/data/feeschedules-mvp.dat"

# (category, tier, effective_from, fee_jpy, effective_to)
# Categories per DM §13.2: 10 deposit, 20 withdrawal, 30 transfer, 40 wire-out
# Tiers: 01=A premium, 02=B standard, 03=C basic
FEES = []
TIER_MAP = {1: "A", 2: "B", 3: "C"}
# 2026 baseline
for cat in [10, 20, 30, 40]:
    for tier_no in [1, 2, 3]:
        # Premium=lower fee, basic=higher fee
        if cat == 10:
            fees = {1: 0, 2: 0, 3: 0}  # deposits free
        elif cat == 20:
            fees = {1: 0, 2: 110, 3: 220}  # withdrawals
        elif cat == 30:
            fees = {1: 0, 2: 220, 3: 440}  # transfers
        elif cat == 40:
            fees = {1: 0, 2: 440, 3: 880}  # wire-out
        FEES.append((cat, tier_no, "20260101", fees[tier_no], "20261231"))

# 2027 with 10% hike
for cat in [10, 20, 30, 40]:
    for tier_no in [1, 2, 3]:
        if cat == 10:
            fees = {1: 0, 2: 0, 3: 0}
        elif cat == 20:
            fees = {1: 0, 2: 121, 3: 242}
        elif cat == 30:
            fees = {1: 0, 2: 242, 3: 484}
        elif cat == 40:
            fees = {1: 0, 2: 484, 3: 968}
        FEES.append((cat, tier_no, "20270101", fees[tier_no], "99991231"))

def comp3_encode(value, total_digits):
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
    if len(nibbles) % 2 == 1:
        nibbles = [0] + nibbles
    out = bytearray()
    for i in range(0, len(nibbles), 2):
        out.append((nibbles[i] << 4) | nibbles[i+1])
    return bytes(out)

def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "wb") as f:
        for cat, tier, eff_from, fee, eff_to in FEES:
            rec = (
                f"{cat:02d}".encode("ascii") +              # 2 CATEGORY
                f"{tier:02d}".encode("ascii") +              # 2 TIER-NO
                eff_from.encode("ascii") +                   # 8
                comp3_encode(0, 15) +                        # 8 TIER-MIN
                comp3_encode(99999999999999, 15) +           # 8 TIER-MAX
                comp3_encode(fee, 9) +                       # 5 AMOUNT
                eff_to.encode("ascii")                        # 8
            )
            assert len(rec) == 41, f"len={len(rec)} expected 41"
            f.write(rec)
    print(f"Generated: {OUTPUT}")
    print(f"  Records: {len(FEES)}, File size: {OUTPUT.stat().st_size} bytes")

if __name__ == "__main__":
    main()
