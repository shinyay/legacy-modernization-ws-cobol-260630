/*
 * rmq_pub.c — shared/util/mq-publish (= promoted from Phase 0 spike 03)
 *
 * Single-shot RabbitMQ publish wrapper that COBOL can CALL via FFI.
 * Per-call connect/publish/close (= simple; production version would
 * pool connections, but per-CALL is correct for low-frequency events
 * and matches Phase 0 spike pattern).
 *
 * COBOL signature:
 *   CALL "rmq_pub" USING BY REFERENCE HOST   ( PIC X(64), null-padded )
 *                        BY VALUE     PORT   ( int, 5672 )
 *                        BY REFERENCE USER   ( PIC X(32), null-padded )
 *                        BY REFERENCE PASS   ( PIC X(32), null-padded )
 *                        BY REFERENCE QUEUE  ( PIC X(64), null-padded )
 *                        BY REFERENCE BODY   ( PIC X(N), space-padded )
 *                        BY REFERENCE BODYLEN( PIC S9(4) COMP-5, explicit length )
 *                        RETURNING RC        ( int; 0 = ok )
 *
 * F-4 lesson (= spike 03): BODY-LEN MUST be explicit (= COBOL space-padding
 * would otherwise contaminate JSON payload with trailing spaces).
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <amqp.h>
#include <amqp_tcp_socket.h>

int rmq_pub(const char *host_buf,
            int port,
            const char *user_buf,
            const char *pass_buf,
            const char *queue_buf,
            const char *body_buf,
            const short *body_len) {

    char host[65]  = {0};
    char user[33]  = {0};
    char pass[33]  = {0};
    char queue[65] = {0};
    int  blen      = (int)(*body_len);

    /* Strip trailing spaces from COBOL-padded strings */
    strncpy(host,  host_buf,  64); for (int i=63; i>=0; --i) if (host[i]==' ')  host[i]=0;  else break;
    strncpy(user,  user_buf,  32); for (int i=31; i>=0; --i) if (user[i]==' ')  user[i]=0;  else break;
    strncpy(pass,  pass_buf,  32); for (int i=31; i>=0; --i) if (pass[i]==' ')  pass[i]=0;  else break;
    strncpy(queue, queue_buf, 64); for (int i=63; i>=0; --i) if (queue[i]==' ') queue[i]=0; else break;

    if (blen <= 0 || blen > 4096) blen = (int)strnlen(body_buf, 4096);

    amqp_connection_state_t conn = amqp_new_connection();
    if (!conn) { fprintf(stderr, "[rmq_pub] new_connection failed\n"); return 1; }

    amqp_socket_t *sock = amqp_tcp_socket_new(conn);
    if (!sock) {
        fprintf(stderr, "[rmq_pub] tcp_socket_new failed\n");
        amqp_destroy_connection(conn);
        return 2;
    }

    if (amqp_socket_open(sock, host, port) != AMQP_STATUS_OK) {
        fprintf(stderr, "[rmq_pub] socket_open(%s:%d) failed\n", host, port);
        amqp_destroy_connection(conn);
        return 3;
    }

    amqp_rpc_reply_t login = amqp_login(conn, "/", 0, 131072, 0,
                                        AMQP_SASL_METHOD_PLAIN, user, pass);
    if (login.reply_type != AMQP_RESPONSE_NORMAL) {
        fprintf(stderr, "[rmq_pub] login failed\n");
        amqp_destroy_connection(conn);
        return 4;
    }

    amqp_channel_open(conn, 1);
    amqp_rpc_reply_t cre = amqp_get_rpc_reply(conn);
    if (cre.reply_type != AMQP_RESPONSE_NORMAL) {
        fprintf(stderr, "[rmq_pub] channel_open failed\n");
        amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
        amqp_destroy_connection(conn);
        return 5;
    }

    amqp_bytes_t body = amqp_cstring_bytes(body_buf);
    body.len = (size_t)blen;
    int pr = amqp_basic_publish(conn, 1,
                                amqp_cstring_bytes(""),
                                amqp_cstring_bytes(queue),
                                0, 0, NULL, body);

    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    amqp_destroy_connection(conn);

    if (pr != AMQP_STATUS_OK) {
        fprintf(stderr, "[rmq_pub] basic_publish failed (status=%d)\n", pr);
        return 6;
    }
    return 0;
}
