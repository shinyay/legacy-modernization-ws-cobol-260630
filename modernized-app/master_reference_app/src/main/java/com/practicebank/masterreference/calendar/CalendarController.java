package com.practicebank.masterreference.calendar;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.practicebank.masterreference.calendar.dto.BusinessDayResponse;
import com.practicebank.masterreference.calendar.dto.CalendarLookupResponse;

/**
 * 営業日カレンダー参照API。
 * architecutre.md の代表API「GET /api/v1/business-calendar/{date}」に準拠する。
 */
@RestController
@RequestMapping("/api/v1/business-calendar")
public class CalendarController {

    private static final DateTimeFormatter OUTPUT_FORMAT = DateTimeFormatter.ofPattern("uuuuMMdd");

    private final CalendarService service;

    public CalendarController(CalendarService service) {
        this.service = service;
    }

    /**
     * 日付区分照会（CAL-LOOKUP）。
     * 例: GET /api/v1/business-calendar/20260101
     */
    @GetMapping("/{date}")
    public CalendarLookupResponse lookup(@PathVariable String date) {
        CalendarDay day = service.lookup(date);
        return new CalendarLookupResponse(
                CalendarStatus.OK.code(),
                day.date().format(OUTPUT_FORMAT),
                day.dayType(),
                day.holidayName());
    }

    /**
     * 翌営業日算出（CAL-NEXT-BD）。
     * 例: GET /api/v1/business-calendar/20260101/next-business-day
     */
    @GetMapping("/{date}/next-business-day")
    public BusinessDayResponse nextBusinessDay(@PathVariable String date) {
        LocalDate next = service.nextBusinessDay(date);
        return new BusinessDayResponse(
                CalendarStatus.OK.code(),
                date,
                next.format(OUTPUT_FORMAT));
    }

    /**
     * 前営業日算出（CAL-PREV-BD）。
     * 例: GET /api/v1/business-calendar/20260101/prev-business-day
     */
    @GetMapping("/{date}/prev-business-day")
    public BusinessDayResponse prevBusinessDay(@PathVariable String date) {
        LocalDate prev = service.prevBusinessDay(date);
        return new BusinessDayResponse(
                CalendarStatus.OK.code(),
                date,
                prev.format(OUTPUT_FORMAT));
    }
}
