#!/usr/bin/env python3
"""
gen-customers-seed.py — Generate customers-mvp.dat for 03-customer CUST-OPEN bulk.

Per data-contracts §10.4 customer.idx (388 bytes):
    PIC 9(10) CUST-ID            10
    PIC X(50) CUST-KANA-NAME     50
    PIC X(60) CUST-KANJI-NAME    60
    PIC X(15) CUST-PHONE         15
    PIC X(200) CUST-ADDRESS     200
    PIC 9(8)  CUST-OPENED-DATE    8
    PIC X(1)  CUST-STATUS         1   A/S/C
    PIC 9(14) CUST-CREATED-TS    14
    PIC 9(14) CUST-UPDATED-TS    14
    PIC X(20) FILLER             20  (= last byte 4th tier; per Wave 5 spec adds tier)

NOTE: shared/copy ws-codes / seed-data-spec uses tier field, but data-contracts
§10.4 uses 20-byte FILLER. Per design priority data-contracts wins; tier
stored at byte 376-376 within FILLER (first byte of FILLER) for forward-compat.
"""
import random
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent.parent / \
    "subsystems/03-customer/data/customers-mvp.dat"

random.seed(42)  # reproducible

# 50 common Japanese surnames (kanji + kana)
SURNAMES = [
    ("田中", "タナカ"), ("佐藤", "サトウ"), ("鈴木", "スズキ"), ("高橋", "タカハシ"),
    ("渡辺", "ワタナベ"), ("伊藤", "イトウ"), ("山本", "ヤマモト"), ("中村", "ナカムラ"),
    ("小林", "コバヤシ"), ("加藤", "カトウ"), ("吉田", "ヨシダ"), ("山田", "ヤマダ"),
    ("佐々木", "ササキ"), ("山口", "ヤマグチ"), ("松本", "マツモト"), ("井上", "イノウエ"),
    ("木村", "キムラ"), ("林", "ハヤシ"), ("斉藤", "サイトウ"), ("清水", "シミズ"),
    ("山崎", "ヤマザキ"), ("森", "モリ"), ("阿部", "アベ"), ("池田", "イケダ"),
    ("橋本", "ハシモト"), ("石川", "イシカワ"), ("中島", "ナカジマ"), ("前田", "マエダ"),
    ("藤田", "フジタ"), ("後藤", "ゴトウ"), ("岡田", "オカダ"), ("長谷川", "ハセガワ"),
    ("村上", "ムラカミ"), ("近藤", "コンドウ"), ("石井", "イシイ"), ("斎藤", "サイトウ"),
    ("坂本", "サカモト"), ("遠藤", "エンドウ"), ("青木", "アオキ"), ("藤井", "フジイ"),
    ("西村", "ニシムラ"), ("福田", "フクダ"), ("太田", "オオタ"), ("三浦", "ミウラ"),
    ("藤原", "フジワラ"), ("岡本", "オカモト"), ("松田", "マツダ"), ("中川", "ナカガワ"),
    ("中野", "ナカノ"), ("原田", "ハラダ"),
]

# 50 given names mix (male + female)
GIVEN_NAMES_M = [
    ("太郎", "タロウ"), ("一郎", "イチロウ"), ("健一", "ケンイチ"), ("拓哉", "タクヤ"),
    ("翔太", "ショウタ"), ("大輔", "ダイスケ"), ("健太", "ケンタ"), ("雄太", "ユウタ"),
    ("亮", "リョウ"), ("誠", "マコト"), ("智樹", "トモキ"), ("拓也", "タクヤ"),
    ("和也", "カズヤ"), ("勇人", "ハヤト"), ("達也", "タツヤ"), ("浩二", "コウジ"),
    ("正樹", "マサキ"), ("聡", "サトシ"), ("修", "オサム"), ("浩", "ヒロシ"),
    ("学", "マナブ"), ("豊", "ユタカ"), ("茂", "シゲル"), ("清", "キヨシ"),
    ("光", "ヒカル"),
]

GIVEN_NAMES_F = [
    ("花子", "ハナコ"), ("雅子", "マサコ"), ("美咲", "ミサキ"), ("優子", "ユウコ"),
    ("智子", "トモコ"), ("由美", "ユミ"), ("恵子", "ケイコ"), ("洋子", "ヨウコ"),
    ("聡美", "サトミ"), ("和美", "カズミ"), ("真理子", "マリコ"), ("陽子", "ヨウコ"),
    ("典子", "ノリコ"), ("直子", "ナオコ"), ("理恵", "リエ"), ("綾", "アヤ"),
    ("舞", "マイ"), ("亜希子", "アキコ"), ("紗希", "サキ"), ("奈々", "ナナ"),
    ("沙織", "サオリ"), ("由香", "ユカ"), ("彩", "アヤ"), ("茜", "アカネ"),
    ("七海", "ナナミ"),
]

# Address templates per region
ADDRESSES = [
    ("東京都新宿区西新宿", "03-{n4}-{n4}"),
    ("東京都渋谷区道玄坂", "03-{n4}-{n4}"),
    ("東京都中央区銀座",   "03-{n4}-{n4}"),
    ("大阪府大阪市北区梅田", "06-{n4}-{n4}"),
    ("大阪府大阪市中央区難波", "06-{n4}-{n4}"),
    ("愛知県名古屋市中村区名駅", "052-{n3}-{n4}"),
    ("愛知県名古屋市中区栄", "052-{n3}-{n4}"),
    ("北海道札幌市中央区南1条西", "011-{n3}-{n4}"),
    ("神奈川県横浜市西区みなとみらい", "045-{n3}-{n4}"),
    ("福岡県福岡市中央区天神", "092-{n3}-{n4}"),
]

def pad_bytes(s, n):
    b = s.encode("utf-8")
    if len(b) > n:
        b = b[:n]
    return b.ljust(n, b" ")

def gen_phone(template):
    return template.format(
        n3=f"{random.randint(0,999):03d}",
        n4=f"{random.randint(0,9999):04d}",
    )

def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with open(OUTPUT, "wb") as f:
        # System customer (= 0000000001 per seed-data-spec §1.3)
        rec = (
            b"0000000001" +
            pad_bytes("システム", 50) +
            pad_bytes("PRACTICE BANK SYSTEM CUSTOMER", 60) +
            pad_bytes("(none)", 15) +
            pad_bytes("(none)", 200) +
            b"20260101" +
            b"A" +
            b"20260101000000" +
            b"20260101000000" +
            b"B" + b" " * 19  # tier B default + 19 FILLER
        )
        assert len(rec) == 392, f"len={len(rec)} expected 392 (per actual field math; doc §10.4 says 388 but field sum = 392 → doc typo follow-up Issue needed)"
        f.write(rec); f.write(b"\n"); count += 1

        # 100 customers (cust_id 0000000002..0000000101)
        for i in range(100):
            cust_id = f"{2 + i:010d}"
            surname_k, surname_kn = random.choice(SURNAMES)
            if i % 2 == 0:
                given_k, given_kn = random.choice(GIVEN_NAMES_M)
            else:
                given_k, given_kn = random.choice(GIVEN_NAMES_F)
            kanji = surname_k + given_k
            kana = surname_kn + given_kn
            addr_base, phone_tpl = random.choice(ADDRESSES)
            addr = f"{addr_base}{random.randint(1,9)}-{random.randint(1,30)}-{random.randint(1,30)}"
            phone = gen_phone(phone_tpl)
            tier = random.choice(["A", "B", "B", "B", "B", "C"])  # weighted B

            rec = (
                cust_id.encode("ascii") +
                pad_bytes(kana, 50) +
                pad_bytes(kanji, 60) +
                pad_bytes(phone, 15) +
                pad_bytes(addr, 200) +
                b"20260101" +
                b"A" +
                b"20260101000000" +
                b"20260101000000" +
                tier.encode("ascii") + b" " * 19
            )
            assert len(rec) == 392, f"len={len(rec)} expected 392"
            f.write(rec); f.write(b"\n"); count += 1

    print(f"Generated: {OUTPUT}")
    print(f"  Records: {count} (= 1 system + 100 ordinary)")
    print(f"  File size: {OUTPUT.stat().st_size} bytes")

if __name__ == "__main__":
    main()
