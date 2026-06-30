package com.practicebank.masterreference.calendar;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

/**
 * 営業日カレンダーの参照サービス。
 * 01-calendar-design.md の CAL-LOOKUP / CAL-NEXT-BD / CAL-PREV-BD に対応する。
 *
 * <p>AS-IS の ISAM メモリキャッシュ（最大1826件=5年）を、アプリ内インメモリキャッシュとして実装する
 * （architecutre.md「ISAMでキャッシュ化・高速化する処理はインメモリキャッシュで対応」）。
 */
@Service
public class CalendarService {

    private static final Logger log = LoggerFactory.getLogger(CalendarService.class);

    /** カレンダー対象範囲（YYYYMMDD: 20260101–20301231）。 */
    static final LocalDate RANGE_START = LocalDate.of(2026, 1, 1);
    static final LocalDate RANGE_END = LocalDate.of(2030, 12, 31);

    /** 営業日探索の上限日数（NEXT-BD / PREV-BD）。 */
    static final int MAX_SEARCH_DAYS = 10;

    /** キャッシュ最大件数（5年分=1826件）。 */
    static final int MAX_CACHE_SIZE = 1826;

    private static final DateTimeFormatter INPUT_FORMAT =
            DateTimeFormatter.ofPattern("uuuuMMdd").withResolverStyle(java.time.format.ResolverStyle.STRICT);

    private final CalendarRepository repository;

    /** 日付→カレンダーレコードのインメモリキャッシュ（遅延ロード）。 */
    private volatile Map<LocalDate, CalendarDay> cache;

    public CalendarService(CalendarRepository repository) {
        this.repository = repository;
    }

    /**
     * 日付区分照会（CAL-LOOKUP）。
     *
     * @param inputDate YYYYMMDD 形式の対象日
     * @return 該当日のカレンダーレコード
     * @throws CalendarException 範囲外/形式不正（08）, 該当なし（04）, I/O失敗（12）
     */
    public CalendarDay lookup(String inputDate) {
        LocalDate date = parseAndValidate(inputDate);
        CalendarDay day = loadCache().get(date);
        if (day == null) {
            throw new CalendarException(CalendarStatus.NOT_FOUND,
                    "カレンダーに対象日付が存在しません: " + inputDate);
        }
        return day;
    }

    /**
     * 翌営業日算出（CAL-NEXT-BD）。起点日の翌日から最大10日先まで探索する。
     *
     * @param inputDate YYYYMMDD 形式の起点日
     * @return 最初に見つかった営業日
     * @throws CalendarException 範囲外/形式不正（08）, 該当なし（04）, I/O失敗（12）
     */
    public LocalDate nextBusinessDay(String inputDate) {
        LocalDate start = parseAndValidate(inputDate);
        return searchBusinessDay(start, inputDate, 1);
    }

    /**
     * 前営業日算出（CAL-PREV-BD）。起点日の前日から最大10日前まで探索する。
     *
     * @param inputDate YYYYMMDD 形式の起点日
     * @return 最初に見つかった営業日
     * @throws CalendarException 範囲外/形式不正（08）, 該当なし（04）, I/O失敗（12）
     */
    public LocalDate prevBusinessDay(String inputDate) {
        LocalDate start = parseAndValidate(inputDate);
        return searchBusinessDay(start, inputDate, -1);
    }

    private LocalDate searchBusinessDay(LocalDate start, String inputDate, int step) {
        Map<LocalDate, CalendarDay> map = loadCache();
        LocalDate cursor = start;
        for (int i = 0; i < MAX_SEARCH_DAYS; i++) {
            cursor = cursor.plusDays(step);
            CalendarDay day = map.get(cursor);
            if (day == null) {
                // 範囲外に出た、または欠損 → これ以上探索できない
                break;
            }
            if (day.isBusinessDay()) {
                return cursor;
            }
        }
        throw new CalendarException(CalendarStatus.NOT_FOUND,
                "起点日から" + MAX_SEARCH_DAYS + "日以内に営業日が見つかりません: " + inputDate);
    }

    /** YYYYMMDD のパースと範囲（20260101–20301231）検証。 */
    private LocalDate parseAndValidate(String inputDate) {
        if (inputDate == null || inputDate.length() != 8) {
            throw new CalendarException(CalendarStatus.INVALID_INPUT,
                    "日付は YYYYMMDD 形式（8桁）で指定してください: " + inputDate);
        }
        LocalDate date;
        try {
            date = LocalDate.parse(inputDate, INPUT_FORMAT);
        } catch (DateTimeParseException e) {
            throw new CalendarException(CalendarStatus.INVALID_INPUT,
                    "日付形式が不正です: " + inputDate);
        }
        if (date.isBefore(RANGE_START) || date.isAfter(RANGE_END)) {
            throw new CalendarException(CalendarStatus.INVALID_INPUT,
                    "日付が対象範囲外です（20260101–20301231）: " + inputDate);
        }
        return date;
    }

    /** インメモリキャッシュを遅延ロードする（ダブルチェックロッキング）。 */
    private Map<LocalDate, CalendarDay> loadCache() {
        Map<LocalDate, CalendarDay> local = cache;
        if (local == null) {
            synchronized (this) {
                local = cache;
                if (local == null) {
                    cache = local = buildCache();
                }
            }
        }
        return local;
    }

    private Map<LocalDate, CalendarDay> buildCache() {
        try {
            List<CalendarDay> days = repository.findByDateRange(RANGE_START, RANGE_END);
            Map<LocalDate, CalendarDay> map = new LinkedHashMap<>(Math.max(16, days.size() * 2));
            for (CalendarDay day : days) {
                if (map.size() >= MAX_CACHE_SIZE) {
                    break;
                }
                map.put(day.date(), day);
            }
            log.info("カレンダーキャッシュをロードしました: {} 件", map.size());
            return map;
        } catch (DataAccessException e) {
            log.error("カレンダーキャッシュのロードに失敗しました", e);
            throw new CalendarException(CalendarStatus.IO_ERROR,
                    "カレンダーキャッシュのロードに失敗しました", e);
        }
    }
}
