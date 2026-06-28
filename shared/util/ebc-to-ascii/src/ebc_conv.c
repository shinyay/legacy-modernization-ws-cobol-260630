/*
 * ebc_conv.c — shared/util/ebc-to-ascii (= promoted from spike 04)
 *
 * Convert a buffer from EBCDIC CP930 (= Japanese EBCDIC) to UTF-8
 * via iconv. Called from COBOL after a raw byte READ.
 *
 * COBOL signature:
 *   CALL "ebc_to_ascii" USING BY REFERENCE EBC-BUF ( PIC X(N) )
 *                             BY VALUE     EBC-LEN ( int    )
 *                             BY REFERENCE ASC-BUF ( PIC X(M), M >= N*3 )
 *                       RETURNING RC                ( int; bytes written or -1 )
 *
 * Phase 7 promotion notes (= production version of Phase 0 spike 04):
 * - Per-call iconv_open/close (= simple; thread-safe per call)
 * - Generous output buffer (= 3x input for multi-byte expansion)
 * - Trailing space pre-strip NOT done here (= caller responsibility)
 */

#include <stdio.h>
#include <string.h>
#include <iconv.h>
#include <errno.h>

int ebc_to_ascii(const char *ebc_buf, int ebc_len, char *asc_buf) {
    iconv_t cd = iconv_open("UTF-8", "CP930");
    if (cd == (iconv_t)-1) {
        fprintf(stderr, "[ebc_to_ascii] iconv_open failed: %s\n", strerror(errno));
        return -1;
    }

    char *in  = (char *)ebc_buf;
    size_t inb  = (size_t)ebc_len;
    char *out = asc_buf;
    size_t outb = (size_t)ebc_len * 3;

    size_t r = iconv(cd, &in, &inb, &out, &outb);
    iconv_close(cd);

    if (r == (size_t)-1) {
        fprintf(stderr, "[ebc_to_ascii] iconv failed: %s\n", strerror(errno));
        return -1;
    }
    return (int)(ebc_len * 3 - outb);
}
