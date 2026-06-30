package com.practicebank.masterreference.calendar.dto;

/**
 * 翌営業日／前営業日算出（NEXT-BD / PREV-BD）のレスポンス。
 * 01-calendar-design.md 4.1 の CAL-OUTPUT-NEXT-DATE に対応。
 *
 * @param status       戻り値コード（CAL-STATUS）
 * @param inputDate    起点日（YYYYMMDD）
 * @param businessDate 算出された営業日（YYYYMMDD）
 */
public record BusinessDayResponse(
        int status,
        String inputDate,
        String businessDate) {
}
