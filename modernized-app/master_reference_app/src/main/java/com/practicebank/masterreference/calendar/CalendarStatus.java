package com.practicebank.masterreference.calendar;

/**
 * COBOL の戻り値コード（CAL-STATUS）を表す。
 * 01-calendar-design.md 2.3 に準拠。
 */
public enum CalendarStatus {

    /** 正常 */
    OK(0),
    /** 該当なし（対象日付レコードが存在しない） */
    NOT_FOUND(4),
    /** 入力不正（日付が範囲外・形式不正） */
    INVALID_INPUT(8),
    /** I/O失敗（キャッシュロード失敗） */
    IO_ERROR(12),
    /** 致命的エラー */
    FATAL(16);

    private final int code;

    CalendarStatus(int code) {
        this.code = code;
    }

    public int code() {
        return code;
    }
}
