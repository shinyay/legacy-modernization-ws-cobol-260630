package com.practicebank.masterreference.calendar;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

/**
 * calendar テーブル（db/migration V2__master_pg_tables.sql）への参照アクセス。
 * 参照系のため更新は行わない。
 */
@Repository
public class CalendarRepository {

    private static final String COLUMNS = "cal_date, day_type, holiday_name, fiscal_year";

    private static final RowMapper<CalendarDay> ROW_MAPPER = (rs, rowNum) -> {
        String dayType = rs.getString("day_type");
        return new CalendarDay(
                rs.getDate("cal_date").toLocalDate(),
                dayType != null ? dayType.trim() : null,
                rs.getString("holiday_name"),
                rs.getInt("fiscal_year"));
    };

    private final JdbcTemplate jdbcTemplate;

    public CalendarRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * 指定範囲のカレンダーを日付昇順で全件取得する（キャッシュロード用）。
     */
    public List<CalendarDay> findByDateRange(LocalDate from, LocalDate to) {
        return jdbcTemplate.query(
                "SELECT " + COLUMNS + " FROM calendar WHERE cal_date BETWEEN ? AND ? ORDER BY cal_date",
                ROW_MAPPER,
                java.sql.Date.valueOf(from),
                java.sql.Date.valueOf(to));
    }

    /**
     * 指定日のカレンダーレコードを取得する。
     */
    public Optional<CalendarDay> findByDate(LocalDate date) {
        try {
            CalendarDay day = jdbcTemplate.queryForObject(
                    "SELECT " + COLUMNS + " FROM calendar WHERE cal_date = ?",
                    ROW_MAPPER,
                    java.sql.Date.valueOf(date));
            return Optional.ofNullable(day);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }
}
