package com.practicebank.masterreference.calendar.dto;

/**
 * エラーレスポンス。COBOL の戻り値コード（CAL-STATUS）とメッセージを返す。
 *
 * @param status  戻り値コード（04/08/12/16）
 * @param message エラー内容
 */
public record CalendarErrorResponse(int status, String message) {
}
