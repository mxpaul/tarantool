
/*
 * Copyright (C) 2011 Mail.RU
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <unistd.h>

#include <tnt_result.h>
#include <tnt_aes.h>
#include <tnt_cmac.h>
#include <tnt_mem.h>
#include <tnt.h>
#include <tnt_io.h>
#include <tnt_auth_chap.h>
#include <tnt_auth.h>

tnt_t*
tnt_init(tnt_proto_t proto, int rbuf_size, int sbuf_size)
{
	tnt_t * t = malloc(sizeof(tnt_t));

	if (t == NULL)
		return NULL;

	memset(t, 0, sizeof(tnt_t));

	t->proto = proto;
	t->auth_type = TNT_AUTH_NONE;

	t->rbuf_size = rbuf_size;
	t->sbuf_size = sbuf_size;

	t->opt_tmout = TNT_TMOUT_DEFAULT;
	t->opt_tmout_rcv = 0;
	t->opt_tmout_snd = 0;

	if (tnt_io_init(t) != TNT_EOK) {

		free(t);
		return NULL;
	}

	return t;
}

void
tnt_set_alloc(tnt_t * t,
	tnt_mallocf_t m, tnt_reallocf_t r, tnt_dupf_t d, tnt_freef_t f)
{
	(void)t;
	tnt_mem_init(m, r, d, f);
}

void
tnt_set_tmout(tnt_t * t, int tmout_connect, int tmout_snd, int tmout_rcv)
{
	t->opt_tmout = tmout_connect;
	t->opt_tmout_snd = tmout_snd;
	t->opt_tmout_rcv = tmout_rcv;
}

tnt_result_t
tnt_set_auth(tnt_t * t, tnt_auth_t auth,
	char * id,
	unsigned char * key, int key_size)
{
	t->auth_type = auth;

	t->auth_id_size = strlen(id);

	switch (t->auth_type) {

		case TNT_AUTH_NONE:
			return TNT_EOK;

		case TNT_AUTH_CHAP:
			if (key_size != TNT_AES_CMAC_KEY_LENGTH)
				return TNT_EBADVAL;

			if ((t->auth_id_size + 1) > TNT_AUTH_CHAP_ID_SIZE)
				return TNT_EBADVAL;
			break;
	}

	t->auth_id = strdup(id);

	if (t->auth_id == NULL)
		return TNT_EMEMORY;

	t->auth_key_size = key_size;
	t->auth_key = malloc(t->auth_key_size);

	if (t->auth_key == NULL) {

		free(t->auth_id);
		t->auth_id = NULL;
		return TNT_EMEMORY;
	}

	memcpy(t->auth_key, key, key_size);
	return TNT_EOK;
}

void
tnt_free(tnt_t * t)
{
	tnt_io_free(t);

	if (t->auth_id)
		free(t->auth_id);

	if (t->auth_key)
		free(t->auth_key);

	free(t);
}

typedef struct {

	tnt_result_t type;
	char * desc;

} tnt_error_t;

/* must be in sync with enum tnt_result_t */

static
tnt_error_t tnt_error_list[] = 
{
	{ TNT_EFAIL,     "fail"                     },
	{ TNT_EOK,       "ok"                       },
	{ TNT_EBADVAL,   "bad function argument"    },
	{ TNT_EMEMORY,   "memory allocation failed" },
	{ TNT_EBIG,      "buffer is too big"        },
	{ TNT_ESIZE,     "bad buffer size"          },
	{ TNT_ESOCKET,   "socket(2) failed"         },
	{ TNT_ESOCKOPT,  "setsockopt(2) failed"     },
	{ TNT_ERESOLVE,  "gethostbyname(2) failed"  },
	{ TNT_ENONBLOCK, "nonblocking set failed"   },
	{ TNT_ECONNECT,  "connect(2) failed"        },
	{ TNT_ETMOUT,    "operation timeout"        },
	{ TNT_EREAD,     "recv(2) failed"           },
	{ TNT_EWRITE,    "write(2) failed"          },
	{ TNT_EPROTO,    "protocol sanity error"    },
	{ TNT_EAUTH,     "authorization failed"     },
	{ TNT_ENOOP,     "no update ops specified"  },
	{ TNT_ENOTU,     "no tuples specified"      },
	{ TNT_EERROR,    "error"                    },
	{ TNT_EAGAIN,    "resend needed"            },
	{ TNT_LAST,       NULL                      }
};

char*
tnt_error(tnt_result_t res)
{
	if ( (int)res > TNT_LAST )
		return NULL;

	return tnt_error_list[(int)res].desc;
}

tnt_result_t
tnt_connect(tnt_t * t, char * hostname, int port)
{
	tnt_result_t result = tnt_io_connect(t, hostname, port);

	if (result != TNT_EOK)
		return result;

	if (t->auth_type != TNT_AUTH_NONE) {

		int result = tnt_auth(t);

		if (result != TNT_EOK) {
		
			tnt_io_close(t);
			return result;
		}
	}

	t->connected = 1;
	return TNT_EOK;
}

tnt_result_t
tnt_flush(tnt_t * t)
{
	return tnt_io_flush(t);
}

void
tnt_close(tnt_t * t)
{
	tnt_io_close(t);
}
