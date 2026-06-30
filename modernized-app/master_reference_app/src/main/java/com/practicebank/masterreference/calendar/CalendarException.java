package com.practicebank.masterreference.calendar;

/**
 * カレンダー処理で発生する業務エラー。
 * COBOL の戻り値コード（{@link CalendarStatus}）を保持する。
 */
public class CalendarException extends RuntimeException {

    private final CalendarStatus status;

    public CalendarException(CalendarStatus status, String message) {
        super(message);
        this.status = status;
    }

    public CalendarException(CalendarStatus status, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
    }

    public CalendarStatus getStatus() {
        return status;
    }
}
