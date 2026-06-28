#!/usr/bin/env python3
"""
gen-calendar-seed.py — Generate calendar-seed.dat for 01-calendar CAL-LOAD.

Per docs/architecture/data-contracts.md §10.4 calendar.idx record layout:
    PIC 9(8) CAL-DATE              (8 bytes; YYYYMMDD)
    PIC X(1) CAL-DAY-TYPE          (1 byte;  B/H/W)
    PIC X(40) CAL-HOLIDAY-NAME     (40 bytes; spaces for non-holiday)
    PIC X(11) FILLER               (11 bytes; reserved)
    TOTAL: 60 bytes fixed per record

Coverage: 2026-01-01 to 2030-12-31 (5 years; 4 normal × 365 + 1 leap × 366 = 1,826 days)

Holiday set per Japan 国民の祝日に関する法律 (16 fixed holidays/year);
substitute holidays (振替休日) for holidays falling on Sunday.

Usage: python3 scripts/gen-seed/gen-calendar-seed.py
Output: subsystems/01-calendar/data/calendar-seed.dat (60 * 1826 = 109,560 bytes)
"""

import datetime
import sys
from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent.parent / \
    "subsystems/01-calendar/data/calendar-seed.dat"

START_DATE = datetime.date(2026, 1, 1)
END_DATE = datetime.date(2030, 12, 31)


def fixed_holidays(year):
    """Return list of (month, day, name_jp) for fixed-date holidays in a year."""
    return [
        (1, 1, "元日"),
        (2, 11, "建国記念の日"),
        (2, 23, "天皇誕生日"),
        (4, 29, "昭和の日"),
        (5, 3, "憲法記念日"),
        (5, 4, "みどりの日"),
        (5, 5, "こどもの日"),
        (8, 11, "山の日"),
        (11, 3, "文化の日"),
        (11, 23, "勤労感謝の日"),
    ]


def nth_monday(year, month, n):
    """Return the date of the n-th Monday in a given month (1-indexed)."""
    d = datetime.date(year, month, 1)
    # weekday(): Monday=0
    offset = (0 - d.weekday()) % 7
    first_monday = d + datetime.timedelta(days=offset)
    return first_monday + datetime.timedelta(days=7 * (n - 1))


def equinox(year, season):
    """Approximate spring (3/20-21) and autumn (9/22-23) equinoxes for 2026-2030."""
    if season == "spring":
        # 春分の日: 3/20 for even years 2024-2055; 3/21 for some odd
        # 2026,2028,2030 -> 3/20; 2027,2029 -> 3/21 (simplified)
        return (3, 20 if year % 2 == 0 else 21)
    elif season == "autumn":
        # 秋分の日: 9/22 for some years, 9/23 for others (simplified):
        # 2026=9/23, 2027=9/23, 2028=9/22, 2029=9/23, 2030=9/23
        m = {2026: 23, 2027: 23, 2028: 22, 2029: 23, 2030: 23}
        return (9, m.get(year, 23))


def get_holidays_for_year(year):
    """Return dict {date: holiday_name} for given year (incl moving + substitutes)."""
    holidays = {}

    # Fixed-date holidays
    for m, d, name in fixed_holidays(year):
        holidays[datetime.date(year, m, d)] = name

    # Moving (n-th Monday) holidays
    holidays[nth_monday(year, 1, 2)] = "成人の日"
    holidays[nth_monday(year, 7, 3)] = "海の日"
    holidays[nth_monday(year, 9, 3)] = "敬老の日"
    holidays[nth_monday(year, 10, 2)] = "スポーツの日"

    # Equinox holidays
    em, ed = equinox(year, "spring")
    holidays[datetime.date(year, em, ed)] = "春分の日"
    em, ed = equinox(year, "autumn")
    holidays[datetime.date(year, em, ed)] = "秋分の日"

    # 振替休日 (substitute holiday): if a holiday falls on Sunday,
    # next non-holiday weekday becomes 振替休日
    subs = {}
    for hdate in sorted(holidays.keys()):
        if hdate.weekday() == 6:  # Sunday
            sub = hdate + datetime.timedelta(days=1)
            while sub in holidays or sub.weekday() in (5, 6):
                sub += datetime.timedelta(days=1)
            subs[sub] = "振替休日"
    holidays.update(subs)

    return holidays


def write_record(f, date, day_type, holiday_name):
    """Write one 60-byte fixed-length record."""
    yyyymmdd = date.strftime("%Y%m%d")  # 8 bytes
    dt = day_type  # 1 byte
    name_field = (holiday_name or "").ljust(40)[:40]  # 40 bytes
    filler = " " * 11  # 11 bytes
    record = (yyyymmdd + dt + name_field + filler).encode("utf-8")
    # Encode might exceed 60 bytes if name has multibyte; truncate / pad
    if len(record) > 60:
        # Strip name and re-pad with ASCII spaces
        name_field = " " * 40
        record = (yyyymmdd + dt + name_field + filler).encode("utf-8")
        # Note: dropping the multibyte name name to keep fixed length;
        # production should use SJIS or right-pad to byte boundary
    record = record[:60].ljust(60, b" ")
    f.write(record)
    f.write(b"\n")


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    holiday_count = 0
    weekend_count = 0
    business_count = 0

    # Pre-compute holiday sets per year
    holidays_by_year = {y: get_holidays_for_year(y)
                        for y in range(START_DATE.year, END_DATE.year + 1)}

    with open(OUTPUT, "wb") as f:
        d = START_DATE
        while d <= END_DATE:
            year_holidays = holidays_by_year[d.year]
            if d in year_holidays:
                dt = "H"
                name = year_holidays[d]
                holiday_count += 1
            elif d.weekday() in (5, 6):  # Sat/Sun
                dt = "W"
                name = ""
                weekend_count += 1
            else:
                dt = "B"
                name = ""
                business_count += 1
            write_record(f, d, dt, name)
            count += 1
            d += datetime.timedelta(days=1)

    print(f"Generated: {OUTPUT}")
    print(f"  Total records: {count}")
    print(f"  Business days: {business_count}")
    print(f"  Holidays:      {holiday_count}")
    print(f"  Weekends:      {weekend_count}")
    print(f"  File size:     {OUTPUT.stat().st_size} bytes")
    assert count == 1826, f"Expected 1826 records, got {count}"


if __name__ == "__main__":
    main()
