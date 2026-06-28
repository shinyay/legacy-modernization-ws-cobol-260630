#!/usr/bin/env python3
"""
gen-accounts-seed.py — Generate accounts-mvp.dat for 08-account ACCT-LOAD.

Per docs/architecture/data-contracts.md §10.4 account.idx (110 bytes):
    PIC 9(13) ACCT-NUMBER           13
    PIC 9(10) ACCT-CUST-ID          10
    PIC 9(3)  ACCT-PRODUCT-CODE      3
    PIC 9(3)  ACCT-BRANCH-CODE       3
    PIC 9(8)  ACCT-OPENED-DATE       8
    PIC 9(8)  ACCT-CLOSED-DATE       8 (00000000 if not closed)
    PIC X(1)  ACCT-STATUS            1 (= A for all seed)
    PIC S9(15) COMP-3 ACCT-OVERDRAFT-LIMIT 8 (=0 except 003 当座)
    PIC 9(4)  ACCT-TERM-DAYS         4 (=0 except 003 定期)
    PIC 9(8)  ACCT-DORMANCY-DATE     8 (= initial opened-date)
    PIC 9(14) ACCT-CREATED-TS       14
    PIC 9(14) ACCT-UPDATED-TS       14
    PIC X(16) FILLER                16
    TOTAL: 110 bytes per record × 200 = 22,000 bytes

ACCT-NUMBER format: BBB-PPP-NNNNNNN (3-digit branch + 3-digit product + 7-digit serial)
Per design: PIC 9(13) numeric; leading 0s preserved (= written as 13 digits).

NO newline separators (= COMP-3 binary contains 0x0A; use SEQUENTIAL fixed-length).
"""
import random
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent.parent / \
    "subsystems/08-account/data/accounts-mvp.dat"

random.seed(42)  # reproducible

# Per Phase 2 seed: 10 branches (001-010), 3 products (001/002/003)
BRANCHES = [f"{i:03d}" for i in range(1, 11)]
PRODUCTS = ["001", "002", "003"]  # Savings / TimeDeposit / Current

# Distribution: 200 accounts spread across 100 customers (cust 0000000002..0000000101)
# Each customer can have 1-3 accounts (= avg 2).

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
    count = 0
    with open(OUTPUT, "wb") as f:
        # Generate accounts for customers 2..101 (100 customers)
        # Each gets 1-3 accounts; we cap at 200 total
        for cust_id_n in range(2, 102):
            n_accts = random.choice([1, 2, 2, 2, 3])  # weighted toward 2
            if count + n_accts > 200:
                n_accts = 200 - count
            for j in range(n_accts):
                branch = random.choice(BRANCHES)
                product = random.choice(PRODUCTS)
                serial = count + 1  # 1..200
                acct_number = f"{branch}{product}{serial:07d}"  # 13 chars

                cust_id = f"{cust_id_n:010d}"
                opened_date = "20260101"
                closed_date = "00000000"
                status = "A"

                # Product-specific:
                if product == "003":  # 当座 = overdraft
                    overdraft = 1000000  # 1M JPY
                    term_days = "0000"
                elif product == "002":  # 定期1年
                    overdraft = 0
                    term_days = "0365"
                else:  # 001 普通
                    overdraft = 0
                    term_days = "0000"

                created_ts = "20260101000000"
                updated_ts = "20260101000000"

                rec = (
                    acct_number.encode("ascii") +
                    cust_id.encode("ascii") +
                    product.encode("ascii") +
                    branch.encode("ascii") +
                    opened_date.encode("ascii") +
                    closed_date.encode("ascii") +
                    status.encode("ascii") +
                    comp3_encode(overdraft, 15) +
                    term_days.encode("ascii") +
                    opened_date.encode("ascii") +  # dormancy = opened
                    created_ts.encode("ascii") +
                    updated_ts.encode("ascii") +
                    b" " * 16
                )
                assert len(rec) == 110, f"len={len(rec)} expected 110"
                f.write(rec)
                count += 1
            if count >= 200:
                break
    print(f"Generated: {OUTPUT}")
    print(f"  Records: {count}, File size: {OUTPUT.stat().st_size} bytes")
    print("  NOTE: NO newline (COMP-3 binary); use ORG SEQUENTIAL + RECORD CONTAINS 110.")


if __name__ == "__main__":
    main()
