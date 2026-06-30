package com.practicebank.masterreference.calendar.dto;

/**
 * 日付区分照会（LOOKUP）のレスポンス。
 * 01-calendar-design.md 4.1 の出力パラメータに対応。
 *
 * @param status      戻り値コード（CAL-STATUS）
 * @param date        判定対象日（YYYYMMDD）
 * @param dayType     区分（B=営業日 / H=祝日 / W=週末）
 * @param holidayName 祝日名（祝日時のみ）
 */
public record CalendarLookupResponse(
        int status,
        String date,
        String dayType,
        String holidayName) {
}
