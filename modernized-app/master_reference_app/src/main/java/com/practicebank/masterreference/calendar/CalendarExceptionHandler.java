package com.practicebank.masterreference.calendar;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.practicebank.masterreference.calendar.dto.CalendarErrorResponse;

/**
 * カレンダーAPIの例外をHTTPレスポンスへマッピングする。
 * 戻り値コード（CAL-STATUS）に応じてHTTPステータスを決定する。
 */
@RestControllerAdvice(assignableTypes = CalendarController.class)
public class CalendarExceptionHandler {

    @ExceptionHandler(CalendarException.class)
    public ResponseEntity<CalendarErrorResponse> handle(CalendarException ex) {
        HttpStatus httpStatus = switch (ex.getStatus()) {
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case INVALID_INPUT -> HttpStatus.BAD_REQUEST;
            case IO_ERROR, FATAL -> HttpStatus.INTERNAL_SERVER_ERROR;
            case OK -> HttpStatus.OK;
        };
        CalendarErrorResponse body = new CalendarErrorResponse(ex.getStatus().code(), ex.getMessage());
        return ResponseEntity.status(httpStatus).body(body);
    }
}
