#!/usr/bin/env python3
"""
gen-products-seed.py — Generate products-mvp.dat for 05-product PROD-LOAD.

Per data-contracts §10.4 product.idx (130 bytes):
    PIC 9(3)  PROD-CODE           3
    PIC X(40) PROD-NAME-KANJI    40
    PIC X(40) PROD-NAME-KANA     40
    PIC X(1)  PROD-TYPE           1   S=Savings C=Checking T=TimeDeposit
    PIC X(1)  PROD-INTEREST-TYPE  1   N/D/M/Y
    PIC X(1)  PROD-ALLOW-OVERDRAFT 1  Y/N
    PIC S9(15) COMP-3 PROD-MIN-BALANCE 8
    PIC 9(4)  PROD-TERM-DAYS      4
    PIC 9(8)  PROD-EFFECTIVE-FROM 8
    PIC 9(8)  PROD-EFFECTIVE-TO   8
    PIC X(16) FILLER             16
"""
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent.parent / \
    "subsystems/05-product/data/products-mvp.dat"

# (code, kanji, kana, type, interest_type, overdraft, min_balance, term_days)
PRODUCTS = [
    ("001", "普通預金",         "フツウヨキン",     "S", "D", "N", 0,        0),
    ("002", "定期預金1年",      "テイキヨキン1ネン", "T", "Y", "N", 100000, 365),
    ("003", "当座預金",         "トウザヨキン",     "C", "N", "Y", 0,        0),
]

def pad_bytes(s, n):
    b = s.encode("utf-8")
    if len(b) > n:
        b = b[:n]
    return b.ljust(n, b" ")

def comp3_encode(value, length=8):
    """Encode signed integer as PIC S9(15) COMP-3 (packed decimal); 8 bytes."""
    # Format: each byte = 2 BCD digits; last nibble = sign (C=positive, D=negative)
    sign = 0xC if value >= 0 else 0xD
    n = abs(value)
    digits = []
    while n > 0:
        digits.append(n % 10)
        n //= 10
    # PIC S9(15) -> 15 digits; pad with 0s on left
    while len(digits) < 15:
        digits.append(0)
    digits = digits[:15]
    digits.reverse()
    # Pack: 15 digits + 1 sign nibble = 16 nibbles = 8 bytes
    nibbles = digits + [sign]
    out = bytearray()
    for i in range(0, 16, 2):
        b = (nibbles[i] << 4) | nibbles[i+1]
        out.append(b)
    return bytes(out)

def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "wb") as f:
        for code, kanji, kana, ptype, itype, ovd, minbal, term in PRODUCTS:
            rec = (
                code.encode("ascii").ljust(3, b" ") +        # 3
                pad_bytes(kanji, 40) +                        # 40
                pad_bytes(kana, 40) +                         # 40
                ptype.encode("ascii") +                       # 1
                itype.encode("ascii") +                       # 1
                ovd.encode("ascii") +                         # 1
                comp3_encode(minbal, 8) +                     # 8
                f"{term:04d}".encode("ascii") +               # 4
                b"20260101" +                                  # 8
                b"99991231" +                                  # 8
                b" " * 16                                      # 16
            )
            assert len(rec) == 130, f"Record length {len(rec)} != 130"
            f.write(rec)
    print(f"Generated: {OUTPUT}")
    print(f"  Records: 3, File size: {OUTPUT.stat().st_size} bytes")

if __name__ == "__main__":
    main()
