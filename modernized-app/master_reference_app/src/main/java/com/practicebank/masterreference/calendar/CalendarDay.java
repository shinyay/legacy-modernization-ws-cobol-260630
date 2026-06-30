package com.practicebank.masterreference.calendar;

import java.time.LocalDate;

/**
 * カレンダー1日分のレコード。calendar テーブル（db/migration V2）に対応する。
 *
 * @param date        対象日（cal_date）
 * @param dayType     区分（day_type）: B=営業日 / H=祝日 / W=週末
 * @param holidayName 祝日名（holiday_name、祝日以外は null）
 * @param fiscalYear  年度（fiscal_year）
 */
public record CalendarDay(LocalDate date, String dayType, String holidayName, int fiscalYear) {

    public static final String DAY_TYPE_BUSINESS = "B";
    public static final String DAY_TYPE_HOLIDAY = "H";
    public static final String DAY_TYPE_WEEKEND = "W";

    public boolean isBusinessDay() {
        return DAY_TYPE_BUSINESS.equals(dayType);
    }
}
